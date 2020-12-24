
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
  TabItem(icon: Icons.list,),
  TabItem(icon: Icons.map,),
];

class Instacritic extends StatefulWidget {
  @override
  _InstacriticState createState() => _InstacriticState();
}

class _InstacriticState extends State<Instacritic> {
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _homeTabs.length,
      initialIndex: 0,
      child: HideFabOnScrollScaffold(
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [ListScreen(scrollController),MapScreen()],
        ),
        floatingActionButton: _buildReviewCountFAB(),
        controller: scrollController,
      ),
    );
  }

  SizedBox _buildReviewCountFAB() {
    return SizedBox(
        width: 110,
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
            label: Text(_getNumReviewsString(), style: TextStyle(fontSize: 12)),
          ),
        ),
      );
  }
  String _getNumReviewsString() {
    final int _numReviews = (Provider.of<InstagramRepository>(context).showingAll) ? Provider.of<InstagramRepository>(context).allReviews.length : Provider.of<InstagramRepository>(context).currentReviews.length;
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
    this.controller,
  }) : super(key: key);

  final Widget body;
  final Widget floatingActionButton;
  final ScrollController controller;

  @override
  State<StatefulWidget> createState() => HideFabOnScrollScaffoldState();
}

class HideFabOnScrollScaffoldState extends State<HideFabOnScrollScaffold> {
  bool _fabVisible = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateFabVisible);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateFabVisible);
    super.dispose();
  }

  void _updateFabVisible() {
    final newFabVisible = (widget.controller.position.userScrollDirection == ScrollDirection.forward);
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
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
    );
  }
  Widget _buildBottomBar() {
    return ConvexAppBar(
      items: _homeTabs,
      elevation: 0,
      style: TabStyle.reactCircle,
      gradient: LinearGradient(colors: GradientColors.purplePink),
      backgroundColor: Color(0xFFcc2b5e),
      color: Colors.white,
      height: 45,
    );
  }
}