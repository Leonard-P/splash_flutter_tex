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
  TeXViewRenderingEngine renderingEngine =
      const TeXViewRenderingEngine.mathjax();

  /// set this static flag to true to automatically close and start server depending on instance count
  /// page view usecase might autostop to early and is easier managed manually by calling dispose.
  static bool autoStop = false;

  // Using a static server instance that's shared across all controllers
  static LocalhostServer? _sharedServer;
  static int _instanceCount = 0;
  static Completer<void> _serverStartCompleter = Completer<void>();
  static bool _isServerRunning = false;

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
          _isServerRunning = false;
          _serverStartCompleter = Completer<void>();
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error stopping shared TeXRenderingController server: $e");
        }
      }
      _instanceCount = 0;
    }
  }

  void dispose() {
    stop(iReallyWantToStop: false);
  }
}
