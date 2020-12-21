
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
    final String igToken = await getInstagramToken();
    final String igUrl = 'https://graph.instagram.com/me/media';
    final String igFields = 'caption,id,media_type,media_url,permalink,timestamp';
    String queryString = Uri(queryParameters: {'fields': igFields, 'access_token': igToken}).query;
    var res = await http.get(igUrl + '?' + queryString);
    List<dynamic> postList = jsonDecode(res.body)['data'];
    for(int i = 0; i < postList.length; i++) {
      reviews.add(Review.fronJson(postList[i]));
    }
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
    return ListView.builder(
      itemCount: reviews.length,
        padding: EdgeInsets.all(16.0),
        itemBuilder: /*1*/ (context, i) {
          return _buildRow(reviews[i]);
        });
  }

  Widget _buildRow(Review review) {
    return ListTile(
      title: Text(
        review.restaurantName,
        style: TextStyle(fontSize: 18.0),
      ),
      subtitle: Text(
        review.location
      ),
      trailing: Text(review.stars.toString())
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show error message if initialization failed
    if(_error) {
      return Text("Error");
    }

    // Show a loader until FlutterFire is initialized
    if (!_initialized) {
      return Text("Loading");
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text('Brandon\'s Food Reviews'),
      ),
      body: _buildReviewList(),
    );
  }

  // @override
  // Widget build(BuildContext context) {
    
  //   return Scaffold(
  //     appBar: AppBar(
  //       backgroundColor: Colors.red,
  //       title: Text('Brandon\'s Restaurant Reviews'),
  //     ),
  //     body: _buildReviewList(),
  //   );
  // }
}

class InstaCritic extends StatefulWidget {
  @override
  State<InstaCritic> createState() => _InstaCriticState();
}

// void getReviews() async {
//   QuerySnapshot qs = await firestore.collection('reviews').get();
//   qs.docs.forEach((doc) {
//           reviews.add(Review(doc["name"], doc["stars"], doc["location"]));
//   });
//   setState(() {
//     _initialized = true;
//   });
// }