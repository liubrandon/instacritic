
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
void main() => runApp(MyApp());

class Review {
  String restaurantName;
  int stars;
  String location;
  Review({this.restaurantName, this.stars, this.location});
  factory Review.fronJson(Map<String, dynamic> postData) {
    List<dynamic> captionData = postData['caption'].split(" - ");
    return Review(
      restaurantName: captionData[1],
      stars: int.parse(captionData[0].substring(0,captionData[0].indexOf('/'))),
      location: captionData[2],
    );
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
  List<Review> reviews = [];
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
    final String igFields = 'caption,id,media_type,media_url,permalink,timestamp';
    String queryString = Uri(queryParameters: {'fields': igFields, 'access_token': igToken}).query;
    var res = await http.get(igUrl + '?' + queryString);

    // Get the list of posts from the response and convert them into Reviews
    List<dynamic> postList = jsonDecode(res.body)['data'];
    for(int i = 0; i < postList.length; i++) {
      reviews.add(Review.fronJson(postList[i]));
    }
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
    reviewSearchController.sink.add(reviews);
    return StreamBuilder(
      stream: reviewSearchController.stream,
      builder: (BuildContext buildContext, AsyncSnapshot<List<Review>> snapshot) {
        if(snapshot == null) {
          return CircularProgressIndicator();
        }
        else if(snapshot.connectionState == ConnectionState.waiting) {
          return Padding(padding: EdgeInsets.only(top: 100), child: CircularProgressIndicator());
        }
        else {
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
    // return ListView.builder(
    //   scrollDirection: Axis.vertical,
    //   shrinkWrap: true,
    //   itemCount: reviews.length,
    //     padding: EdgeInsets.all(16.0),
    //     itemBuilder: (context, i) {
    //       return _buildRow(reviews[i]);
    //     });
  }

  Widget _buildRow(Review review) {
    return Card(child: ListTile(
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
    );
  }
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final reviewSearchController = StreamController<List<Review>>();

  void _searchUser(String searchQuery) {
    List<Review> searchResult = [];
    if(searchQuery.isEmpty) {
      reviewSearchController.sink.add(reviews);
      return;
    }
    reviews.forEach((review) {
      if(review.restaurantName.toLowerCase().contains(searchQuery.toLowerCase()))
        searchResult.add(review);
    });
    reviewSearchController.sink.add(searchResult);
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: TextField(
        onChanged: (text) => _searchUser(text),
        decoration: InputDecoration(
            suffixIcon: Icon(Icons.search),
            hintText: 'Search by restaurant name',
            contentPadding:
                EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            border: OutlineInputBorder(
                //borderSide: BorderSide(width: 3.1, color: Colors.black),
                borderRadius: BorderRadius.circular(10))),
      ),
    );
  }
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
        backgroundColor: Colors.indigo[600],
        title: Text('Brandon\'s Food Reviews'),
        actions: [IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Reload',
          onPressed: () {
            reviews = []; // Reset review list
            getReviews(); // Get latest data from IG
            // Show a snackbar briefly confirming reload
            scaffoldKey.currentState.showSnackBar(
              SnackBar(
                duration: Duration(milliseconds: 750),
                content: Text('Reloading...'),
              )
            );
          },
        )]
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildReviewList()
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
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
        onPressed: () {
          // Add your onPressed code here!
        },
        child: Icon(Icons.filter_alt),
        backgroundColor: Colors.indigo[600],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
  }
}
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
