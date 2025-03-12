import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_tex/src/utils/core_utils.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

/// An independent TeXView widget that uses its own controller
/// This allows multiple TeXViews to be used simultaneously without interfering with each other
/// Claude managed to use a shared server instance that's shared across all controllers
class IndependentTeXView extends StatefulWidget {
  final TeXViewRenderingEngine renderingEngine;
  final TeXViewWidget child;
  final Function(double height)? onRenderFinished;
  final Widget Function(BuildContext context)? loadingWidgetBuilder;

  const IndependentTeXView({
    super.key,
    this.renderingEngine = const TeXViewRenderingEngine.mathjax(),
    required this.child,
    this.onRenderFinished,
    this.loadingWidgetBuilder,
  });

  @override
  State<IndependentTeXView> createState() => _IndependentTeXViewState();
}

class _IndependentTeXViewState extends State<IndependentTeXView> {
  late TeXRenderingController _controller;
  double _currentHeight = initialHeight;
  String _lastRawData = "";
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  Future<void> _setupController() async {
    _controller = TeXRenderingController();
    _controller.renderingEngine = widget.renderingEngine;

    _controller.onTeXViewRenderedCallback = (teXViewRenderedCallbackMessage) {
      double newHeight = double.parse(teXViewRenderedCallbackMessage);
      if (_currentHeight != newHeight && mounted) {
        setState(() {
          _currentHeight = newHeight;
        });
        widget.onRenderFinished?.call(_currentHeight);
      }
    };

    _controller.onTapCallback =
        (tapCallbackMessage) => widget.child.onTapCallback(tapCallbackMessage);

    if (!kIsWeb) {
      await _controller.run();
      await _controller.initController();
      if (mounted) {
        setState(() {
          _isControllerInitialized = true;
        });
      }
    } else {
      setState(() {
        _isControllerInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isControllerInitialized) {
      return widget.loadingWidgetBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    _renderTeXView();
    return IndexedStack(
      index: widget.loadingWidgetBuilder?.call(context) != null
          ? _currentHeight == initialHeight
              ? 1
              : 0
          : 0,
      children: <Widget>[
        SizedBox(
          height: _currentHeight,
          child: WebViewWidget(
            controller: _controller.controller,
          ),
        ),
        widget.loadingWidgetBuilder?.call(context) ?? const SizedBox.shrink()
      ],
    );
  }

  void _renderTeXView() async {
    var currentRawData = getRawDataIndependent(widget);
    if (currentRawData != _lastRawData) {
      if (widget.loadingWidgetBuilder != null) _currentHeight = initialHeight;
      await _controller.controller.runJavaScript("initView($currentRawData)");
      _lastRawData = currentRawData;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
