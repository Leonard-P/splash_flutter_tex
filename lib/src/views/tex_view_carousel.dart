import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

import '../../flutter_tex.dart';
import '../models/widget_meta.dart';
import '../styles/style.dart';
import '../utils/style_utils.dart';
import '../widgets/composite.dart';
import '../widgets/document.dart';

// Default initial height for TeXViews before they report their actual height
const double initialHeight = 100.0;

class DualTeXViewController {
  late final TeXViewController controllerA;
  late final TeXViewController controllerB;

  // Track which page index each controller is handling
  int? _controllerAIndex;
  int? _controllerBIndex;

  // Custom head content for TeXViews
  final String customHeadContent;

  // Callback for when a page is rendered
  final Function(int pageIndex, double height)? onRenderFinished;

  bool _isInitialized = false;

  DualTeXViewController({
    required this.customHeadContent,
    this.onRenderFinished,
  });

  bool get isInitialized => _isInitialized;

  // Initialize the controllers
  Future<void> initialize() async {
    controllerA = TeXViewController(id: 'controllerA');
    controllerB = TeXViewController(id: 'controllerB');

    // Set up callbacks
    controllerA.onTeXViewRenderedCallback = (height) {
      if (_controllerAIndex != null) {
        final heightDouble = double.tryParse(height) ?? 0;
        onRenderFinished?.call(_controllerAIndex!, heightDouble);
      }
    };

    controllerB.onTeXViewRenderedCallback = (height) {
      if (_controllerBIndex != null) {
        final heightDouble = double.tryParse(height) ?? 0;
        onRenderFinished?.call(_controllerBIndex!, heightDouble);
      }
    };

    // Initialize the controllers in parallel
    await Future.wait([
      controllerA.initialize(customHeadContent: customHeadContent),
      controllerB.initialize(customHeadContent: customHeadContent),
    ]);

    _isInitialized = true;
  }

  // Get the controller for a specific page index
  TeXViewController? getControllerForPage(int pageIndex) {
    if (_controllerAIndex == pageIndex) return controllerA;
    if (_controllerBIndex == pageIndex) return controllerB;
    return null;
  }

  // Handle page change and prepare controllers for upcoming pages
  Future<void> handlePageChange(
      int currentIndex, List<int> upcomingTexPages) async {
    // If there are no upcoming pages, nothing to do
    if (upcomingTexPages.isEmpty) return;

    // First upcoming TeX page (could be the current page)
    final firstPage = upcomingTexPages[0];

    // Second upcoming TeX page if any
    final secondPage = upcomingTexPages.length > 1 ? upcomingTexPages[1] : null;

    // If neither controller is assigned to the first page, assign one
    if (_controllerAIndex != firstPage && _controllerBIndex != firstPage) {
      // Choose which controller to reassign
      if (_controllerBIndex == currentIndex) {
        // If B is showing the current page, move A to the next page
        _controllerAIndex = firstPage;
      } else {
        // Otherwise, move B to the next page
        _controllerBIndex = firstPage;
      }
    }

    // If there's a second page and neither controller is assigned to it, assign one
    if (secondPage != null &&
        _controllerAIndex != secondPage &&
        _controllerBIndex != secondPage) {
      // Choose the controller that isn't showing the first page
      if (_controllerAIndex == firstPage) {
        _controllerBIndex = secondPage;
      } else {
        _controllerAIndex = secondPage;
      }
    }
  }

  // Preload controller for a specific page
  Future<TeXViewController?> preloadController(
      int pageIndex, int currentIndex) async {
    // If this page already has a controller, return it
    TeXViewController? existing = getControllerForPage(pageIndex);
    if (existing != null) return existing;

    // Determine which controller to use for this page
    TeXViewController controller;

    // If controller A is showing the current page, use controller B for preloading
    if (_controllerAIndex == currentIndex) {
      _controllerBIndex = pageIndex;
      controller = controllerB;
    }
    // If controller B is showing the current page, use controller A for preloading
    else if (_controllerBIndex == currentIndex) {
      _controllerAIndex = pageIndex;
      controller = controllerA;
    }
    // If neither controller is showing current page, prioritize controller A if available
    else if (_controllerAIndex == null ||
        (_controllerBIndex != null &&
            _controllerAIndex! > _controllerBIndex!)) {
      _controllerAIndex = pageIndex;
      controller = controllerA;
    }
    // Otherwise use controller B
    else {
      _controllerBIndex = pageIndex;
      controller = controllerB;
    }

    return controller;
  }

