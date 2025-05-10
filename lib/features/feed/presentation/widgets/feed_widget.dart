import 'package:empathy_hub_app/features/feed/presentation/models/post_model.dart'; // Changed import
import 'package:empathy_hub_app/features/feed/presentation/widgets/feed_item_widget.dart';
import 'package:empathy_hub_app/features/feed/data/mock/mock_feed_data.dart';
import 'package:flutter/material.dart';

class FeedWidget extends StatefulWidget {
  const FeedWidget({super.key});

  @override
  State<FeedWidget> createState() => _FeedWidgetState();
}

class _FeedWidgetState extends State<FeedWidget> {
  final List<Post> _displayedItems = []; // Changed type to Post
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;
  final int _itemsPerPage = 7; // Number of items to load per "page"

  @override
  void initState() {
    super.initState();
    // print("FeedWidget: initState - Calling initial _loadMoreItems.");
    _loadMoreItems(); // Load initial items
    _scrollController.addListener(() {
      // print("FeedWidget Scroll: pixels=${_scrollController.position.pixels}, extentAfter=${_scrollController.position.extentAfter}, maxScrollExtent=${_scrollController.position.maxScrollExtent}");
      // print("FeedWidget Scroll: isLoadingMore=$_isLoadingMore, hasMoreItems=$_hasMoreItems");
      // Check if the user has scrolled to near the bottom of the list
      if (_scrollController.position.extentAfter < 300 && // 300 pixels from bottom
          !_isLoadingMore &&
          _hasMoreItems) {
        // print("FeedWidget Scroll: Condition MET to load more items via scroll.");
        _loadMoreItems();
      }
    });
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreItems) {
      // print("FeedWidget: _loadMoreItems - Bailing out. isLoadingMore: $_isLoadingMore, hasMoreItems: $_hasMoreItems");
      return;
    }

    // print("FeedWidget: _loadMoreItems START - displayedItems: ${_displayedItems.length}");
    setState(() {
      _isLoadingMore = true;
    });

    // Simulate a network delay, like fetching from an API
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return; // Check if the widget is still in the tree

    final int currentLength = _displayedItems.length;
    final int endOfList = currentLength + _itemsPerPage;

    // Get the next batch of items from our mock data source
    final itemsToAdd = allMockFeedItems.sublist(
        currentLength,
        endOfList > allMockFeedItems.length
            ? allMockFeedItems.length
            : endOfList);
    // print("FeedWidget: _loadMoreItems - Attempting to add ${itemsToAdd.length} items.");
    _displayedItems.addAll(itemsToAdd);

    setState(() {
      _isLoadingMore = false;
      _hasMoreItems = _displayedItems.length < allMockFeedItems.length;
      // print("FeedWidget: _loadMoreItems END - isLoadingMore: $_isLoadingMore, hasMoreItems: $_hasMoreItems, displayed: ${_displayedItems.length}, total: ${allMockFeedItems.length}");

      // After loading, check if the content is still not scrollable and more items exist.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _hasMoreItems && !_isLoadingMore && _scrollController.position.maxScrollExtent <= _scrollController.position.pixels) {
          // print("FeedWidget: Content not scrollable after load, but more items exist. Triggering another load.");
          _loadMoreItems();
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _displayedItems.length + (_hasMoreItems ? 1 : 0), // +1 for loading indicator
      itemBuilder: (BuildContext context, int index) {
        // If it's the last item and there are more items to load, show a loading indicator
        if (index == _displayedItems.length && _hasMoreItems) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        // Ensure we don't try to access an index out of bounds
        if (index >= _displayedItems.length) return null; 

        final item = _displayedItems[index];
        return FeedItemWidget(item: item);
      },
    );
  }
}