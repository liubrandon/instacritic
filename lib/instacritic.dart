
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:fl_chart/fl_chart.dart';
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
import 'indicator.dart';

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
          children: [ListScreen(_scrollController, _textController, _searchBoxFocusNode, _tabController),MapScreen(_tabController,_textController,_searchBoxFocusNode)],
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
              onPressed: _showFilterModal,
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
  int touchedIndex;
  Future<void> _showFilterModal() {
    return showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            builder: (context) {
              return LayoutBuilder(
                builder: (context, constraint) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter state) {
                      return Theme(
                      data: ThemeData(unselectedWidgetColor: Colors.transparent),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(top:22, left: 23, bottom: 10),
                              child: Text('Filter', style: TextStyle(fontSize: 20, letterSpacing: .5)),
                            ),
                            _buildChart(state),
                            CheckboxListTile(
                              
                              checkColor: Colors.green,
                              activeColor: Colors.transparent,
                              title: Padding(padding: EdgeInsets.only(left: 0), child:StarDisplay(value:0)),
                              secondary: Indicator(
                                color: Color(0xff0293ee),
                                text: 'First',
                                isSquare: false,
                              ),
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
                              title: Padding(padding: EdgeInsets.only(left: 0), child:StarDisplay(value:1)),
                              secondary: Indicator(
                                color: Color(0xfff8b250),
                                text: 'Second',
                                isSquare: false,
                              ),
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
                              title: Padding(padding: EdgeInsets.only(left: 0), child:StarDisplay(value:2)),
                              secondary: Indicator(
                                color: Color(0xff845bef),
                                text: 'Third',
                                isSquare: false,
                              ),
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
                              title: Padding(padding: EdgeInsets.only(left: 0), child:StarDisplay(value:3)),
                              secondary: Indicator(
                                color: Color(0xff13d38e),
                                text: 'Fourth',
                                isSquare: false,
                              ),
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
                              title: Padding(padding: EdgeInsets.only(left: 0), child:StarDisplay(value:4)),
                              secondary: Indicator(
                                color: Colors.red,
                                text: 'Fourth',
                                isSquare: false,
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              onChanged: (bool value) { 
                                state(() {
                                  filterBoxChecked[4] = value;
                                });
                              },
                              value: filterBoxChecked[4],
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child:  TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: Size(constraint.minWidth-30, 50),
                                    backgroundColor: Constants.myPurple,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  ),
                                  child: Text('Apply', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: .5, fontWeight: FontWeight.w600)),
                                  onPressed: () {},
                              )),
                            )
                          ],
                          ),
                      );
                    },
                  );
                }
              );
            });
  }

  Widget _buildChart(StateSetter state) {
    return Expanded(
          child: Container(
            height: 120,
            child: Center(
              // aspectRatio: 1,
              child: PieChart(
                PieChartData(
                    pieTouchData: PieTouchData(touchCallback: (pieTouchResponse) {
                      state(() {
                        if (pieTouchResponse.touchInput is FlLongPressEnd ||
                            pieTouchResponse.touchInput is FlPanEnd) {
                          touchedIndex = -1;
                        } else {
                          touchedIndex = pieTouchResponse.touchedSectionIndex;
                        }
                      });
                    }),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    sectionsSpace: 0,
                    centerSpaceRadius: 20,
                    sections: showingSections()),
              ),
            ),
          ),
        );
  }

  List<PieChartSectionData> showingSections() {
      return List.generate(5, (i) {
        final isTouched = i == touchedIndex;
        final double fontSize = isTouched ? 16 : 14;
        final double radius = isTouched ? 60 : 50;
        final double widgetSize = isTouched ? 55 : 40;

        switch (i) {
          case 0:
            return PieChartSectionData(
              color: const Color(0xff0293ee),
              value: 40,
              title: '36%',
              radius: radius,
              titleStyle: TextStyle(
                  fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
              badgePositionPercentageOffset: .98,
            );
          case 1:
            return PieChartSectionData(
              color: const Color(0xfff8b250),
              value: 30,
              title: '30%',
              radius: radius,
              titleStyle: TextStyle(
                  fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
              badgePositionPercentageOffset: .98,
            );
          case 2:
            return PieChartSectionData(
              color: const Color(0xff845bef),
              value: 16,
              title: '16%',
              radius: radius,
              titleStyle: TextStyle(
                  fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
              badgePositionPercentageOffset: .98,
            );
          case 3:
            return PieChartSectionData(
              color: const Color(0xff13d38e),
              value: 15,
              title: '15%',
              radius: radius,
              titleStyle: TextStyle(
                  fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
              badgePositionPercentageOffset: .98,
            );
          case 4:
            return PieChartSectionData(
              color: Colors.red,
              value: 4,
              title: '4%',
              radius: radius,
              titleStyle: TextStyle(
                  fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
              badgePositionPercentageOffset: .98,
            );
          default:
            return null;
        }
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
            _fabVisible = true;
            widget.scrollController.addListener(_updateFabVisible);
            _appDrawerSwipingEnabled = true;
          });
        }
      },
    );
  }
}

