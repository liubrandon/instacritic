import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review.dart';

class InstagramRepository with ChangeNotifier {
  String igUsername;
  List<Review> allReviews = [];
  List<Review> currentReviews = [];
  bool ready = false;

  InstagramRepository() {
    getReviews();
  }

  void madeChange() => notifyListeners();

  Future<String> getInstagramToken() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('secrets').doc('chirashibrandon').get();
    return doc.data()['ig_token'];
  }

  Future<void> getReviews() async {
    // Construct the Instagram API call and get the response
    final String igToken = await getInstagramToken();
    final String igUrl = 'https://graph.instagram.com/me/media';
    final String igFields = 'caption,id,media_type,media_url,permalink,timestamp,username';
    String queryString = Uri(queryParameters: {'fields': igFields, 'access_token': igToken}).query;
    var res = await http.get(igUrl + '?' + queryString);

    // Get the list of posts from the response and convert them into Reviews
    List<dynamic> postList = jsonDecode(res.body)['data'];
    // postList.forEach((post) => print(post.toString() + '\n'));
    if(postList.length > 0)
      igUsername = postList[0]['username'];
    for(int i = 0; i < postList.length; i++)
      allReviews.add(Review.fronJson(postList[i]));
    ready = true;
    notifyListeners();
  }
}