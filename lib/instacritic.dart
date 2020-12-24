
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gradient_colors/flutter_gradient_colors.dart';
import 'package:provider/provider.dart';
import 'info_screen.dart';
import 'instagram_repository.dart';
import 'map_screen.dart';
import 'list_screen.dart';

const List<TabItem> _homeTabs = [
  TabItem(icon: Icons.list),
  TabItem(icon: Icons.map),
];

class Instacritic extends StatefulWidget {
  const Instacritic(this.initialPageIndex);
  final int initialPageIndex;
  static final route = '/';
  @override
  _InstacriticState createState() => _InstacriticState();
}

class _InstacriticState extends State<Instacritic> with SingleTickerProviderStateMixin {
  // Used by ListScreen and HideFabOnScrollScaffold
  TextEditingController _textController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  FocusNode _searchBoxFocusNode = FocusNode();
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _homeTabs.length, initialIndex: widget.initialPageIndex);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _searchBoxFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: HideFabOnScrollScaffold(
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [ListScreen(scrollController: _scrollController, textController:  _textController, searchBoxFocusNode: _searchBoxFocusNode),MapScreen()],
        ),
        floatingActionButton: _buildReviewCountFAB(),
        scrollController: _scrollController,
        textController: _textController,
        focusNode: _searchBoxFocusNode,
        tabController: _tabController,
      ),
    );
  }

  SizedBox _buildReviewCountFAB() {
    return SizedBox(
        width: 120,
        height: 35,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: GradientColors.purplePink,
          )),
          child: FloatingActionButton.extended(
            onPressed: null,
            backgroundColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            label: Text(_getNumReviewsString(), style: TextStyle(color: Colors.white, fontSize: 15, letterSpacing: .5)),
          ),
        ),
      );
  }
  String _getNumReviewsString() {
    final int _numReviews = Provider.of<InstagramRepository>(context).getNumReviewsShown();
    if(_numReviews == 1)
      return '$_numReviews Review';
    return '$_numReviews Reviews';
  }
}

class HideFabOnScrollScaffold extends StatefulWidget {
  const HideFabOnScrollScaffold({
    Key key,
    this.body,
    this.floatingActionButton,
    this.scrollController,
    this.textController,
    this.focusNode,
    this.tabController,
  }) : super(key: key);

  final Widget body;
  final Widget floatingActionButton;
  final ScrollController scrollController;
  final TextEditingController textController;
  final FocusNode focusNode;
  final TabController tabController;

  @override
  State<StatefulWidget> createState() => HideFabOnScrollScaffoldState();
}

class HideFabOnScrollScaffoldState extends State<HideFabOnScrollScaffold> {
  bool _fabVisible = true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_updateFabVisible);
    widget.focusNode.addListener(_updateFabVisible);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateFabVisible);
    widget.focusNode.removeListener(_updateFabVisible);
    super.dispose();
  }

  void _updateFabVisible() {
    final newFabVisible = (widget.scrollController.position.userScrollDirection == ScrollDirection.forward
                          || widget.focusNode.hasFocus); // || widget.textController.text.isNotEmpty);
    if (_fabVisible != newFabVisible) {
      setState(() {
        _fabVisible = newFabVisible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.body,
      floatingActionButton: _fabVisible ? widget.floatingActionButton : null,
      drawer: Container(
        width: 250,
        child: Drawer(
          child: InfoScreen(),
        ),
      ),
      drawerEnableOpenDragGesture: false,
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
    );
  }
  Widget _buildBottomBar() {
    return ConvexAppBar(
      controller: widget.tabController,
      items: _homeTabs,
      elevation: 0,
      style: TabStyle.reactCircle,
      gradient: LinearGradient(colors: GradientColors.purplePink),
      backgroundColor: Color(0xFFcc2b5e),
      color: Colors.white,
      height: 45,
      onTap: (int i) {
        if(i == 1) { // Map screen
          setState(() {
            _fabVisible = true;
            widget.scrollController.removeListener(_updateFabVisible);
          });
        } else if(i == 0) {
          widget.scrollController.addListener(_updateFabVisible);
        }
      },
    );
  }
}