import 'package:flutter_tex/flutter_tex.dart';

/// A pool of TeX view controllers that can be shared across multiple TeXView widgets.
///
/// This controller pool helps reduce memory usage by reusing controllers
/// and keeping the total number of controller instances limited.
class SharedTexViewControllerPool {
  // Configuration
  final int maxControllers;

  // Mapping from user-assigned id (String) to controllers.
  final Map<String, TeXViewController> _controllers = {};

  // To track recency (oldest first): list of ids (the first is least recently used)
  final List<String> _lruList = [];

  // Stored custom head content for all controllers.
  String _customHeadContent = '';

  /// Creates a new controller pool with the specified maximum number of controllers.
  ///
  /// The [maxControllers] parameter determines how many controllers can exist
  /// simultaneously before the least recently used one is recycled.
  SharedTexViewControllerPool({this.maxControllers = 3});

  /// Get a controller for the given id.
  Future<TeXViewController> get(String id) async {
    if (_controllers.containsKey(id)) {
      _updateLRU(id);
      return _controllers[id]!;
    } else if (_controllers.length < maxControllers) {
      // Create new controller
      final controller = TeXViewController(id: id);
      await controller.initialize(
          customHeadContent: _customHeadContent, waitForPageFinished: false);
      _controllers[id] = controller;
      _lruList.add(id);
      return controller;
    } else {
      // Reuse the least recently used controller
      final oldestId = _lruList.removeAt(0);
      final controller = _controllers.remove(oldestId)!;
      _controllers[id] = controller;
      _lruList.add(id);
      return controller;
    }
  }

  void _updateLRU(String id) {
    _lruList.removeWhere((element) => element == id);
    _lruList.add(id);
  }

  /// Gets the current custom head content.
  String get customHeadContent => _customHeadContent;

  /// Update custom head content in pool.
  Future<void> updateCustomHeadContent(String newHeadContent) async {
    _customHeadContent = newHeadContent;
    for (var controller in _controllers.values) {
      if (controller.isInitialized) {
        await controller.updateCustomHeadContent(newHeadContent);
      }
    }
  }

  /// Returns whether this pool contains a controller with the given id.
  bool hasController(String id) => _controllers.containsKey(id);

  /// Returns the current number of controllers in the pool.
  int get controllerCount => _controllers.length;

  /// Dispose all controllers and clear the pool.
  /// Call this method when the pool is no longer needed.
  Future<void> dispose() async {
    for (var controller in _controllers.values) {
      await controller.dispose();
    }
    _controllers.clear();
    _lruList.clear();
  }
}
