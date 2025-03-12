import 'dart:convert';

import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_tex/src/models/widget_meta.dart';
import 'package:flutter_tex/src/utils/style_utils.dart';
import 'package:flutter_tex/src/views/tex_view.dart';

const double initialHeight = 0.1;

String getRawData(TeXView teXView) {
  return jsonEncode({
    'meta': const TeXViewWidgetMeta(
            tag: 'div', classList: 'tex-view', node: Node.root)
        .toJson(),
    'fonts': (teXView.fonts ?? []).map((font) => font.toJson()).toList(),
    'data': teXView.child.toJson(),
    'style': teXView.style?.initStyle() ?? teXViewDefaultStyle
  });
}

String getRawDataIndependent(IndependentTeXView teXView) {
  return jsonEncode({
    'meta': const TeXViewWidgetMeta(
            tag: 'div', classList: 'tex-view', node: Node.root)
        .toJson(),
    'fonts': (null ?? []).map((font) => font.toJson()).toList(), // TODO
    'data': teXView.child.toJson(),
    'style': null ?? teXViewDefaultStyle // TODO
  });
}
