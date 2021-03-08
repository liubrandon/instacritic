import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gradient_colors/flutter_gradient_colors.dart';
import 'package:instacritic/constants.dart';
import 'package:instacritic/sort_filter.dart';
import 'package:instacritic/review.dart';
import 'package:instacritic/star_display.dart';
import 'package:instacritic/tag.dart';
import 'package:location/location.dart';
import "package:flutter/foundation.dart" show kIsWeb;
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'app_drawer.dart';
import 'chip_list.dart';
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
  InstagramRepository igRepository;
  // Used by ListScreen and HideFabOnScrollScaffold
  TextEditingController _textController;
  ScrollController _scrollController;
  FocusNode _searchBoxFocusNode;
  StreamController<List<Review>> _reviewController;
  TabController _tabController;
  List<bool> filterBoxCheckedBackup;
  int sortSelectionBackup;
  bool pressedApply = false;
  LocationData _locationData;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _searchBoxFocusNode = FocusNode();
    _reviewController = BehaviorSubject(); // ignore: close_sinks
    _tabController = TabController(vsync: this, length: _homeTabs.length, initialIndex: 0);
  }

  Future<void> getLocation() async {
    Location location = Location();
    if(!kIsWeb) {
        bool _serviceEnabled;
        PermissionStatus _permissionGranted;
        _serviceEnabled = await location.serviceEnabled();
        if(!_serviceEnabled) {
          _serviceEnabled = await location.requestService();
          if(!_serviceEnabled) return;
        }
        _permissionGranted = await location.hasPermission();
        if(_permissionGranted == PermissionStatus.denied) {
          _permissionGranted = await location.requestPermission();
          if(_permissionGranted != PermissionStatus.granted) return;
        }
    }
    _locationData = await location.getLocation();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _searchBoxFocusNode.dispose();
    _reviewController.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    igRepository = Provider.of<InstagramRepository>(context,listen:false);
    return AbsorbPointer(
      absorbing: !Provider.of<InstagramRepository>(context).ready, // until first load don't respond to touch
      child: HideFabOnScrollScaffold(
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ListScreen(_scrollController, _textController, _searchBoxFocusNode, _tabController, _reviewController,
                        _updateCurrentReviews, _openSortAndFilterModal, _clearSearchText),
            MapScreen(_tabController,_textController,_searchBoxFocusNode,
                      _updateCurrentReviews,_clearSearchText)
          ],
        ),
        floatingActionButton: _buildReviewCountFAB(),
        scrollController: _scrollController,
        textController: _textController,
        focusNode: _searchBoxFocusNode,
        tabController: _tabController,
      ),
    );
  }

  Widget _buildReviewCountFAB() {
    pressedApply = false;
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
              heroTag: 'filterButton',
              onPressed: () => _openSortAndFilterModal(),
              backgroundColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              label: Text(_getNumReviewsString(), style: TextStyle(color: Colors.white, fontSize: 15, letterSpacing: .5)),
            ),
          ),
    );
  }

  void _openSortAndFilterModal() {
    Future<void> f = _showFilterModal();
    f.then((_) {
      if(!pressedApply) {// If you didn't press apply, don't save changes to filter check boxes
        filterBoxChecked = List.from(filterBoxCheckedBackup);
        sortSelection = sortSelectionBackup;
      }
    });
  }

  Future<void> _showFilterModal() {
    filterBoxCheckedBackup = List.from(filterBoxChecked);
    sortSelectionBackup = sortSelection;
    return showModalBottomSheet(
      isScrollControlled: true,
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
                  data: ThemeData(unselectedWidgetColor: Colors.transparent,),
                  child: PointerInterceptor(
                    child: Wrap(
                        children: <Widget>[
                          _buildFilterSortHeader(),
                          _buildRatingLabel(),
                          _buildCheckboxListTile(5, state),
                          for(int i = 0; i < 5; i++)
                            _buildCheckboxListTile(i, state),
                          _buildSortLabel(),
                          _buildSortButtons(state),
                          _buildApplyFiltersButton(constraint, state),
                        ],
                      ),
                  ),
                );
              },
            );
          }
        );
      });
  }
  
  Widget _buildSortButtons(StateSetter state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: ToggleButtons(
          borderRadius: BorderRadius.circular(5.0),
          isSelected: [
            for(int i = 0; i < sortLabels.length; i++)
              i == sortSelection // Only sortSelected will be true and selected
          ],
          children: [
            for(int i = 0; i < sortLabels.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(sortLabels[i].text),
              )
          ],
          onPressed: (int index) {
            state(() => sortSelection = index);
          },
        ),
      ),
    );
  }

  Widget _buildCheckboxListTile(int i, StateSetter state) {
    int currNum = Provider.of<InstagramRepository>(context).currNumStars[i];
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5),
      child: ListTile(
        dense: true,
        title: Padding(padding: EdgeInsets.only(left: 0), child:StarDisplay(value:i)),
        trailing: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: currNum == 0 || !filterBoxChecked[i] ? GradientColors.grey : GradientColors.purplePink,
          )),
          width: 25,
          height: 25,
          child: Center(child: Text(currNum.toString(), textAlign: TextAlign.justify, style: TextStyle(color: Colors.white)))
        ),
        enabled: currNum != 0, // disable if there are 0 reviews
        onTap: () { 
          state(() => filterBoxChecked[i] = !filterBoxChecked[i]);
        },
      ),
    );
  }

  Widget _buildFilterSortHeader() {
    int numReviews = 0;
    Provider.of<InstagramRepository>(context).currNumStars.forEach((element) => numReviews+=element);
    String numReviewsText = 'All $numReviews ratings';
    if(processStringForSearch(_textController.text).isNotEmpty)
      numReviewsText = '$numReviews ratings matching \"${_textController.text}\"';
    return Column(
      children: [
        Stack(
          children: [
            Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: Text('Sort and Filter', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600))),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
        Text(numReviewsText, style: TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildRatingLabel() {
    return Padding(
      padding: EdgeInsets.only(left: 20, top: 14),
      child: Text('Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSortLabel() {
    return Padding(
      padding: EdgeInsets.only(left: 20, bottom: 10, top: 20),
      child: Text('Sort by', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Padding _buildApplyFiltersButton(BoxConstraints constraint, StateSetter state) {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 20),
      child: Center(
        child:  TextButton(
          style: TextButton.styleFrom(
            minimumSize: Size(constraint.minWidth-30, 50),
            backgroundColor: Constants.myPurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Text('Apply', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: .5, fontWeight: FontWeight.w600)),
          onPressed: () async {
            bool sortingByDistance = sortSelection == 4;
            if(sortingByDistance && !igRepository.calculatedDistances) {
              await igRepository.addLatLngToAllReviews();
              try {
                await getLocation();
              } catch(_) { 
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Location permission required to sort by distance.'),
                  )
                );
                return;
              }
              igRepository.calculateDistances(_locationData.latitude, _locationData.longitude);
              igRepository.calculatedDistances = true;
            }
            state(() {
              pressedApply = true; // Used in the modal closed callback to not apply checkbox updates if you swiped out/cancelled
              bool needToSort = sortSelection != sortSelectionBackup;
              bool needToFilter = !ListEquality().equals(filterBoxChecked, filterBoxCheckedBackup);
              if(needToSort || needToFilter) // Only update if you made a change
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
      return '$_numReviews Rating';
    return '$_numReviews Ratings';
  }

  // https://medium.com/level-up-programming/flutter-stream-tutorial-asynchronous-dart-programming-991e6cf97c5a
  void _updateCurrentReviews(String searchQuery, {Tag tag}) {
    igRepository.currentReviews = [];
    igRepository.currNumStars = [0,0,0,0,0,0];
    igRepository.allReviews.forEach((review) {
      bool isMatch = (tag == null) ? _reviewMatchesSearchQuery(review, searchQuery) : review.tags.contains(tag);
      if(isMatch) {
        igRepository.currNumStars[review.stars]++;
        if (filterBoxChecked[review.stars])
          igRepository.currentReviews.add(review);
      }
    });
    sortLabels[sortSelection].mySort(igRepository.currentReviews);
    _reviewController.sink.add(igRepository.currentReviews);
    igRepository.showingAll = false;
    igRepository.madeChange();
  }

  void _clearSearchText() {
    _textController.clear();
    clearCurrTag();
    _reviewController.sink.add(igRepository.allReviews);
    igRepository.showingAll = true;
    igRepository.currNumStars = 
      List.from(igRepository.allNumStars);
    resetSortAndFilterOptions();
    igRepository.madeChange();
  }

  bool _reviewMatchesSearchQuery(Review review, String searchQuery) {
    Map<String, String> terms = {'name': review.restaurantName, 'place': review.location, 'query': searchQuery};
    terms.forEach((key, value) => terms[key] = processStringForSearch(value));
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
          child: MyDrawer(widget.textController),
        ),
      ),
      drawerEnableOpenDragGesture: widget.tabController.index != 1,
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
    );
  }

  Widget _buildBottomBar() {
    return ConvexAppBar(
      controller: widget.tabController,
      items: _homeTabs,
      // elevation: 0,
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
          });
        } else if(i == 0) {
          setState(() {
            _fabVisible = true;
            widget.scrollController.addListener(_updateFabVisible);
          });
        }
      },
    );
  }
}