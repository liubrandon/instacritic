
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gradient_colors/flutter_gradient_colors.dart';
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
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            ListScreen(),
            MapScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
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
      height: 42,
    );
  }
}