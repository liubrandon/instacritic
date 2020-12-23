
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gradient_colors/flutter_gradient_colors.dart';
import 'package:provider/provider.dart';
import 'info_screen.dart';
import 'instagram_repository.dart';
import 'map_screen.dart';
import 'list_screen.dart';
class Instacritic extends StatefulWidget {
  @override
  _InstacriticState createState() => _InstacriticState();
}

class _InstacriticState extends State<Instacritic> {
  static const List<TabItem> _homeTabs = [
    TabItem(icon: Icons.list,),
    TabItem(icon: Icons.map,),
  ];

  // Used for showing the snackbar
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _homeTabs.length,
      initialIndex: 0,
      child: Scaffold(
        key: scaffoldKey,
        drawer: Container(
          width: 150,
          child: Drawer(
            child: InfoScreen(),
          ),
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [ListScreen(),MapScreen()],
        ),
        bottomNavigationBar: _buildBottomBar(),
        floatingActionButton: _buildReviewCountFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
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