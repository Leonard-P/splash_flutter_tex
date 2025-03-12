import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

import '../../flutter_tex.dart';

/// A rendering controller for TeXView that can be instantiated multiple times.
/// Each instance has its own controller and server, allowing multiple independent TeXViews.
class TeXRenderingController {
  RenderingEngineCallback? onPageFinished,
      onTapCallback,
      onTeXViewRenderedCallback;
  WebViewControllerPlus controller = WebViewControllerPlus();
  TeXViewRenderingEngine renderingEngine = const TeXViewRenderingEngine.katex();

  /// Custom content to inject into the HTML document's head section
  final String customHeadContent;

  /// set this static flag to true to automatically close and start server depending on instance count
  /// page view usecase might autostop to early and is easier managed manually by calling dispose.
  static bool autoStop = false;

  // Using a static server instance that's shared across all controllers
  static LocalhostServer? _sharedServer;
  static int _instanceCount = 0;
  static Completer<void> _serverStartCompleter = Completer<void>();
  static bool _isServerRunning = false;

  /// Constructor that allows setting custom head content
  TeXRenderingController({this.customHeadContent = ''});

  // Create a getter for the server
  LocalhostServer get server => _sharedServer!;

  Future<void> run({int port = 0}) async {
    // Initialize shared server if it doesn't exist
    if (_sharedServer == null) {
      _sharedServer = LocalhostServer();
      await _sharedServer!.start(port: port);
      _isServerRunning = true;
      _serverStartCompleter.complete();
    } else if (!_isServerRunning) {
      // If server exists but isn't running, wait until it's ready
      await _serverStartCompleter.future;
    }
    _instanceCount++;
  }

  Future<void> initController() async {
    // Make sure server is running
    if (_sharedServer == null || !_isServerRunning) {
      await run();
    }

    var controllerCompleter = Completer<void>();

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(Colors.transparent);

    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) {
          onPageFinished?.call(url);

          // Inject custom head content if provided
          if (customHeadContent.isNotEmpty) {
            // More robust approach to inject any type of HTML content
            controller.runJavaScript('''
              (function() {
                try {
                  // Mark document for custom content
                  document.body.setAttribute('data-has-custom-content', 'true');
                  
                  // Add a container for custom head content in the head
                  if (!document.getElementById('custom-head-container')) {
                    var customHeadContainer = document.createElement('div');
                    customHeadContainer.id = 'custom-head-container';
                    customHeadContainer.style.display = 'none';
                    document.head.appendChild(customHeadContainer);
                  }
                  
                  // Insert content into the head properly
                  var styles = [];
                  var scripts = [];
                  var links = [];
                  var other = [];
                  
                  // Parse the custom content
                  var tempContainer = document.createElement('div');
                  tempContainer.innerHTML = `$customHeadContent`;
                  
                  // Sort elements by type
                  Array.from(tempContainer.children).forEach(function(el) {
                    if (el.tagName === 'STYLE') styles.push(el);
                    else if (el.tagName === 'SCRIPT') scripts.push(el);
                    else if (el.tagName === 'LINK') links.push(el);
                    else other.push(el);
                  });
                  
                  // Add styles first
                  styles.forEach(function(style) {
                    document.head.appendChild(style.cloneNode(true));
                  });
                  
                  // Add links next
                  links.forEach(function(link) {
                    document.head.appendChild(link.cloneNode(true));
                  });
                  
                  // Add other elements
                  other.forEach(function(el) {
                    document.head.appendChild(el.cloneNode(true));
                  });
                  
                  // Add scripts last to ensure everything else is ready
                  scripts.forEach(function(script) {
                    var newScript = document.createElement('script');
                    newScript.textContent = script.textContent;
                    if (script.src) newScript.src = script.src;
                    if (script.type) newScript.type = script.type;
                    if (script.defer) newScript.defer = script.defer;
                    if (script.async) newScript.async = script.async;
                    document.head.appendChild(newScript);
                  });
                  
                  console.log("Custom head content injected successfully");
                  
                  // Dispatch an event when custom content is ready
                  document.dispatchEvent(new Event('customContentLoaded'));
                } catch (e) {
                  console.error("Error injecting custom head content:", e);
                }
              })();
            ''');
          }

          controllerCompleter.complete();
        },
      ),
    );

    await controller.addJavaScriptChannel(
      'TeXViewRenderedCallback',
      onMessageReceived: (teXViewRenderedCallbackMessage) =>
          onTeXViewRenderedCallback
              ?.call(teXViewRenderedCallbackMessage.message),
    );

    await controller.setOnConsoleMessage(
      (message) {
        if (kDebugMode) {
          print(message.message);
        }
      },
    );

    await controller.loadFlutterAssetWithServer(
        "packages/flutter_tex/js/${renderingEngine.name}/index.html",
        _sharedServer!.port!);

    await controller.addJavaScriptChannel(
      'OnTapCallback',
      onMessageReceived: (onTapCallbackMessage) =>
          onTapCallback?.call(onTapCallbackMessage.message),
    );

    return controllerCompleter.future;
  }

  static Future<void> stop({bool iReallyWantToStop = false}) async {
    // Only close the server if this is the last instance
    _instanceCount--;

    if (!iReallyWantToStop && !autoStop) {
      return;
    }

    if (_instanceCount <= 0 || iReallyWantToStop) {
      try {
        if (_sharedServer != null && _isServerRunning) {
          await _sharedServer!.close();
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error stopping shared TeXRenderingController server: $e");
        }
      }
      _instanceCount = 0;
      _isServerRunning = false;
      _serverStartCompleter = Completer<void>();
      _sharedServer = null;
    }
  }

  void dispose() {
    stop(iReallyWantToStop: false);
  }
}