  // Render content in a controller for a specific page
  Future<void> renderContent(
      int pageIndex, dynamic content, TeXViewStyle? style) async {
    final controller = getControllerForPage(pageIndex);
    if (controller == null) return;

    try {
      String rawData;

      if (content is TeXViewDocument) {
        rawData = jsonEncode({
          'meta': const TeXViewWidgetMeta(
                  tag: 'div', classList: 'tex-view', node: Node.root)
              .toJson(),
          'fonts': [],
          'data': content.toJson(),
          'style': style?.initStyle() ?? teXViewDefaultStyle,
        });
      } else if (content is TeXViewComposite) {
        final document = content.document;
        rawData = jsonEncode({
          'meta': const TeXViewWidgetMeta(
                  tag: 'div', classList: 'tex-view', node: Node.root)
              .toJson(),
          'fonts': [],
          'data': document.toJson(),
          'style': style?.initStyle() ?? teXViewDefaultStyle,
        });
      } else {
        return;
      }

      await controller.render(rawData);
    } catch (e) {
      if (kDebugMode) {
        print('Error rendering content for page $pageIndex: $e');
      }
    }
  }

  // Update custom head content for all controllers
  Future<void> updateCustomHeadContent(String newCustomHeadContent) async {
    await Future.wait([
      controllerA.updateCustomHeadContent(newCustomHeadContent),
      controllerB.updateCustomHeadContent(newCustomHeadContent),
    ]);
  }

  // Check if a controller is assigned and ready for a page
  bool isControllerReady(int pageIndex) {
    if (_controllerAIndex == pageIndex) return controllerA.isInitialized;
    if (_controllerBIndex == pageIndex) return controllerB.isInitialized;
    return false;
  }

  // Get indices of pages currently handled by controllers
  List<int> get managedIndices => [
        if (_controllerAIndex != null) _controllerAIndex!,
        if (_controllerBIndex != null) _controllerBIndex!,
      ];

  // Dispose controllers
  void dispose() {
    controllerA.dispose();
    controllerB.dispose();
  }
}

/// A carousel widget that efficiently displays multiple TeXViews in a PageView
class TeXViewCarousel extends StatefulWidget {
  /// Total number of items in the carousel
  final int itemCount;

  /// Builder function that returns an item for a given index
  /// Note: Items can be either TeXViewDocument, TeXViewComposite, or any other widget
  final dynamic Function(BuildContext context, int index) itemBuilder;

  /// Custom PageController
  final PageController? controller;

  /// Style for TeXViews
  final TeXViewStyle? style;

  /// Optional padding to apply around the TeXView content
  final EdgeInsetsGeometry? padding;

  /// Custom head content for TeXViews
  final String customHeadContent;

  /// Callback when a page changes
  final Function(int)? onPageChanged;

  /// Callback when a TeXView finishes rendering
  final Function(int, double)? onRenderFinished;

  /// Callback to build a loading widget
  final Widget Function(BuildContext)? loadingWidgetBuilder;

  /// Create a new TeXViewCarousel
  const TeXViewCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.style,
    this.padding,
    this.customHeadContent = '',
    this.onPageChanged,
    this.onRenderFinished,
    this.loadingWidgetBuilder,
  });

  /// Factory constructor that accepts a list of items instead of an itemBuilder
  factory TeXViewCarousel.fromItems({
    Key? key,
    required List<dynamic> items,
    PageController? controller,
    TeXViewStyle? style,
    EdgeInsetsGeometry? padding,
    String customHeadContent = '',
    Function(int)? onPageChanged,
    Function(int, double)? onRenderFinished,
    Widget Function(BuildContext)? loadingWidgetBuilder,
  }) {
    return TeXViewCarousel(
      key: key,
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
      controller: controller,
      style: style,
      padding: padding,
      customHeadContent: customHeadContent,
      onPageChanged: onPageChanged,
      onRenderFinished: onRenderFinished,
      loadingWidgetBuilder: loadingWidgetBuilder,
    );
  }

  @override
  State<TeXViewCarousel> createState() => _TeXViewCarouselState();
}

class _TeXViewCarouselState extends State<TeXViewCarousel> {
  /// PageController for the carousel
  late PageController _pageController;

  /// Current page index
  late int _currentPageIndex;

