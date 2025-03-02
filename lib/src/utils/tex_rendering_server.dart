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

  static Future<void> run({int port = 0}) async {
    await server.start(port: port);
  }

  static Future<String> generateHTML(
      String customHeadContent, int port, String renderingEngineName) async {
    // Read the original HTML file from assets.
    String htmlContent = await rootBundle
        .loadString("packages/flutter_tex/js/$renderingEngineName/index.html");

    // Set the base URL so relative paths resolve correctly.
    // If index.html is in .../js/mathjax/, the base href should be that folder.
    String baseUrl =
        "http://localhost:$port/packages/flutter_tex/js/$renderingEngineName/";
    String baseTag = '<base href="$baseUrl">';

    // Inject the base tag and custom head content right after <head>
    htmlContent = htmlContent.replaceFirst(
        "<head>", "<head>\n$baseTag\n$customHeadContent\n");

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

  static Future<void> stop() async {
    await server.close();
  }
}

typedef RenderingEngineCallback = void Function(String message);
