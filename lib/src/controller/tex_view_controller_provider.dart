import 'package:flutter/widgets.dart';
import 'package:flutter_tex/flutter_tex.dart';

/// A provider for accessing the SharedTexViewControllerPool throughout an app.
///
/// This provider uses the InheritedWidget pattern to make the controller pool accessible
/// from anywhere in the widget tree.
class TeXViewControllerProvider extends InheritedWidget {
  final SharedTexViewControllerPool pool;

  /// Creates a TeXViewControllerProvider.
  ///
  /// The [pool] parameter is the controller pool to be provided.
  /// The [child] parameter is the widget below this widget in the tree.
  const TeXViewControllerProvider({
    super.key,
    required this.pool,
    required super.child,
  });

  /// Gets the TeXViewControllerProvider from the specified build context.
  static TeXViewControllerProvider of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<TeXViewControllerProvider>();
    if (provider == null) {
      throw FlutterError(
          'TeXViewControllerProvider.of() called with a context that does not contain a TeXViewControllerProvider.\n'
          'Make sure to wrap your app or a portion of your app with TeXViewControllerProvider.');
    }
    return provider;
  }

  /// Gets the controller pool from the specified build context.
  static SharedTexViewControllerPool poolOf(BuildContext context) {
    return of(context).pool;
  }

  @override
  bool updateShouldNotify(TeXViewControllerProvider oldWidget) {
    return pool != oldWidget.pool;
  }
}
