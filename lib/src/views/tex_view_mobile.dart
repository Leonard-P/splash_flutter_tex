import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_tex/src/utils/core_utils.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

class TeXViewState extends State<TeXView> {
  final WebViewControllerPlus _controller = TeXRederingServer.controller;

  double _currentHeight = initialHeight;
  String _lastRawData = "";
  bool _initialRenderComplete = false;

  @override
  void initState() {
    TeXRederingServer.onTeXViewRenderedCallback =
        (teXViewRenderedCallbackMessage) {
      double newHeight = double.parse(teXViewRenderedCallbackMessage);

      if ((_currentHeight != newHeight || !_initialRenderComplete) && mounted) {
        setState(() {
          _currentHeight = newHeight;
          _initialRenderComplete = true;
        });
        widget.onRenderFinished?.call(_currentHeight);
      }
    };

    TeXRederingServer.onTapCallback =
        (tapCallbackMessage) => widget.child.onTapCallback(tapCallbackMessage);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _renderTeXView();
    return IndexedStack(
      index: widget.loadingWidgetBuilder?.call(context) != null
          ? !_initialRenderComplete
              ? 1
              : 0
          : 0,
      children: <Widget>[
        SizedBox(
          height: _currentHeight,
          child: WebViewWidget(
            controller: _controller,
          ),
        ),
        widget.loadingWidgetBuilder?.call(context) ?? const SizedBox.shrink()
      ],
    );
  }

  void _renderTeXView() async {
    var currentRawData = getRawData(widget);
    if (currentRawData != _lastRawData) {
      if (widget.loadingWidgetBuilder != null) {
        setState(() {
          _initialRenderComplete = false;
          _currentHeight = initialHeight;
        });
      }
      await _controller.runJavaScript("initView($currentRawData)");
      _lastRawData = currentRawData;
    }
  }
}
