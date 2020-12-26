import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review.dart';

class InstagramRepository with ChangeNotifier {
  var _places = gp.GoogleMapsPlaces(apiKey: "AIzaSyDagGkzsqL5cDnTJoSzM3jLYHWPW8dWSds");
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String igUsername;
  List<Review> allReviews = [];
  List<Review> currentReviews = [];
  bool ready = false;
  bool showingAll = true;

  InstagramRepository() {
    getReviews();
  }

  void madeChange() => notifyListeners();

  Future<String> getInstagramToken() async {
    DocumentSnapshot doc = await firestore.collection('users').doc('chirashibrandon').get();
    return doc.data()['ig_token'];
  }

  Future<bool> reviewExistsInFirestore(String media_id) async {
    var docData = await firestore.collection('users/$igUsername/reviews').doc('$media_id').get();
    return docData.exists;
  }

  int getNumReviewsShown() => (showingAll) ? allReviews.length : currentReviews.length;

  Future<void> getReviews() async {
    // Construct the Instagram API call and get the response
    final String igToken = await getInstagramToken();
    final String igUrl = 'https://graph.instagram.com/me/media';
    final String igFields = 'caption,id,media_type,media_url,permalink,timestamp,username';
    String queryString = Uri(queryParameters: {'fields': igFields, 'access_token': igToken}).query;
    var res = await http.get(igUrl + '?' + queryString);
    var curr25 = jsonDecode(res.body);
    // Get the list of posts from the response and convert them into Reviews
    List<dynamic> postList = curr25['data'];
    while(curr25['paging']['next'] != null) {
      // Get all pages until there are no more
      res = await http.get(curr25['paging']['next']);
      curr25 = jsonDecode(res.body);
      postList.addAll(curr25['data']);
    }
    // postList.forEach((post) {print(post); print('\n');});
    if(postList.length > 0)
      igUsername = postList[0]['username'];
    allReviews = [];
    currentReviews = [];
    for(int i = 0; i < postList.length; i++) {
      Review rev = Review.fronJson(postList[i]);
      allReviews.add(rev);
      currentReviews.add(rev);
    }
    ready = true;
    notifyListeners();
  }
}