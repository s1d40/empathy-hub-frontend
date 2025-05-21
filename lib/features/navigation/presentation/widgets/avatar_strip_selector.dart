import 'package:flutter/material.dart';

class AvatarStripSelector extends StatefulWidget {
  final List<String> allAvatarUrls;
  final String? currentSelectedAvatarUrl;
  final Function(String) onAvatarSelectedBySwipe;
  // final VoidCallback onLargeAvatarTap; // Removed
  final double avatarRadius; // Was smallAvatarRadius, now the only radius
  final double viewportFraction;
  final double stripLayoutHeight; // New: defines the height for layout
  final double avatarHorizontalSpacing;    // New: horizontal space between avatars

  const AvatarStripSelector({
    super.key,
    required this.allAvatarUrls,
    this.currentSelectedAvatarUrl,
    required this.onAvatarSelectedBySwipe,
    // required this.onLargeAvatarTap, // Removed
    this.avatarRadius = 25.0, // Default radius for all avatars in the strip
    this.viewportFraction = 0.33, 
    // Default stripLayoutHeight based on default avatarRadius (25*2 + 16 padding = 66)
    this.stripLayoutHeight = (25.0 * 2) + 16.0, // Default based on default avatarRadius
    this.avatarHorizontalSpacing = 4.0, // Adjusted default for general use, app_drawer overrides it
  });

  @override
  State<AvatarStripSelector> createState() => _AvatarStripSelectorState();
}

class _AvatarStripSelectorState extends State<AvatarStripSelector> {
  PageController? _pageController;
  int _selectedPageIndex = 0;
  bool _isProgrammaticJump = false;

  @override
  void initState() {
    super.initState();
    _initializeControllerAndPage();
  }

  void _initializeControllerAndPage() {
    int initialPage = 0;
    if (widget.currentSelectedAvatarUrl != null && widget.allAvatarUrls.isNotEmpty) {
      initialPage = widget.allAvatarUrls.indexOf(widget.currentSelectedAvatarUrl!);
      if (initialPage == -1) initialPage = 0; // Fallback
    }
    _selectedPageIndex = initialPage;

    _pageController?.dispose(); // Dispose old controller if any
    _pageController = PageController(
      initialPage: _selectedPageIndex,
      viewportFraction: widget.viewportFraction,
    );
    // Add listener to handle programmatic jumps vs user swipes
    _pageController!.addListener(() {
      if (_pageController!.page == _pageController!.page?.roundToDouble()) {
        // Page has settled
        if (_isProgrammaticJump) {
          // If it was a programmatic jump, reset the flag
          // and don't trigger onAvatarSelectedBySwipe
          setState(() {
            _isProgrammaticJump = false;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(AvatarStripSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool needsControllerRebuild = false;
    bool needsPageAnimation = false;

    // Determine the target page index based on current props
    int newCalculatedPageIndex = 0; // Default if no avatars or selected URL
    if (widget.currentSelectedAvatarUrl != null && widget.allAvatarUrls.isNotEmpty) {
      newCalculatedPageIndex = widget.allAvatarUrls.indexOf(widget.currentSelectedAvatarUrl!);
      if (newCalculatedPageIndex == -1) newCalculatedPageIndex = 0; // Fallback
    }

    // Check if controller needs a full rebuild due to viewportFraction or list length change
    if (widget.viewportFraction != oldWidget.viewportFraction ||
        widget.allAvatarUrls.length != oldWidget.allAvatarUrls.length) {
      needsControllerRebuild = true;
    }

    // Check if the selected page needs to change (even if controller isn't rebuilt)
    if (newCalculatedPageIndex != _selectedPageIndex) {
      needsPageAnimation = true;
    }

    if (needsControllerRebuild) {
      // Rebuild controller. _initializeControllerAndPage will use the new widget props
      // and correctly set _selectedPageIndex.
      _initializeControllerAndPage();
    } else if (needsPageAnimation) {
      // Only the selected avatar changed, viewportFraction and list length are the same. Animate.
      setState(() {
        _selectedPageIndex = newCalculatedPageIndex;
        _isProgrammaticJump = true; // Mark that this change is programmatic
      });
      if (_pageController!.hasClients) {
        _pageController!.animateToPage(
          _selectedPageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      // If no clients, _selectedPageIndex is updated, PageController will use it when it gets clients.
    }
  }


  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allAvatarUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final stripHeight = widget.stripLayoutHeight;

    return SizedBox(
      height: stripHeight,
      child: PageView.builder(
        controller: _pageController, // Ensure _pageController is not null
        itemCount: widget.allAvatarUrls.length,
        clipBehavior: Clip.none, // Allow larger selected avatar to overflow PageView bounds
        onPageChanged: (int index) {
          if (_isProgrammaticJump) {
            // If the page change was due to a programmatic jump,
            // do not call onAvatarSelectedBySwipe.
            // The flag will be reset by the controller's listener.
            setState(() {
              _selectedPageIndex = index;
            });
            return;
          }
          // This is a user swipe
          setState(() {
            _selectedPageIndex = index;
          });
          widget.onAvatarSelectedBySwipe(widget.allAvatarUrls[index]);
        },
        itemBuilder: (context, index) {
          final avatarUrl = widget.allAvatarUrls[index];
          bool isTheCurrentlySelectedOne = (index == _selectedPageIndex);

          Widget avatarWidget;

          if (isTheCurrentlySelectedOne) {
            // If this is the selected avatar in the strip, make it an empty placeholder
            // to create the illusion that the large static avatar is part of the strip.
            // The size should match the other avatars in the strip.
            avatarWidget = SizedBox(
              width: widget.avatarRadius * 2,
              height: widget.avatarRadius * 2,
            );
          } else {
            // For all other avatars, display them normally.
            avatarWidget = Opacity(
              opacity: 1.0, // Full opacity
              child: CircleAvatar(
                backgroundImage: NetworkImage(avatarUrl),
                radius: widget.avatarRadius,
              ),
            );
          }
          return Center( // Center each item in its allocated page space
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.avatarHorizontalSpacing),
              child: avatarWidget,
            ),
          );
        },
      ),
    );
  }
}
