import 'package:flutter/material.dart';
import 'package:flutter_tex/src/widgets/document.dart';

/// A composite widget that combines a TeXView document with Flutter widgets above and/or below it
class TeXViewComposite {
  /// The TeXView document to render
  final TeXViewDocument document;

  /// Widget to display above the TeXView
  final Widget? above;

  /// Widget to display below the TeXView
  final Widget? below;

  /// Space between the TeXView and the widgets above/below
  final double spacing;

  /// Create a composite TeXView with Flutter widgets
  const TeXViewComposite({
    required this.document,
    this.above,
    this.below,
    this.spacing = 8.0,
  });
}
