import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review.dart';

class InstagramRepository with ChangeNotifier {
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
    String username = 'unagibrandon';
    const username_override = const String.fromEnvironment('USERNAME', defaultValue: '');
    if(username_override != '') {
      username = username_override;
    }
    DocumentSnapshot doc = await firestore.collection('users').doc('$username').get();
    return doc.data()['ig_long_lived_token'];
  }

  Future<Map<String, Review>> getReviewsAsMap() async {
    CollectionReference reviewsCollection = firestore.collection('users/$igUsername/reviews');
    QuerySnapshot reviews = await reviewsCollection.get();
    if(reviews.docs.length == 0) return null;
    Map<String, Review> reviewMap = {};
    for(int i = 0; i < reviews.docs.length; i++) {
      Review r = Review.fromFirestoreDocSnap(reviews.docs[i]);
      reviewMap['${r.mediaId}'] = r;
    }
    return reviewMap;
  }
  
  Future<Review> getReviewFromFirestore(String mediaId) async {
    DocumentSnapshot doc = await firestore.collection('users/$igUsername/reviews').doc('$mediaId').get();
    if(!doc.exists)
      return Review(); // if nothing in Firestore return empty review
    return Review.fromFirestoreDocSnap(doc);
  }

  Future<Stream<QuerySnapshot>> getReviewsAsStream() async =>
    FirebaseFirestore.instance.collection('users/$igUsername/reviews').snapshots();
  
  void addReviewToFirestore(Review r) {
    DocumentReference newReview = FirebaseFirestore.instance.collection('users/$igUsername/reviews/').doc('${r.mediaId}');
    newReview.set({
      'restaurant_name': r.restaurantName,
      'stars': r.stars,
      'location': r.location,
      'permalink': r.permalink,
      'post_timestamp': r.postTimestamp,
      'media_url': r.mediaUrl,
      'media_id': r.mediaId, // Stored as the document id
    }, SetOptions(merge: true)).then((value) => print("Review for ${r.restaurantName} added to Firestore"))
    .catchError((error) => print("Failed to add review: ${r.restaurantName} $error"));
  }

  int getNumReviewsShown() => (showingAll) ? allReviews.length : currentReviews.length;

  int getNumReviews() => allReviews.length;

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
    if(postList.length > 0)
      igUsername = postList[0]['username'];
    allReviews = [];
    currentReviews = [];
    Map<String, Review> reviewsMap = await getReviewsAsMap();
    for(int i = 0; i < postList.length; i++) {
      Review rev = Review.fromJson(postList[i]);
      if(rev == null) continue;
      allReviews.add(rev);
      currentReviews.add(rev);
      if(reviewsMap == null || !Review.reviewsEqual(rev, reviewsMap[rev.mediaId])) { // Update Firestore if the data from Instagram is different
          addReviewToFirestore(rev);
      }
    }
    ready = true;
    notifyListeners();
  }
}