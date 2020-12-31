
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instacritic/constants.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';
import 'instagram_repository.dart';
import 'star_display.dart';
import 'review.dart';
import 'label.dart';

class ListScreen extends StatefulWidget {
  final StreamController<List<Review>> reviewController; // ignore: close_sinks  
  final TabController tabController;
  final ScrollController scrollController;
  final TextEditingController textController;
  final FocusNode searchBoxFocusNode;
  final void Function(String) updateCurrentReviews;
  const ListScreen(this.scrollController, this.textController, this.searchBoxFocusNode, this.tabController, this.reviewController, this.updateCurrentReviews);
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool runOnce = true;
  

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if(!Provider.of<InstagramRepository>(context,listen: true).ready) {
      return Center(child: CircularProgressIndicator());
    }
    if(runOnce) { // This is the initial building of the list
      widget.reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).allReviews);
      runOnce = false;
    }
    return StreamBuilder( // Get the reviews as a stream so if you search or sort it updates again
            stream: widget.reviewController.stream,
            builder: (BuildContext buildContext, AsyncSnapshot<List<Review>> snapshot) {
              if(snapshot == null || snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              else {
                Provider.of<InstagramRepository>(context,listen:false).currentReviews = snapshot.data;
                List<Widget> slivs = [
                  _buildAppBar(),
                  _buildSearchBar(),
                  _buildSliverPadding(height: 4),
                  _buildReviewList(snapshot),
                ];
                // slivs.addAll(_getSliverList(snapshot));
                slivs.add(_buildSliverPadding(height: 20)); // Bottom padding for convex
                return CupertinoScrollbar(
                  child: CustomScrollView(
                    controller: widget.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    cacheExtent: 10000.0, // https://github.com/flutter/flutter/issues/22314
                    slivers: slivs),
                );}});
  }

  SliverToBoxAdapter _buildSliverPadding({double height}) => SliverToBoxAdapter(child: Container(height:height));

  // List<Widget> _getSliverList(AsyncSnapshot<List<Review>> snapshot) {
  //   return snapshot.data.map((review) => SliverToBoxAdapter(child: _buildRow(review))).toList();
  // } 

  SliverList _buildReviewList(AsyncSnapshot<List<Review>> snapshot) {
    return SliverList( // Builder seems to crash, so I switched to a list
              delegate: SliverChildBuilderDelegate(
                (_, index) => _buildRow(snapshot.data[index]),
                childCount: snapshot.data.length,
              ),
            );
  }

  SliverAppBar _buildSearchBar() {
    return SliverAppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              pinned: true,
              backgroundColor: Colors.white,
              flexibleSpace: _buildSearchTextField(),
              actions: [_buildSortButton()],
            );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
              elevation: 0,
              floating: true,
              title: Text(Provider.of<InstagramRepository>(context,listen:false).igUsername + '\'s reviews'),
              toolbarHeight: 48,
              backgroundColor: Constants.myPurple,
              actions: [_buildRefreshButton()],
            );
  }

  Widget _buildRow(Review review) {
    return Card(
      elevation: 0,
      child: Link(
        uri: Uri.parse(review.permalink),
        target: LinkTarget.self,
        builder: (_, FollowLink followLink) => ListTile(
          leading: CircleAvatar(
            minRadius: 25, maxRadius: 25,
            backgroundColor: Colors.grey,
            backgroundImage: NetworkImage(review.mediaUrl),
          ),
          title: Text(review.restaurantName, style: TextStyle(fontSize: 18.0),),
          subtitle: Text(review.location),
          trailing: IconTheme(
            data: IconThemeData(color: Colors.amber[500], size: 25),
            child: StarDisplay(value: review.stars)
          ),
          onTap: followLink,
        ),
      ),
    );
  }

  Widget _buildSearchTextField() {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 70),
      child: Center(
        child: TextField(
          focusNode: widget.searchBoxFocusNode,
          controller: widget.textController,
          textInputAction: TextInputAction.search,
          onChanged: (text) => widget.updateCurrentReviews(text),
          onSubmitted: (text) {
            if(text.isNotEmpty) {
              widget.tabController.animateTo(1);
              widget.searchBoxFocusNode.unfocus();
            }
          },
          decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              suffixIcon: (widget.textController.text.length > 0) ? IconButton(
                color:  Colors.black,
                focusColor: Colors.transparent, hoverColor: Colors.transparent, highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onPressed: () {
                  widget.reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).allReviews);
                  Provider.of<InstagramRepository>(context,listen:false).showingAll = true;
                  Provider.of<InstagramRepository>(context,listen:false).madeChange();
                  Provider.of<InstagramRepository>(context,listen:false).currNumStars = 
                    Provider.of<InstagramRepository>(context,listen:false).allNumStars;
                  widget.textController.clear();
                }, 
                icon: Icon(Icons.clear, size: 17, color: Colors.grey,),
              ) : null,
              hintText: 'Search',
              contentPadding: EdgeInsets.only(top: 14),
              focusedBorder: InputBorder.none,
              border: InputBorder.none,
          ),),));
  }

  Label _currentSortLabel = sortLabels[0];
  Widget _buildSortButton() {
    return Container(
      padding: EdgeInsets.only(right: 14),
      child: PopupMenuButton(
        offset: Offset(0,55),
        tooltip: 'Sort',
        icon: Icon(Icons.sort, size: 27, color: Colors.grey),
        itemBuilder: (_) => List.generate(sortLabels.length, (index) {
          return CheckedPopupMenuItem(
              checked: (_currentSortLabel == sortLabels[index]),
              value: sortLabels[index],
              child: Text(sortLabels[index].text),
            );
        }),
        onSelected: (sortLabel) { 
          sortLabel.mySort(Provider.of<InstagramRepository>(context,listen:false).currentReviews);
          widget.reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).currentReviews);
          _currentSortLabel = sortLabel;
        },));
  }

  Widget _buildRefreshButton() {
    return IconButton(
      padding: EdgeInsets.only(right: 23),
      icon: const Icon(Icons.refresh),
      tooltip: 'Reload',
      onPressed: () {
          Provider.of<InstagramRepository>(context,listen:false).getReviews(); // Get latest data from IG
          widget.reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).allReviews); // Get latest data from IG
          widget.textController.clear();
          Provider.of<InstagramRepository>(context,listen:false).showingAll = true;
      });
  }

  @override
  void dispose() {
    widget.reviewController.close(); // Not sure if needed
    widget.textController.dispose();
    super.dispose();
  }
}