import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tex/src/models/rendering_engine.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

/// A rendering server for TeXView. This is backed by a [LocalhostServer] and a [WebViewControllerPlus].
/// Make sure to call [run] before using the [controller].
class TeXRederingServer {
  static RenderingEngineCallback? onPageFinished,
      onTapCallback,
      onTeXViewRenderedCallback;
  static WebViewControllerPlus controller = WebViewControllerPlus();
  static TeXViewRenderingEngine renderingEngine =
      const TeXViewRenderingEngine.mathjax();

  static LocalhostServer server = LocalhostServer();

  /// Tracks the current custom head content for reference
  static String _currentCustomHeadContent = '';

  /// Unique ID used to identify the custom head content container
  static const String _customHeadContainerId =
      'flutter_tex_custom_head_content';

  static Future<void> run({int port = 0}) async {
    await server.start(port: port);
  }

  static Future<String> generateHTML(
      String customHeadContent, int port, String renderingEngineName) async {
    // Read the original HTML file from assets.
    String htmlContent = await rootBundle
        .loadString("packages/flutter_tex/js/$renderingEngineName/index.html");

    // Set the base URL so relative paths resolve correctly.
    String baseUrl =
        "http://localhost:$port/packages/flutter_tex/js/$renderingEngineName/";
    String baseTag = '<base href="$baseUrl">';
    // Add a CSP meta tag to relax CORS restrictions on Android.
    String cspTag =
        '<meta http-equiv="Content-Security-Policy" content="default-src * data: blob: \'unsafe-inline\' \'unsafe-eval\';">';

    // Create a container div for custom head content with an ID to find it later
    String customHeadWrapper =
        '<div id="$_customHeadContainerId" style="display:none;">$customHeadContent</div>';

    // Add resource loading monitoring script
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

    // Inject the base tag, custom head content and resource monitoring script right after <head>
    htmlContent = htmlContent.replaceFirst("<head>",
        "<head>\n$baseTag\n$cspTag\n$customHeadWrapper\n$resourceMonitoringScript\n");

    _currentCustomHeadContent = customHeadContent;
    return htmlContent;
  }

  static Future<void> initController({String customHeadContent = ''}) async {
    var controllerCompleter = Completer<void>();

    String customHTML = await generateHTML(
        customHeadContent, server.port!, renderingEngine.name);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(
        Uri.dataFromString(
          customHTML,
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
            print(message.message);
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

    return controllerCompleter.future;
  }

  /// Updates the custom head content without reinitializing the WebView controller
  ///
  /// This function updates the custom head content div and re-executes all scripts
  /// to ensure the new content takes effect.
  static Future<void> updateCustomHeadContent(
      String newCustomHeadContent) async {
    if (_currentCustomHeadContent == newCustomHeadContent) {
      // No changes needed if content is the same
      return;
    }

    // Update the tracking variable
    _currentCustomHeadContent = newCustomHeadContent;

    // Properly escape the content for JavaScript
    // Convert the content to a base64 string to avoid escaping issues
    final base64Content = base64Encode(utf8.encode(newCustomHeadContent));

    // JavaScript to update the custom head content and re-execute scripts
    final updateScript = '''
      (function() {
        // Decode the base64 content
        function decodeBase64(str) {
          // Use built-in atob function
          return decodeURIComponent(Array.prototype.map.call(atob(str), function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
          }).join(''));
        }
        
        // The custom head content as base64
        const encodedContent = "$base64Content";
        const decodedContent = decodeBase64(encodedContent);
        
        // Find the custom head container
        const container = document.getElementById('$_customHeadContainerId');
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
        
        // Call updateBalance function if it exists to initialize the UI
        if (typeof updateBalance === 'function') {
          try {
            updateBalance();
          } catch (e) {
            console.error('Error calling updateBalance:', e);
          }
        }
      })();
    ''';

    // Execute the JavaScript to update the head content
    await controller.runJavaScript(updateScript);
  }

  static Future<void> stop() async {
    await server.close();
  }
}

typedef RenderingEngineCallback = void Function(String message);
