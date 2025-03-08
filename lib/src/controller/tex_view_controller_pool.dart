import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_tex/src/controller/tex_view_controller.dart';

/// A pool of TeXViewController instances for efficient use in PageView
class TeXViewControllerPool {
  /// Maximum number of controllers to keep in the pool
  final int maxControllers;

  /// Map of controllers by their index
  final Map<int, TeXViewController> _controllers = {};

  /// Queue to track the least recently used controller indices
  final Queue<int> _lruQueue = Queue<int>();

  /// Map to store rendered heights by page index
  final Map<int, double> _pageHeights = {};

  /// Custom head content to use for all controllers
  String _customHeadContent = '';

  /// Callback for when a page is rendered
  final void Function(int pageIndex, double height)? onRenderFinished;

  /// Create a new TeXViewControllerPool with a maximum number of controllers
  TeXViewControllerPool(
      {this.maxControllers = 2,
      this.onRenderFinished,
      String customHeadContent = ''}) {
    _customHeadContent = customHeadContent;
  }

  /// Get a controller for a specific page index, initializing if needed
  Future<TeXViewController?> getControllerForPage(int pageIndex) async {
    // Check if the controller is already in the pool
    if (_controllers.containsKey(pageIndex)) {
      _updateLRU(pageIndex);
      return _controllers[pageIndex];
    }

    try {
      // Create a new controller
      final controller = TeXViewController(id: 'controller_$pageIndex');

      // Set up callbacks
      controller.onTeXViewRenderedCallback = (height) {
        final doubleHeight = double.tryParse(height);
        if (doubleHeight != null) {
          _pageHeights[pageIndex] = doubleHeight;
          onRenderFinished?.call(pageIndex, doubleHeight);
        }
      };

      // Initialize the controller
      await controller.initialize(customHeadContent: _customHeadContent);

      // Check if we need to remove controllers (LRU eviction)
      if (_controllers.length >= maxControllers) {
        await _evictLRU();
      }

      // Add the new controller to the pool
      _controllers[pageIndex] = controller;
      _updateLRU(pageIndex);

      return controller;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating controller for page $pageIndex: $e');
      }
      return null;
    }
  }

  /// Preload a controller for a specific page index
  Future<void> preloadController(int pageIndex) async {
    if (_controllers.containsKey(pageIndex)) return;

    // If we're at capacity, don't preload
    if (_controllers.length >= maxControllers) return;

    await getControllerForPage(pageIndex);
  }

  /// Get the cached height for a page
  double? getHeightForPage(int pageIndex) {
    return _pageHeights[pageIndex];
  }

  /// Update the least recently used queue
  void _updateLRU(int pageIndex) {
    // Remove from queue if already there
    _lruQueue.removeWhere((index) => index == pageIndex);
    // Add to the end (most recently used)
    _lruQueue.addLast(pageIndex);
  }

  /// Evict the least recently used controller
  Future<void> _evictLRU() async {
    if (_lruQueue.isEmpty) return;

    final lruIndex = _lruQueue.removeFirst();
    final controller = _controllers.remove(lruIndex);

    if (controller != null) {
      if (kDebugMode) {
        print('Evicting controller for page $lruIndex');
      }
      await controller.dispose();
    }
  }

  /// Update custom head content for all active controllers
  Future<void> updateCustomHeadContent(String newCustomHeadContent) async {
    _customHeadContent = newCustomHeadContent;

    // Update all active controllers
    for (var controller in _controllers.values) {
      if (controller.isInitialized) {
        await controller.updateCustomHeadContent(newCustomHeadContent);
      }
    }
  }

  /// Clean up all controllers
  Future<void> dispose() async {
    for (var controller in _controllers.values) {
      await controller.dispose();
    }
    _controllers.clear();
    _lruQueue.clear();
  }
}
