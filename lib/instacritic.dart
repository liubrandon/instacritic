
import 'dart:async';

import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gradient_colors/flutter_gradient_colors.dart';
import 'package:instacritic/constants.dart';
import 'package:instacritic/review.dart';
import 'package:instacritic/star_display.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
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
  // ignore: close_sinks
  StreamController<List<Review>> _reviewController = BehaviorSubject(); 
  List<bool> filterBoxChecked = [true,true,true,true,true];
  List<bool> filterBoxCheckedBackup;
  bool pressedApply = false;
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
          children: [ListScreen(_scrollController, _textController, _searchBoxFocusNode, _tabController, _reviewController, _updateCurrentReviews),MapScreen(_tabController,_textController,_searchBoxFocusNode)],
        ),
        floatingActionButton: _buildReviewCountFAB(),
        scrollController: _scrollController,
        textController: _textController,
        focusNode: _searchBoxFocusNode,
        tabController: _tabController,
      );
  }

  Widget _buildReviewCountFAB() {
    pressedApply = false;
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
                Future<void> f = _showFilterModal();
                f.then((_) {
                  if(!pressedApply) {
                    filterBoxChecked = List.from(filterBoxCheckedBackup);
                  }
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
    filterBoxCheckedBackup = List.from(filterBoxChecked);
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
                            _buildFilterLabel(),
                            for(int i = 0; i < 5; i++)
                              _buildCheckboxListTile(i, state),
                            _buildApplyFiltersButton(constraint, state)
                          ],
                          ),
                      );
                    },
                  );
                }
              );
            });
  }

  CheckboxListTile _buildCheckboxListTile(int i, StateSetter state) {
    int currNum = Provider.of<InstagramRepository>(context).currNumReviewsWithStars[i];
    return CheckboxListTile(
      checkColor: Colors.green,
      activeColor: Colors.transparent,
      title: Padding(padding: EdgeInsets.only(left: 0), child:StarDisplay(value:i)),
      secondary: SizedBox(
        width: 20,
        height: 20,
        child: Text(currNum.toString(), textAlign: TextAlign.right)
      ),// + ' review' + ((currNum != 1) ? 's' : ''))),
      controlAffinity: ListTileControlAffinity.trailing,
      onChanged: (bool value) { 
        state(() {
          filterBoxChecked[i] = value;
        });
      },
      value: filterBoxChecked[i],
    );
  }

  Padding _buildFilterLabel() {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 20, bottom: 10),
      child: Text('Filtering ${_getNumReviewsString().split(' ')[0]} reviews', style: TextStyle(fontSize: 20, letterSpacing: .5)),
    );
  }

  Padding _buildApplyFiltersButton(BoxConstraints constraint, StateSetter state) {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 15),
      child: Center(
        child:  TextButton(
          style: TextButton.styleFrom(
            minimumSize: Size(constraint.minWidth-30, 50),
            backgroundColor: Constants.myPurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Text('Apply', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: .5, fontWeight: FontWeight.w600)),
          onPressed: () {
            state(() {
              pressedApply = true;
              _updateCurrentReviews(_textController.text);
              Navigator.of(context).pop();
            });
          },
      )),
    );
  }

  String _getNumReviewsString() {
    int _numReviews = Provider.of<InstagramRepository>(context).numReviewsShown;
    if(_numReviews == 1)
      return '$_numReviews Review';
    return '$_numReviews Reviews';
  }

  // https://medium.com/level-up-programming/flutter-stream-tutorial-asynchronous-dart-programming-991e6cf97c5a
  void _updateCurrentReviews(String searchQuery) {
    Provider.of<InstagramRepository>(context,listen:false).currentReviews = [];
    Provider.of<InstagramRepository>(context,listen:false).currNumReviewsWithStars = [0,0,0,0,0];
    Provider.of<InstagramRepository>(context,listen:false).allReviews.forEach((review) {
      if(_reviewMatchesSearchQuery(review, searchQuery)) {
        Provider.of<InstagramRepository>(context,listen:false).currNumReviewsWithStars[review.stars]++;
        if (filterBoxChecked[review.stars])
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
    if(terms['query'].isEmpty) return true;
    return terms['name'].contains(terms['query']) ||
        terms['place'].toLowerCase().contains(terms['query']);
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
    // print(widget.scrollController.position.userScrollDirection == ScrollDirection.forward);
    final newFabVisible = (widget.scrollController.position.userScrollDirection == ScrollDirection.forward
                          || widget.focusNode.hasFocus || widget.tabController.index == 1);
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
          child: InfoScreen(widget.textController),
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


// Widget _buildChart(StateSetter state) {
//   return Expanded(
//         child: Container(
//           height: 120,
//           child: Center(
//             // aspectRatio: 1,
//             child: PieChart(
//               PieChartData(
//                   pieTouchData: PieTouchData(touchCallback: (pieTouchResponse) {
//                     state(() {
//                       if (pieTouchResponse.touchInput is FlLongPressEnd ||
//                           pieTouchResponse.touchInput is FlPanEnd) {
//                         touchedIndex = -1;
//                       } else {
//                         touchedIndex = pieTouchResponse.touchedSectionIndex;
//                       }
//                     });
//                   }),
//                   borderData: FlBorderData(
//                     show: false,
//                   ),
//                   sectionsSpace: 0,
//                   centerSpaceRadius: 20,
//                   sections: showingSections()),
//             ),
//           ),
//         ),
//       );
// }

// List<PieChartSectionData> showingSections() {
//     return List.generate(5, (i) {
//       final isTouched = i == touchedIndex;
//       final double fontSize = isTouched ? 16 : 14;
//       final double radius = isTouched ? 60 : 50;
//       final double widgetSize = isTouched ? 55 : 40;

//       switch (i) {
//         case 0:
//           return PieChartSectionData(
//             color: const Color(0xff0293ee),
//             value: 40,
//             title: '36%',
//             radius: radius,
//             titleStyle: TextStyle(
//                 fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
//             badgePositionPercentageOffset: .98,
//           );
//         case 1:
//           return PieChartSectionData(
//             color: const Color(0xfff8b250),
//             value: 30,
//             title: '30%',
//             radius: radius,
//             titleStyle: TextStyle(
//                 fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
//             badgePositionPercentageOffset: .98,
//           );
//         case 2:
//           return PieChartSectionData(
//             color: const Color(0xff845bef),
//             value: 16,
//             title: '16%',
//             radius: radius,
//             titleStyle: TextStyle(
//                 fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
//             badgePositionPercentageOffset: .98,
//           );
//         case 3:
//           return PieChartSectionData(
//             color: const Color(0xff13d38e),
//             value: 15,
//             title: '15%',
//             radius: radius,
//             titleStyle: TextStyle(
//                 fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
//             badgePositionPercentageOffset: .98,
//           );
//         case 4:
//           return PieChartSectionData(
//             color: Colors.red,
//             value: 4,
//             title: '4%',
//             radius: radius,
//             titleStyle: TextStyle(
//                 fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
//             badgePositionPercentageOffset: .98,
//           );
//         default:
//           return null;
//       }
//     });
//   }