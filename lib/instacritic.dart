
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gradient_colors/flutter_gradient_colors.dart';
import 'package:instacritic/constants.dart';
import 'package:instacritic/star_display.dart';
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
  @override
  _InstacriticState createState() => _InstacriticState();
}

class _InstacriticState extends State<Instacritic> with SingleTickerProviderStateMixin {
  // Used by ListScreen and HideFabOnScrollScaffold
  TextEditingController _textController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  FocusNode _searchBoxFocusNode = FocusNode();
  TabController _tabController;
  List<bool> filterBoxChecked = [true,true,true,true,true];
  double _fabOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _homeTabs.length, initialIndex: 0);
  }

  @override
  void dispose() {
    // _textController.dispose();
    _scrollController.dispose();
    _searchBoxFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HideFabOnScrollScaffold(
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [ListScreen(_scrollController, _textController, _searchBoxFocusNode),MapScreen()],
        ),
        floatingActionButton: _buildReviewCountFAB(),
        scrollController: _scrollController,
        textController: _textController,
        focusNode: _searchBoxFocusNode,
        tabController: _tabController,
      );
  }

  Widget _buildReviewCountFAB() {
    return Padding(
        padding: EdgeInsets.only(bottom: _fabOffset),
        child: SizedBox(
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
              onPressed: () {
                Future<void> f;
                setState(() {
                  _fabOffset = 280;
                  f = _showFilterModal();
                });
                f.then((void _) {
                  setState(() {
                    _fabOffset = 0;
                  });
                });
              },
              backgroundColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              label: Text(_getNumReviewsString(), style: TextStyle(color: Colors.white, fontSize: 15, letterSpacing: .5)),
            ),
          ),
        ),
    );
  }

  Future<void> _showFilterModal() {
    return showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0)
            ),
            builder: (context) {
              return StatefulBuilder(
                  builder: (BuildContext context, StateSetter state) {
                    return Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.transparent),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top:25, left: 15, bottom: 15),
                            child: Text('Filter', style: TextStyle(fontSize: 24,), textAlign: TextAlign.left,),
                          ),
                          CheckboxListTile(
                            checkColor: Colors.green,
                            activeColor: Colors.transparent,
                            secondary: StarDisplay(value:0),
                            title: Text(''),
                            controlAffinity: ListTileControlAffinity.trailing,
                            onChanged: (bool value) { 
                              state(() {
                                filterBoxChecked[0] = value;
                              });
                            },
                            value: filterBoxChecked[0],
                          ),
                          CheckboxListTile(
                            checkColor: Colors.green,
                            activeColor: Colors.transparent,
                            secondary: StarDisplay(value:1),
                            title: Text(''),
                            controlAffinity: ListTileControlAffinity.trailing,
                            onChanged: (bool value) { 
                              state(() {
                                filterBoxChecked[1] = value;
                              });
                            },
                            value: filterBoxChecked[1],
                          ),
                          CheckboxListTile(
                            checkColor: Colors.green,
                            activeColor: Colors.transparent,
                            secondary: StarDisplay(value:2),
                            title: Text(''),
                            controlAffinity: ListTileControlAffinity.trailing,
                            onChanged: (bool value) { 
                              state(() {
                                filterBoxChecked[2] = value;
                              });
                            },
                            value: filterBoxChecked[2],
                          ),
                          CheckboxListTile(
                            checkColor: Colors.green,
                            activeColor: Colors.transparent,
                            secondary: StarDisplay(value:3),
                            title: Text(''),
                            controlAffinity: ListTileControlAffinity.trailing,
                            onChanged: (bool value) { 
                              state(() {
                                filterBoxChecked[3] = value;
                              });
                            },
                            value: filterBoxChecked[3],
                          ),
                          CheckboxListTile(
                            checkColor: Colors.green,
                            activeColor: Colors.transparent,
                            secondary: StarDisplay(value:4),
                            title: Text(''),
                            controlAffinity: ListTileControlAffinity.trailing,
                            onChanged: (bool value) { 
                              state(() {
                                filterBoxChecked[4] = value;
                              });
                            },
                            value: filterBoxChecked[4],
                          ),
                          ButtonBar(
                            children: [],
                          ),
                        ],
                        ),
                    );
                  },
                );
              
            });
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
  bool _appDrawerSwipingEnabled = true;

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
      drawerEnableOpenDragGesture: _appDrawerSwipingEnabled,
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
      backgroundColor: Constants.myPurple,
      color: Colors.white,
      height: 48,
      onTap: (int i) {
        if(i == 1) { // Map screen
          setState(() {
            _fabVisible = true;
            widget.scrollController.removeListener(_updateFabVisible);
            _appDrawerSwipingEnabled = false;
          });
        } else if(i == 0) {
          setState(() {
            widget.scrollController.addListener(_updateFabVisible);
            _appDrawerSwipingEnabled = true;
          });
        }
      },
    );
  }
}