  /// Preloaded page index
  int? _preloadedPageIndex;

  /// Dual controller manager
  late DualTeXViewController _dualController;

  /// Map of page heights by index
  final Map<int, double> _heights = {};

  /// Map to track which pages have TeXView content and what type
  final Map<int, _TeXViewType> _texViewTypes = {};

  // Track if animation is in progress
  bool _isAnimating = false;

  List<int> upcomingTexPages = [];

  @override
  void initState() {
    super.initState();

    // Initialize the page controller
    _pageController = widget.controller ?? PageController(initialPage: 0);
    _currentPageIndex = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listen to scroll state changes to detect end of animation
      _pageController.position.isScrollingNotifier
          .addListener(_handleScrollEnd);
    });

    // Initialize dual controller
    _dualController = DualTeXViewController(
      customHeadContent: widget.customHeadContent,
      onRenderFinished: (pageIndex, height) {
        if (mounted) {
          setState(() {
            _heights[pageIndex] = height;
          });

          // Notify listener
          widget.onRenderFinished?.call(pageIndex, height);
          if (kDebugMode) {
            print("height mapped to $pageIndex: $height");
          }
        }
      },
    );

    _identifyTeXViewItems();
    // Initialize the dual controller
    _dualController.initialize().then((_) {
      // Identify which pages have TeXView content

      // Set up initial page display
      if (mounted) {
        _prepareInitialPages();
      }
    });
  }

  // Handle end of scroll animation
  void _handleScrollEnd() {
    if (!_pageController.position.isScrollingNotifier.value && _isAnimating) {
      _isAnimating = false;
      if (kDebugMode) {
        print('Animation completed for page $_currentPageIndex');
      }
      // Complete any pending controller updates
      _completePageChange();
    }
  }

  /// Identify which items are TeXView documents or composites
  void _identifyTeXViewItems() {
    for (int i = 0; i < widget.itemCount; i++) {
      final item = widget.itemBuilder(context, i);
      if (item is TeXViewDocument) {
        _texViewTypes[i] = _TeXViewType.document;
      } else if (item is TeXViewComposite) {
        _texViewTypes[i] = _TeXViewType.composite;
      } else {
        _texViewTypes[i] = _TeXViewType.none;
      }
    }
  }

  /// Prepare initial pages when carousel is first displayed
  Future<void> _prepareInitialPages() async {
    // Find upcoming TeX pages
    List<int> upcomingTexPages = [];

    // Get first TeX page
    var nextIndex = _getNextTeXPageIndex(0);
    if (nextIndex != null) {
      upcomingTexPages.add(nextIndex);

      // Get second TeX page if exists
      var secondIndex = _getNextTeXPageIndex(nextIndex + 1);
      if (secondIndex != null) {
        upcomingTexPages.add(secondIndex);
      }
    }

    // Update current page index if first page is a TeX page
    if (upcomingTexPages.isNotEmpty && upcomingTexPages[0] == 0) {
      _currentPageIndex = 0;
    }

    // Handle page preparation
    await _dualController.handlePageChange(_currentPageIndex, upcomingTexPages);

    // Render content for all upcoming pages
    for (int pageIndex in upcomingTexPages) {
      await _preparePageIfNeeded(pageIndex);
    }
  }

  /// Check if there's a next page that requires a TeXView controller
  int? _getNextTeXPageIndex(int fromIndex) {
    if (fromIndex >= widget.itemCount) return null;

    // Check if any of the next pages is a TeXView page
    for (int i = fromIndex; i < widget.itemCount; i++) {
      if (_texViewTypes[i] != _TeXViewType.none) return i;
    }
    return null;
  }

  /// Prepare a page for display if it's a TeXView page
  Future<void> _preparePageIfNeeded(int pageIndex) async {
    // Skip if not a TeXView page or out of bounds
    if (pageIndex < 0 ||
        pageIndex >= widget.itemCount ||
        _texViewTypes[pageIndex] == _TeXViewType.none) {
      return;
    }

    // Track preloaded page if it's not the current page
    if (pageIndex != _currentPageIndex) {
      _preloadedPageIndex = pageIndex;
    }

    try {
      // Get controller and render content
      final controller =
          await _dualController.preloadController(pageIndex, _currentPageIndex);
      if (controller != null && mounted) {
        final item = widget.itemBuilder(context, pageIndex);
        await _dualController.renderContent(pageIndex, item, widget.style);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error preparing page $pageIndex: $e');
      }
    }
  }

  /// Handle page changes
  void _onPageChanged(int newPageIndex) async {
    if (kDebugMode) {
      print('Page changed to $newPageIndex');
      print('Current managed pages: ${_dualController.managedIndices}');
    }

    final oldPageIndex = _currentPageIndex;
    _currentPageIndex = newPageIndex;
    _isAnimating = true;

    // First, notify the callback if provided
    widget.onPageChanged?.call(newPageIndex);

    // Find all upcoming TeX pages regardless of current page type
    upcomingTexPages = [];

    // Check if current page is a TeX page
    late final int nextForwardIndex;
    if (_texViewTypes[newPageIndex] != _TeXViewType.none) {
      upcomingTexPages.add(newPageIndex);
      nextForwardIndex = newPageIndex;
    } else {
      // If not a TeX page, look for next TeX page in forward direction
      nextForwardIndex = _getNextTeXPageIndex(newPageIndex + 1) ?? newPageIndex;
      if (nextForwardIndex != newPageIndex) {
        upcomingTexPages.add(nextForwardIndex);
      }
    }

    // Also look for next TeX page in backward direction if we're moving backwards
    if (newPageIndex < oldPageIndex) {
      final nextBackwardIndex = _getPreviousTeXPageIndex(newPageIndex - 1);
      if (nextBackwardIndex != null &&
          !upcomingTexPages.contains(nextBackwardIndex)) {
        upcomingTexPages.add(nextBackwardIndex);
      }
    } else {
      // Look for next TeX page in forward direction
      final secondNextForwardIndex = _getNextTeXPageIndex(nextForwardIndex + 1);
      if (secondNextForwardIndex != null) {
        upcomingTexPages.add(secondNextForwardIndex);
      }
    }

    if (kDebugMode) {
      print('Upcoming TeX pages: $upcomingTexPages');
    }

    // If no upcoming TeX pages, nothing to do for controllers
    if (upcomingTexPages.isEmpty) {
      if (kDebugMode) {
        print('No TeX pages to prepare');
      }
      return;
    }
  }

  Future<void> _completePageChange() async {
    // Handle controller management
    await _dualController.handlePageChange(_currentPageIndex, upcomingTexPages);

    // Track which pages need state update
    Set<int> pagesNeedingUpdate = {};

    // Prepare each upcoming page
    for (int pageIndex in upcomingTexPages) {
      // Always track as preloaded if not current
      if (pageIndex != _currentPageIndex) {
        _preloadedPageIndex = pageIndex;
      }

      // Check if page already has a controller ready
      if (!_dualController.isControllerReady(pageIndex)) {
        if (kDebugMode) {
          print('Preparing page $pageIndex');
        }
        await _preparePageIfNeeded(pageIndex);
        pagesNeedingUpdate.add(pageIndex);
      } else if (_dualController.getControllerForPage(pageIndex) != null) {
        // If controller exists but content might need update
        if (kDebugMode) {
          print('Controller exists for page $pageIndex');
        }

        // Re-render content if this is a page we just moved to
        if (pageIndex == _currentPageIndex) {
          final item = widget.itemBuilder(context, pageIndex);
          await _dualController.renderContent(pageIndex, item, widget.style);
          pagesNeedingUpdate.add(pageIndex);
        }
      }

      // Update state if needed
      if (mounted && pagesNeedingUpdate.isNotEmpty) {
        if (kDebugMode) {
          print('Updating state for pages: $pagesNeedingUpdate');
          print(
              'Current managed pages after update: ${_dualController.managedIndices}');
        }
      }
    }

    // Update state if needed
    if (mounted && pagesNeedingUpdate.isNotEmpty) {
      if (kDebugMode) {
        print('Updating state for pages: $pagesNeedingUpdate');
        print(
            'Current managed pages after update: ${_dualController.managedIndices}');
      }
      setState(() {});
    }
  }

  /// Get the previous page that requires a TeXView controller
  int? _getPreviousTeXPageIndex(int fromIndex) {
    if (fromIndex < 0) return null;

    // Check if any of the previous pages is a TeXView page
    for (int i = fromIndex; i >= 0; i--) {
      if (_texViewTypes[i] != _TeXViewType.none) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.itemCount,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final texViewType = _texViewTypes[index] ?? _TeXViewType.none;
        final item = widget.itemBuilder(context, index);

        if (texViewType == _TeXViewType.none) {
          // Return the regular widget if it's not a TeXViewDocument or composite
          return item;
        } else if (texViewType == _TeXViewType.document) {
          // It's a standard TeXViewDocument, return a TeXView
          return _buildTeXView(index, item);
        } else {
          // It's a composite, we need to combine TeXView with Flutter widgets
          return _buildCompositeView(index, item as TeXViewComposite);
        }
      },
    );
  }

  /// Build a standard TeXView
  Widget _buildTeXView(int index, dynamic item) {
    // Get the controller for this page
    final controller = _dualController.getControllerForPage(index);
    final isCurrentPage = index == _currentPageIndex;

    if (controller == null) {
      if (kDebugMode) {
        print('No controller for page $index, showing loading');
      }
      return widget.loadingWidgetBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    // Get the page height or use initialHeight if not yet calculated
    final height = _heights[index] ?? initialHeight;
    final isLoading = !controller.isInitialized;

    Widget texView = SizedBox(
      height: height,
      child: Stack(
        children: [
          // The WebView - IMPORTANT: Only show for current page to avoid performance issues
          if (isCurrentPage || index == _preloadedPageIndex)
            Visibility(
              visible: isCurrentPage,
              maintainState: true, // Keep state when not visible
              maintainAnimation: true,
              maintainSize: true,
              maintainSemantics: true,
              maintainInteractivity: false,
              child: WebViewWidget(
                controller: controller.webViewController,
              ),
            ),

          // Loading widget, shown until height is determined
          if (isLoading && widget.loadingWidgetBuilder != null)
            widget.loadingWidgetBuilder!(context),
        ],
      ),
    );

    // Apply padding if specified
    if (widget.padding != null) {
      texView = Padding(
        padding: widget.padding!,
        child: texView,
      );
    }

    return texView;
  }

  /// Build a composite view with TeXView and Flutter widgets
  Widget _buildCompositeView(int index, TeXViewComposite composite) {
    // Get the controller for this page
    final controller = _dualController.getControllerForPage(index);
    final isCurrentPage = index == _currentPageIndex;

    if (controller == null) {
      if (kDebugMode) {
        print('No controller for composite page $index, showing loading');
      }
      return widget.loadingWidgetBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    // Get the page height or use initialHeight if not yet calculated
    final texHeight = _heights[index] ?? initialHeight;
    final isLoading = !controller.isInitialized;

    Widget texViewContent = SizedBox(
      height: texHeight,
      child: Stack(
        children: [
          // The WebView - IMPORTANT: Only create for current or preloaded pages
          if (isCurrentPage || index == _preloadedPageIndex)
            Visibility(
              visible: isCurrentPage,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              maintainSemantics: true,
              maintainInteractivity: false,
              child: WebViewWidget(
                controller: controller.webViewController,
              ),
            ),

          // Loading widget, shown until height is determined
          if (isLoading && widget.loadingWidgetBuilder != null)
            widget.loadingWidgetBuilder!(context),
        ],
      ),
    );

    // Apply padding to the TeXView part if specified
    if (widget.padding != null) {
      texViewContent = Padding(
        padding: widget.padding!,
        child: texViewContent,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Widget above, if any
          if (composite.above != null) ...[
            composite.above!,
            SizedBox(height: composite.spacing),
          ],

          // The TeXView in the middle
          texViewContent,

          // Widget below, if any
          if (composite.below != null) ...[
            SizedBox(height: composite.spacing),
            composite.below!,
          ],
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(TeXViewCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update custom head content if it changed
    if (widget.customHeadContent != oldWidget.customHeadContent) {
      _dualController.updateCustomHeadContent(widget.customHeadContent);
    }
  }

  @override
  void dispose() {
// Remove scroll listener
    _pageController.position.isScrollingNotifier
        .removeListener(_handleScrollEnd);

    // Dispose the dual controller
    _dualController.dispose();

    // Dispose page controller if we created it
    if (widget.controller == null) {
      _pageController.dispose();
    }

    super.dispose();
  }
}

/// Enum to represent the different types of TeXView content
enum _TeXViewType {
  none, // Not a TeXView (regular Flutter widget)
  document, // Standard TeXViewDocument
  composite, // TeXViewComposite (TeXView with Flutter widgets)
}
