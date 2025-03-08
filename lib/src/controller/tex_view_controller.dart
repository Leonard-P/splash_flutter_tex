import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tex/src/models/rendering_engine.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

/// A controller for a TeXView, wrapping the WebViewControllerPlus and LocalhostServer.
class TeXViewController {
  /// The WebView controller
  final WebViewControllerPlus webViewController = WebViewControllerPlus();

  /// The local server
  final LocalhostServer server = LocalhostServer();

  /// Flag to track if the controller has been initialized
  bool _isInitialized = false;

  /// Flag to track if the controller is currently active
  bool _isActive = false;

  /// Current content being displayed
  String? _currentContent;

  /// Custom head content
  String _customHeadContent = '';

  /// Unique ID for this controller
  final String id;

  /// Callbacks
  Function(String)? onPageFinished;
  Function(String)? onTapCallback;
  Function(String)? onTeXViewRenderedCallback;

  /// The rendering engine to use
  TeXViewRenderingEngine renderingEngine =
      const TeXViewRenderingEngine.mathjax();

  /// Create a new TeXViewController with a unique ID
  TeXViewController({required this.id});

  /// Initialize the controller
  Future<void> initialize({String customHeadContent = ''}) async {
    if (_isInitialized) return;

    _customHeadContent = customHeadContent;

    // Start the server
    await server.start(port: 0);

    // Generate HTML
    String htmlContent = await _generateHTML(
        customHeadContent, server.port!, renderingEngine.name);

    // Initialize the controller
    var controllerCompleter = Completer<void>();

    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(
        Uri.dataFromString(
          htmlContent,
          mimeType: 'text/html',
          encoding: Encoding.getByName('utf-8'),
        ),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            onPageFinished?.call(url);
            controllerCompleter.complete();
          },
        ),
      )
      ..setOnConsoleMessage(
        (message) {
          if (kDebugMode) {
            print('[$id] ${message.message}');
          }
        },
      )
      ..addJavaScriptChannel(
        'OnTapCallback',
        onMessageReceived: (onTapCallbackMessage) =>
            onTapCallback?.call(onTapCallbackMessage.message),
      )
      ..addJavaScriptChannel(
        'TeXViewRenderedCallback',
        onMessageReceived: (teXViewRenderedCallbackMessage) =>
            onTeXViewRenderedCallback
                ?.call(teXViewRenderedCallbackMessage.message),
      );

    await controllerCompleter.future;
    _isInitialized = true;
    _isActive = true;
  }

  /// Generate HTML content for the WebView
  Future<String> _generateHTML(
      String customHeadContent, int port, String renderingEngineName) async {
    // Read the original HTML file from assets
    String htmlContent = await rootBundle
        .loadString("packages/flutter_tex/js/$renderingEngineName/index.html");

    // Set the base URL so relative paths resolve correctly
    String baseUrl =
        "http://localhost:$port/packages/flutter_tex/js/$renderingEngineName/";
    String baseTag = '<base href="$baseUrl">';

    // Create a container div for custom head content with an ID to find it later
    String customHeadWrapper =
        '<div id="flutter_tex_custom_head_content" style="display:none;">$customHeadContent</div>';

    // Add resource monitoring script
    String resourceMonitoringScript = '''
    <script>
      // Track resource loading for height adjustment
      window.TeXViewResourceMonitor = {
        pendingResources: 0,
        
        // Register a new resource to be monitored
        registerResource: function() {
          this.pendingResources++;
          return this.pendingResources;
        },
        
        // Resource finished loading, update height if needed
        resourceLoaded: function() {
          this.pendingResources--;
          if (this.pendingResources <= 0) {
            // All resources loaded, update height
            this.updateHeight();
          }
        },
        
        // Update the TeXView height
        updateHeight: function() {
          if (typeof updateTeXViewHeight === 'function') {
            updateTeXViewHeight();
          }
        },
        
        // Process the entire DOM to add monitoring to existing resources
        observeExistingResources: function() {
          const images = document.querySelectorAll('img:not([data-texview-monitored])');
          const iframes = document.querySelectorAll('iframe:not([data-texview-monitored])');
          const videos = document.querySelectorAll('video:not([data-texview-monitored])');
          
          // Monitor images
          images.forEach(img => {
            img.setAttribute('data-texview-monitored', 'true');
            if (!img.complete) {
              const resourceId = this.registerResource();
              img.addEventListener('load', () => {
                this.resourceLoaded();
              });
              img.addEventListener('error', () => {
                this.resourceLoaded();
              });
            }
          });
          
          // Monitor iframes
          iframes.forEach(iframe => {
            iframe.setAttribute('data-texview-monitored', 'true');
            const resourceId = this.registerResource();
            iframe.addEventListener('load', () => {
              this.resourceLoaded();
            });
          });
          
          // Monitor videos
          videos.forEach(video => {
            video.setAttribute('data-texview-monitored', 'true');
            if (video.readyState < 1) { // HAVE_NOTHING
              const resourceId = this.registerResource();
              video.addEventListener('loadedmetadata', () => {
                this.resourceLoaded();
              });
              video.addEventListener('error', () => {
                this.resourceLoaded();
              });
            }
          });
        }
      };
      
      // Override the existing updateTeXViewHeight function to also check resources
      const originalUpdateTeXViewHeight = window.updateTeXViewHeight || function() {};
      window.updateTeXViewHeight = function() {
        originalUpdateTeXViewHeight();
        
        // Ensure we're monitoring all resources
        window.TeXViewResourceMonitor.observeExistingResources();
        
        // Get height after resources are loaded
        const height = document.getElementById("tex-view-render-container").offsetHeight;
        window.flutter_inappwebview.callHandler('TeXViewRenderedCallback', height);
      };
      
      // Observe mutations to detect newly added resources
      const observeDOMChanges = () => {
        const observer = new MutationObserver((mutations) => {
          let hasNewContent = false;
          
          mutations.forEach(mutation => {
            if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
              hasNewContent = true;
            }
          });
          
          if (hasNewContent) {
            // New content was added, check for new resources
            window.TeXViewResourceMonitor.observeExistingResources();
          }
        });
        
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });
      };
      
      // Initialize monitoring when the document is ready
      document.addEventListener('DOMContentLoaded', () => {
        window.TeXViewResourceMonitor.observeExistingResources();
        observeDOMChanges();
      });
    </script>
    ''';

    // Inject the base tag and custom head content right after <head>
    htmlContent = htmlContent.replaceFirst("<head>",
        "<head>\n$baseTag\n$customHeadWrapper\n$resourceMonitoringScript\n");

    return htmlContent;
  }

  /// Render TeXView content
  Future<void> render(String rawData) async {
    if (!_isInitialized) {
      throw Exception('Controller not initialized, call initialize() first');
    }

    if (_currentContent == rawData) {
      // Content hasn't changed, no need to re-render
      return;
    }

    _currentContent = rawData;
    await webViewController.runJavaScript("initView($rawData)");
  }

  /// Update custom head content
  Future<void> updateCustomHeadContent(String newCustomHeadContent) async {
    if (!_isInitialized) return;

    if (_customHeadContent == newCustomHeadContent) {
      // No changes needed if content is the same
      return;
    }

    _customHeadContent = newCustomHeadContent;

    // Convert the content to a base64 string to avoid escaping issues
    final base64Content = base64Encode(utf8.encode(newCustomHeadContent));

    final updateScript = '''
      (function() {
        // Decode the base64 content
        function decodeBase64(str) {
          return decodeURIComponent(Array.prototype.map.call(atob(str), function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
          }).join(''));
        }
        
        // The custom head content as base64
        const encodedContent = "$base64Content";
        const decodedContent = decodeBase64(encodedContent);
        
        // Find the custom head container
        const container = document.getElementById('flutter_tex_custom_head_content');
        if (!container) {
          console.error('Custom head container not found');
          return;
        }
        
        // Remove old styles from head
        const oldStyles = document.querySelectorAll('head style.flutter_tex_injected');
        oldStyles.forEach(style => style.remove());
        
        // Create a temporary div to parse the new content
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = decodedContent;
        
        // Extract and collect scripts to re-execute them later
        const scripts = [];
        const scriptElements = tempDiv.querySelectorAll('script');
        scriptElements.forEach(script => {
          scripts.push({
            src: script.getAttribute('src'),
            type: script.getAttribute('type'),
            content: script.textContent
          });
          script.remove(); // Remove script to prevent premature execution
        });
        
        // Add all other elements to the head
        const head = document.head;
        const styleElements = tempDiv.querySelectorAll('style, link[rel="stylesheet"]');
        styleElements.forEach(style => {
          const clone = style.cloneNode(true);
          if (clone.tagName === 'STYLE') {
            clone.classList.add('flutter_tex_injected');
          }
          head.appendChild(clone);
        });
        
        // Add meta tags and other head elements
        const metaElements = tempDiv.querySelectorAll('meta');
        metaElements.forEach(meta => {
          // Check if the meta tag already exists (by name or property)
          const name = meta.getAttribute('name');
          const property = meta.getAttribute('property');
          let exists = false;
          
          if (name) {
            exists = !!document.querySelector(`meta[name="\${name}"]`);
          } else if (property) {
            exists = !!document.querySelector(`meta[property="\${property}"]`);
          }
          
          if (!exists) {
            const clone = meta.cloneNode(true);
            head.appendChild(clone);
          }
        });
        
        // Store the new content in the container
        container.innerHTML = decodedContent;
        
        // Re-execute all scripts in the correct order
        scripts.forEach(scriptData => {
          const newScript = document.createElement('script');
          if (scriptData.type) newScript.type = scriptData.type;
          
          if (scriptData.src) {
            newScript.src = scriptData.src;
            newScript.async = false;
            document.head.appendChild(newScript);
          } else if (scriptData.content) {
            try {
              // For inline scripts, execute the content
              const scriptContent = scriptData.content;
              const scriptElement = document.createElement('script');
              scriptElement.textContent = scriptContent;
              document.head.appendChild(scriptElement);
            } catch (e) {
              console.error('Error executing script:', e);
            }
          }
        });
        
        console.log('Custom head content updated successfully');
        
        // Call common UI functions that might be defined in custom head
        if (typeof updateBalance === 'function') {
          try {
            updateBalance();
          } catch (e) { /* ignore if not defined */ }
        }
      })();
    ''';

    await webViewController.runJavaScript(updateScript);
  }

  /// Mark this controller as active
  void markActive() {
    _isActive = true;
  }

  /// Mark this controller as inactive
  void markInactive() {
    _isActive = false;
  }

  /// Check if controller is active
  bool get isActive => _isActive;

  /// Check if controller is initialized
  bool get isInitialized => _isInitialized;

  /// Get the current content
  String? get currentContent => _currentContent;

  /// Clean up resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await server.close();
    }
    _isInitialized = false;
    _isActive = false;
  }
}
