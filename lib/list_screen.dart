
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:instacritic/constants.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'chart_screen.dart';
import 'instagram_repository.dart';
import 'star_display.dart';
import 'review.dart';
import 'sort_filter.dart';

class ListScreen extends StatefulWidget {
  final StreamController<List<Review>> reviewController; // ignore: close_sinks  
  final TabController tabController;
  final ScrollController scrollController;
  final TextEditingController textController;
  final FocusNode searchBoxFocusNode;
  final void Function(String) updateCurrentReviews;
  final void Function() openSortAndFilterModal;
  const ListScreen(this.scrollController, this.textController, this.searchBoxFocusNode, this.tabController, this.reviewController, this.updateCurrentReviews, this.openSortAndFilterModal);
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool runOnce = true;
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  // firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
  // firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref('/testsmall.jpg');
  // @override
  // void initState() {
  //   super.initState();
  // }

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
          return NestedScrollView(
            headerSliverBuilder: (context, bool innerBoxIsScrolled) {
              return [_buildAppBar(),_buildSearchBar()];
            },
            floatHeaderSlivers: true,
            body: CupertinoScrollbar(
              child: SmartRefresher(
                controller: _refreshController,
                header: ClassicHeader(
                  height: 50,
                  idleText: 'Pull down to refresh',
                  refreshingText: '',
                  completeText: '',
                ),
                child: CustomScrollView(
                  controller: widget.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  // cacheExtent: 10000.0, // https://github.com/flutter/flutter/issues/22314
                  slivers: [
                    _buildSliverPadding(height: 8),
                    _buildReviewList(snapshot),
                    _buildSliverPadding(height: 20)
                  ],
                ),
                onRefresh: () async {
                  await Provider.of<InstagramRepository>(context,listen:false).getReviews(); // Get latest data from IG
                  widget.reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).allReviews); // Get latest data from IG
                  widget.textController.clear();
                  _refreshController.refreshCompleted();
                },
                onLoading: () async => _refreshController.loadComplete(),
              ),
            ),
          );
        }
      }
    );
  }

  SliverToBoxAdapter _buildSliverPadding({double height}) => SliverToBoxAdapter(child: Container(height:height));

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
        // centerTitle: false,
        automaticallyImplyLeading: false,
        elevation: 5,
        pinned: true,
        // floating: false,
        backgroundColor: Colors.white,
        flexibleSpace: _buildSearchTextField(),
        leading: null,
        actions: [_buildSortAndFilterButton()],
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      elevation: 0,
      floating: true,
      pinned: true,
      centerTitle: true,
      title: Text(Provider.of<InstagramRepository>(context,listen:false).igUsername + '\'s reviews'),
      toolbarHeight: 48,
      backgroundColor: Constants.myPurple,
      actions: [_buildViewChartsButton()]
    );
  }

  Widget _buildRow(Review review) {
    return Column(
      children: [
        ListTile(
          tileColor: Colors.white,
          leading: InkWell(
              onTap: () => launch(review.permalink),
              child: FadeInImage.memoryNetwork(
                fit: BoxFit.fitWidth,
                height: 50.0, width: 50.0,
                placeholder: kTransparentImage,
                image: review.mediaUrl,
            ),
          ),
          title: Text(review.restaurantName, style: TextStyle(fontSize: 18.0),),
          subtitle: Text(review.location),
          trailing: IconTheme(
            data: IconThemeData(color: Colors.amber[500], size: 25),
            child: StarDisplay(value: review.stars)
          ),
          onTap: () async {
            widget.textController.value = TextEditingValue(text: review.restaurantName);
            widget.updateCurrentReviews(review.restaurantName);
            await Future.delayed(Duration(milliseconds: 80));
            widget.tabController.animateTo(1);
            // widget.searchBoxFocusNode.unfocus();
          },
        ),
        const SizedBox(height: 5),
      ]
    );
  }

  Widget _buildSearchTextField() {
    return Padding(
      padding: const EdgeInsets.only(left: 7, top: 4, right: 60),
      child: TextField(
          // autofocus: true,
          focusNode: widget.searchBoxFocusNode,
          controller: widget.textController,
          textInputAction: TextInputAction.search,
          onChanged: (text) {
            widget.updateCurrentReviews(text);
          },
          onSubmitted: (text) {
            if(text.isNotEmpty) {
              widget.tabController.animateTo(1);
            }
            widget.searchBoxFocusNode.unfocus();
          },
          decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              suffixIcon: (widget.textController.text.length > 0) ? IconButton(
                icon: Icon(Icons.clear, size: 17, color: Colors.grey),
                color:  Colors.black,
                focusColor: Colors.transparent, hoverColor: Colors.transparent, highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onPressed: () {
                  widget.textController.clear();
                  widget.reviewController.sink.add(Provider.of<InstagramRepository>(context,listen:false).allReviews);
                  Provider.of<InstagramRepository>(context,listen:false).showingAll = true;
                  Provider.of<InstagramRepository>(context,listen:false).currNumStars = 
                    List.from(Provider.of<InstagramRepository>(context,listen:false).allNumStars);
                  resetSortAndFilterOptions();
                  Provider.of<InstagramRepository>(context,listen:false).madeChange();
                }, 
              ) : null,
              hintText: 'Search',
              contentPadding: EdgeInsets.only(top: 14),
              focusedBorder: InputBorder.none,
              border: InputBorder.none,
          ),),);
  }

  Widget _buildSortAndFilterButton() {
    return Padding(
      padding: EdgeInsets.only(right: 10),
      child: IconButton(
        tooltip: 'Sort and filter',
        icon: Icon(FontAwesomeIcons.slidersH, size: 20, color: Colors.grey[600]),
        onPressed: () => widget.openSortAndFilterModal(),
      )
    );
  }

  Widget _buildViewChartsButton() {
    return IconButton(
        padding: EdgeInsets.only(right: 23),
        icon: const Icon(Icons.insert_chart_outlined),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context)=>ChartScreen(widget.textController)))
      );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
}