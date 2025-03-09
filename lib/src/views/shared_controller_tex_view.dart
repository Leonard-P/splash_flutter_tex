import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:webview_flutter_plus/webview_flutter_plus.dart';
import '../../flutter_tex.dart';
import '../models/widget_meta.dart';
import '../utils/style_utils.dart';

/// A TeXView widget that uses a shared controller from SharedTexViewControllerPool.
/// This version mirrors the behavior in tex_view_mobile.dart (height update, lazy rendering, etc.)
class SharedControllerTeXView extends StatefulWidget {
  final String id;
  final TeXViewWidget child;
  final TeXViewStyle? style;
  final double addedHeight;
  final Widget Function(BuildContext context)? loadingWidgetBuilder;
  final SharedTexViewControllerPool controllerPool;

  /// Optional callback (the page id in this case) and updated height.
  final Function(String, double)? onRenderFinished;

  const SharedControllerTeXView({
    super.key,
    required this.id,
    required this.child,
    this.style,
    this.loadingWidgetBuilder,
    this.onRenderFinished,
    required this.controllerPool,
    this.addedHeight = 0.0,
  });

  @override
  State<SharedControllerTeXView> createState() =>
      _SharedControllerTeXViewState();
}

class _SharedControllerTeXViewState extends State<SharedControllerTeXView> {
  TeXViewController? _controller; // made nullable
  double _currentHeight = initialHeight;
  String _lastRawData = "";
  bool _initialRenderComplete = false;

  @override
  void initState() {
    super.initState();
    // Obtain the shared controller from the pool using the provided id.
    widget.controllerPool.get(widget.id).then((controller) async {
      if (!mounted) return;
      setState(() {
        _controller = controller;
      });
      // Set the onRendered callback to update height.
      _controller!.onTeXViewRenderedCallback = (heightStr) {
        double newHeight = double.tryParse(heightStr) ?? initialHeight;
        if ((newHeight != _currentHeight || !_initialRenderComplete) &&
            mounted) {
          setState(() {
            _currentHeight = newHeight;
            _initialRenderComplete = true;
          });
          widget.onRenderFinished?.call(widget.id, newHeight);
        }
      };
      _renderTeXView();
    });
  }

  @override
  void didUpdateWidget(covariant SharedControllerTeXView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newRaw = widget.child.toJson().toString();
    final oldRaw = oldWidget.child.toJson().toString();
    if (newRaw != oldRaw) {
      _renderTeXView();
    }
  }

  Future<bool> _isInitViewDefined() async {
    if (_controller == null) return false;
    try {
      final result = await _controller!.webViewController
          .runJavaScriptReturningResult("typeof initView");
      // result might be returned as a string.
      return (result as String).trim() == 'function';
    } catch (_) {
      return false;
    }
  }

  void _renderTeXView() async {
    if (_controller == null) return;
    // Get the raw JSON data from the child widget.
    final currentRawData = getSharedTeXViewRawData(widget);
    if (currentRawData != _lastRawData) {
      if (widget.loadingWidgetBuilder != null) {
        setState(() {
          _initialRenderComplete = false;
          _currentHeight = initialHeight;
        });
      }
      // Wait until initView is defined.
      while (!await _isInitViewDefined()) {
        if (kDebugMode) {
          print("Waiting for init view...");
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Call the JavaScript function 'initView' on the controller's WebView.
      // await _controller!.webViewController
      //     .runJavaScript("initView(${jsonEncode(currentRawData)})");

      await _controller?.render(currentRawData);
      // _controller?.forceHeightUpdate();
      _lastRawData = currentRawData;
    } else {
      if (kDebugMode) {
        print("forcing height update");
      }
      setState(() {
        _controller?.forceHeightUpdate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the controller is not yet available, show loading.
    if (_controller == null) {
      return widget.loadingWidgetBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }
    // Removed _renderTeXView() invocation from build to prevent multiple calls
    return IndexedStack(
      index: widget.loadingWidgetBuilder != null && !_initialRenderComplete
          ? 1
          : 0,
      children: [
        SizedBox(
          height: _currentHeight + widget.addedHeight,
          child: WebViewWidget(controller: _controller!.webViewController),
        ),
        widget.loadingWidgetBuilder?.call(context) ?? const SizedBox.shrink(),
      ],
    );
  }
}

String getSharedTeXViewRawData(SharedControllerTeXView teXView) {
  return jsonEncode({
    'meta': const TeXViewWidgetMeta(
            tag: 'div', classList: 'tex-view', node: Node.root)
        .toJson(),
    'fonts': (null ?? []).map((font) => font.toJson()).toList(), // TODO
    'data': teXView.child.toJson(),
    'style': teXView.style?.initStyle() ?? teXViewDefaultStyle
  });
}
