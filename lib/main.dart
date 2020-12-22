
import 'dart:async';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gradient_colors/flutter_gradient_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/subjects.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
void main() => runApp(MyApp());

class Review {
  String restaurantName;
  int stars;
  String location;
  String permalink;
  DateTime timestamp;
  String mediaUrl;
  Review({this.restaurantName, this.stars, this.location, this.permalink, this.timestamp, this.mediaUrl});
  factory Review.fronJson(Map<String, dynamic> postData) {
    List<dynamic> captionData = postData['caption'].split(" - ");
    int stars = (captionData[0].contains('💀')) ? 0 : int.parse(captionData[0].substring(0,captionData[0].indexOf('/')));
    return Review(
      restaurantName: captionData[1],
      stars: stars,
      location: captionData[2],
      permalink: postData['permalink'],
      timestamp: DateTime.parse(postData['timestamp']),
      mediaUrl: postData['media_url'],
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
class Label {
  String text;
  Function(dynamic) mySort;
  Label({this.text, this.mySort});
}

List<Label> _sortLabels = [
  Label(text: 'Newest',       mySort: (reviewList) {return reviewList.sort((Review a, Review b) => b.timestamp.compareTo(a.timestamp));}),
  Label(text: 'Oldest',       mySort: (reviewList) {return reviewList.sort((Review a, Review b) => a.timestamp.compareTo(b.timestamp));}),
  Label(text: 'Alphabetical', mySort: (reviewList) {return reviewList.sort((Review a, Review b) => a.restaurantName.compareTo(b.restaurantName));}),
  Label(text: '★ ascending',  mySort: (reviewList) {return reviewList.sort((Review a, Review b) => a.stars.compareTo(b.stars));}),
  Label(text: '★ descending', mySort: (reviewList) {return reviewList.sort((Review a, Review b) => b.stars.compareTo(a.stars));}),
];

class _InstaCriticState extends State<InstaCritic> {
  List<Review> allReviews = [];
  List<Review> currentReviews = [];
  String igUsername;
  StreamController<List<Review>> reviewController = BehaviorSubject(); // ignore: close_sinks  
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
    // postList.forEach((post) {
    //   print(post);
    //   print('\n');
    // });
    if(postList.length > 0)
      igUsername = postList[0]['username'];
    for(int i = 0; i < postList.length; i++)
      allReviews.add(Review.fronJson(postList[i]));
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
    try { // Wait for Firebase to initialize and set `_initialized` state to true
      await Firebase.initializeApp();
    } catch(e) { // Set `_error` state to true if Firebase initialization fails
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
        headers: <String, String>{},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildRow(Review review) {
    return GestureDetector(
      child: Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: ListTile(
          leading: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 44, minHeight: 44, maxHeight: 64, maxWidth: 64),
            child: Image.network(review.mediaUrl),
          ),
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

  // https://medium.com/level-up-programming/flutter-stream-tutorial-asynchronous-dart-programming-991e6cf97c5a
  void _searchUser(String searchQuery) {
    List<Review> searchResult = [];
    if(searchQuery.isEmpty) {
      reviewController.sink.add(allReviews);
      return;
    }
    allReviews.forEach((review) {
      if (review.restaurantName.toLowerCase().contains(searchQuery.toLowerCase()) ||
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
              hintText: 'Search by restaurant or place name',
              contentPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 6),
              border: OutlineInputBorder(
                  //borderSide: BorderSide(width: 3.1, color: Colors.black),
                  borderRadius: BorderRadius.circular(6))),
        ),
      )
    );
  }

  Label _currentSortLabel = _sortLabels[0];
  Widget _buildSortButton() {
    return Container(
      padding: EdgeInsets.only(top: 11, right: 20),
      child: PopupMenuButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        offset: Offset(0,55),
        tooltip: 'Sort',
        icon: Icon(Icons.sort_rounded, size: 27),
        itemBuilder: (_) => List.generate(_sortLabels.length, (index) {
          return CheckedPopupMenuItem(
              checked: (_currentSortLabel == _sortLabels[index]),
              value: _sortLabels[index],
              child: Text(_sortLabels[index].text),
            );
        }),
        onSelected: (value) { setState(() {
          value.mySort(currentReviews);
          reviewController.sink.add(currentReviews);
          _currentSortLabel = value; 
        });},
      )
    );
  }
  final List<TabItem> _myTabs = [
    TabItem(icon: Icons.list, title: 'List'),
    TabItem(icon: Icons.map, title: 'Map'),
    // TabItem(icon: Icons.settings, title: 'Settings'),
  ];
  // Used for showing the snackbar
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    // Show error message if initialization failed
    if(_error) { return Text("Error"); }
    // Show a loader until FlutterFire is initialized
    if (!_initialized) { return Text("Loading"); }

    return DefaultTabController(
      length: _myTabs.length,
      initialIndex: 0,
      child: Scaffold(
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
                SnackBar( // Briefly show a snackbar confirming reload
                  duration: Duration(milliseconds: 750),
                  content: Text('Reloading...'),
                )
              );
            },
          )]
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildListTabView(),
            _buildMapTabView(),
          ],
        ),
        bottomNavigationBar: ConvexAppBar(
          items: _myTabs,
          style: TabStyle.react,
          gradient: LinearGradient(colors: GradientColors.purplePink),
          color: Colors.white,
        ),
        ),
    );
  }

  Widget _buildListTabView() {
    return Column(
      children: [
        Row(children: [_buildSearchBar(), _buildSortButton()]),
        _buildReviewList(),
      ],
    );
  }

  Widget _buildMapTabView() {
    Completer<GoogleMapController> _controller = Completer();
    final CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(41.3163, -72.9223),
      zoom: 14.4746,
    );

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _kGooglePlex,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
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
      children: (value == 0) ? [Icon(FontAwesomeIcons.skull, size: 20, color: Colors.grey[400])] : List.generate(value, (index) {
        return Icon( Icons.star );
      }),
    );
  }
}

class InstaCritic extends StatefulWidget {
  @override
  State<InstaCritic> createState() => _InstaCriticState();
}