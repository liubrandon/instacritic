
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gradient_colors/flutter_gradient_colors.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:url_launcher/url_launcher.dart';
import 'instagram_repository.dart';
import 'star_display.dart';
import 'review.dart';
import 'label.dart';

class ListScreen extends StatefulWidget {
  static final route = '/list';
  const ListScreen({this.scrollController, this.textController, this.searchBoxFocusNode});
  final ScrollController scrollController;
  final TextEditingController textController;
  final FocusNode searchBoxFocusNode;
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool runOnce = true;
  StreamController<List<Review>> _reviewController = BehaviorSubject(); // ignore: close_sinks  

  @override
  Widget build(BuildContext context) {
    print('Rebuilt list screen');
    super.build(context);
    if(!Provider.of<InstagramRepository>(context,listen: true).ready) {
      return Center(child: CircularProgressIndicator());
    }
    if(runOnce) { // This is the initial building of the list
      _reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).allReviews);
      runOnce = false;
    }
    return StreamBuilder( // Get the reviews as a stream so if you search or sort it updates again
            stream: _reviewController.stream,
            builder: (BuildContext buildContext, AsyncSnapshot<List<Review>> snapshot) {
              if(snapshot == null || snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              else {
                Provider.of<InstagramRepository>(context,listen:false).currentReviews = snapshot.data;
                List<Widget> slivs = [
                  _buildAppBar(),
                  _buildSearchBar(),
                  _buildSliverPadding(height: 4)
                ];
                slivs.addAll(_getSliverList(snapshot));
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

  List<Widget> _getSliverList(AsyncSnapshot<List<Review>> snapshot) {
    return snapshot.data.map((review) => SliverToBoxAdapter(child: _buildRow(review))).toList();
  } 

  // SliverList _buildReviewList(AsyncSnapshot<List<Review>> snapshot) {
  //   return SliverList( // Builder seems to crash, so I switched to a list
  //             delegate: SliverChildBuilderDelegate(
  //               (context, index) => _buildRow(snapshot.data[index]),
  //               childCount: snapshot.data.length,
  //             ),
  //           );
  // }

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
              flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: GradientColors.purplePink,
              ))),
              actions: [_buildRefreshButton()],
            );
  }

  Widget _buildRow(Review review) {
    return Card(
      elevation: 0,
      child: ListTile(
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
        onTap: () => _launchUniversalLinkIos(review.permalink),
      ),
    );
  }

  Future<void> _launchUniversalLinkIos(String url) async {
    if (await canLaunch(url)) {
      final bool nativeAppLaunchSucceeded = await launch(
        url,
        forceSafariVC: false,
        universalLinksOnly: true,
      );
      print('universal link failed');
      if (!nativeAppLaunchSucceeded) {
        await launch(
          url,
          forceSafariVC: true,
        );
      }
    }
  }

  Widget _buildSearchTextField() {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 70),
      child: Center(
        child: TextField(
          focusNode: widget.searchBoxFocusNode,
          controller: widget.textController,
          onChanged: (text) => _updateCurrentReviews(text),
          decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              suffixIcon: (widget.textController.text.length > 0) ? IconButton(
                color:  Colors.black,
                focusColor: Colors.transparent, hoverColor: Colors.transparent, highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onPressed: () {
                  _reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).allReviews);
                  Provider.of<InstagramRepository>(context,listen:false).showingAll = true;
                  Provider.of<InstagramRepository>(context,listen:false).madeChange();
                  widget.textController.clear();
                }, 
                icon: Icon(Icons.clear, size: 17, color: Colors.grey,),
              ) : null,
              hintText: 'Search',
              contentPadding: EdgeInsets.only(top: 14),
              focusedBorder: InputBorder.none,
              border: InputBorder.none,
          ),),),);
  }

  // https://medium.com/level-up-programming/flutter-stream-tutorial-asynchronous-dart-programming-991e6cf97c5a
  void _updateCurrentReviews(String searchQuery) {
    Provider.of<InstagramRepository>(context,listen:false).currentReviews = [];
    if(searchQuery.isEmpty) {
      _reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).allReviews);
      Provider.of<InstagramRepository>(context,listen:false).showingAll = true;
      Provider.of<InstagramRepository>(context,listen:false).madeChange();
      return;
    }
    Provider.of<InstagramRepository>(context,listen:false).allReviews.forEach((review) {
      if (_reviewMatchesSearchQuery(review, searchQuery)) {
        Provider.of<InstagramRepository>(context,listen:false).currentReviews.add(review);
      }
    });
    _reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).currentReviews);
    Provider.of<InstagramRepository>(context,listen:false).showingAll = false;
    Provider.of<InstagramRepository>(context,listen:false).madeChange();
  }

  bool _reviewMatchesSearchQuery(Review review, String searchQuery) {
    Map<String, String> terms = {'name': review.restaurantName, 'place': review.location, 'query': searchQuery};
    terms.forEach((key, value) => terms[key] = value.toLowerCase().replaceAll(RegExp(r"[^\w]"), ''));
    return terms['name'].contains(terms['query']) ||
        terms['place'].toLowerCase().contains(terms['query']);
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
          _reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).currentReviews);
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
          _reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).allReviews); // Get latest data from IG
          widget.textController.clear();
          Provider.of<InstagramRepository>(context,listen:false).showingAll = true;
      });
  }

  @override
  void dispose() {
    _reviewController.close(); // Not sure if needed
    widget.textController.dispose();
    super.dispose();
  }
}