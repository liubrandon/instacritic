
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gradient_colors/flutter_gradient_colors.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
void main() => runApp(MyApp());

class Review {
  String restaurantName;
  int stars;
  String location;
  String permalink;
  Review({this.restaurantName, this.stars, this.location, this.permalink});
  factory Review.fronJson(Map<String, dynamic> postData) {
    List<dynamic> captionData = postData['caption'].split(" - ");
    return Review(
      restaurantName: captionData[1],
      stars: int.parse(captionData[0].substring(0,captionData[0].indexOf('/'))),
      location: captionData[2],
      permalink: postData['permalink'],
    );
  }
  @override
  String toString() {
    return "(" + restaurantName + " " + stars.toString() + " " + location + ")";
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstaCritic',
      home: InstaCritic(),
    );
  }
}

class _InstaCriticState extends State<InstaCritic> {
  List<Review> allReviews = [];
  List<Review> currentReviews = [];
  String igUsername;
  final reviewController = StreamController<List<Review>>(); // ignore: close_sinks
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    initializeFlutterFire();
    getReviews();
    super.initState();
  }
  
  Future<String> getInstagramToken() async {
    DocumentSnapshot doc = await firestore.collection('secrets').doc('chirashibrandon').get();
    return doc.data()['ig_token'];
  }

  void getReviews() async {
    // Construct the Instagram API call and get the response
    final String igToken = await getInstagramToken();
    final String igUrl = 'https://graph.instagram.com/me/media';
    final String igFields = 'caption,id,media_type,media_url,permalink,timestamp,username';
    String queryString = Uri(queryParameters: {'fields': igFields, 'access_token': igToken}).query;
    var res = await http.get(igUrl + '?' + queryString);

    // Get the list of posts from the response and convert them into Reviews
    List<dynamic> postList = jsonDecode(res.body)['data'];
    if(postList.length > 0) {
      igUsername = postList[0]['username'];
    }
    for(int i = 0; i < postList.length; i++) {
      allReviews.add(Review.fronJson(postList[i]));
    }
    // allReviews.sort((a, b) => b.stars.compareTo(a.stars)); // May pre-sort by timestamp
    reviewController.sink.add(allReviews);
    // Rebuild the widget once the reviews have been loaded
    setState(() {
      _initialized = true;
    });
  }

  bool _initialized = false;
  bool _error = false;
  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      await Firebase.initializeApp();
    } catch(e) {
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  Widget _buildReviewList() {
    return StreamBuilder(
      stream: reviewController.stream,
      builder: (BuildContext buildContext, AsyncSnapshot<List<Review>> snapshot) {
        if(snapshot == null) {
          return CircularProgressIndicator();
        }
        else if(snapshot.connectionState == ConnectionState.waiting) {
          return Padding(padding: EdgeInsets.only(top: 100), child: CircularProgressIndicator());
        }
        else {
          currentReviews = snapshot.data;
          return ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: snapshot.data.length,
              padding: EdgeInsets.all(16.0),
              itemBuilder: (context, i) {
                return _buildRow(snapshot.data[i]);
            });
        }
      }
    );
  }
  Future<void> _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
    } else {
      throw 'Could not launch $url';
    }
  }
  Widget _buildRow(Review review) {
    return GestureDetector(
      child: Card(child: ListTile(
        title: Text(
          review.restaurantName,
          style: TextStyle(fontSize: 18.0),
        ),
        subtitle: Text(
          review.location
        ),
        trailing: IconTheme(
          data: IconThemeData(
            color: Colors.amber,
            size: 25,
          ),
          child: StarDisplay(value: review.stars)
        ),
        ),
      ),
      onTap: () {
        _launchInBrowser(review.permalink);
      },
    );
  }
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // https://medium.com/level-up-programming/flutter-stream-tutorial-asynchronous-dart-programming-991e6cf97c5a
  void _searchUser(String searchQuery) {
    List<Review> searchResult = [];
    if(searchQuery.isEmpty) {
      reviewController.sink.add(allReviews);
      return;
    }
    allReviews.forEach((review) {
      if(review.restaurantName.toLowerCase().contains(searchQuery.toLowerCase()) ||
         review.location.toLowerCase().contains(searchQuery.toLowerCase())) {
        searchResult.add(review);
      }
    });
    reviewController.sink.add(searchResult);
  }

  Widget _buildSearchBar() {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 14, top: 16),
        child: TextField(
          onChanged: (text) => _searchUser(text),
          decoration: InputDecoration(
              suffixIcon: Icon(Icons.search),
              hintText: 'Search by restaurant name or location',
              contentPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              border: OutlineInputBorder(
                  //borderSide: BorderSide(width: 3.1, color: Colors.black),
                  borderRadius: BorderRadius.circular(10))),
        ),
      )
    );
  }
  int _currentSortValue = 1;
  Widget _buildSortButton() {
    return Container(
      padding: EdgeInsets.only(top: 13, right: 20),
      child: PopupMenuButton(
        initialValue: _currentSortValue,
        offset: Offset(0,60),
        tooltip: 'Sort',
        icon: Icon(Icons.sort_rounded, size: 27),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 1,
            child: Text("Newest"),
          ),
          PopupMenuItem(
            value: 2,
            child: Text("Oldest"),
          ),
          PopupMenuItem(
            value: 3,
            child: Text("★ descending"),
          ),
          PopupMenuItem(
            value: 4,
            child: Text("★ ascending")
          ),
          PopupMenuItem(
            value: 5,
            child: Text("Alphabetical")
          ),
        ],
        onSelected: (value) { setState(() {
          if(value == 1) {
            currentReviews.sort((a, b) => b.stars.compareTo(a.stars));
          }
          else if(value == 2) {
            currentReviews.sort((a, b) => a.stars.compareTo(b.stars));
          }
          else if(value == 3) {
            currentReviews.sort((a, b) => a.restaurantName.compareTo(b.restaurantName));
          }
          print(currentReviews);
          reviewController.sink.add(currentReviews);
          _currentSortValue = value; 
        });},
      )
    );
  }

  bool showSortAndFilter = false;

  // Used for showing the snackbar
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    // Show error message if initialization failed
    if(_error) { return Text("Error"); }
    // Show a loader until FlutterFire is initialized
    if (!_initialized) { return Text("Loading"); }

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: GradientColors.purplePink,
        ))),     
        title: Text(igUsername + '\'s reviews'),
        actions: [IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Reload',
          onPressed: () {
            allReviews = []; // Reset review list
            getReviews(); // Get latest data from IG
            scaffoldKey.currentState.showSnackBar(
              SnackBar( // Show a snackbar briefly confirming reload
                duration: Duration(milliseconds: 750),
                content: Text('Reloading...'),
              )
            );
          },
        )]
      ),
      body: Column(
        children: [
          Row(children: [_buildSearchBar(), _buildSortButton()]),
          _buildReviewList()
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () { setState(() { showSortAndFilter = true; }); },
        child: Container(
          width: 60,
          height: 60,
          child: Icon(
            Icons.filter_list_alt,
          ),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: GradientColors.purplePink)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
  }
}

// https://medium.com/icnh/a-star-rating-widget-for-flutter-41560f82c8cb
class StarDisplay extends StatelessWidget {
  final int value;
  const StarDisplay({Key key, this.value = 0})
      : assert(value != null),
        super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(value, (index) {
        return Icon( Icons.star );
      }),
    );
  }
}

class InstaCritic extends StatefulWidget {
  @override
  State<InstaCritic> createState() => _InstaCriticState();
}