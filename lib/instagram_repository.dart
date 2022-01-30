import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:instacritic/constants.dart';
import 'package:instacritic/tag.dart';
import 'package:latlong/latlong.dart';
import 'review.dart';

class InstagramRepository with ChangeNotifier {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;
  String igUsername;
  String igUserId;
  List<Review> allReviews = [];
  List<Review> currentReviews = [];
  List<Review> reviewsWithErrors = [];
  List<int> currNumStars = [0, 0, 0, 0, 0];
  List<int> allNumStars = [0, 0, 0, 0, 0];
  bool ready = false;
  bool showingAll = true;
  bool calculatedDistances = false;
  HashMap<Tag, int> allTags = HashMap<Tag, int>();
  Map<Tag, int> allTagsSorted = Map<Tag, int>();

  InstagramRepository() {
    getReviews();
  }

  void madeChange() => notifyListeners();

  Future<String> getInstagramToken() async {
    String username = 'unagibrandon';
    const username_override =
        const String.fromEnvironment('USERNAME', defaultValue: '');
    if (username_override != '') username = username_override;
    DocumentSnapshot doc =
        await firestore.collection('users').doc('$username').get();
    return doc.data()['ig_long_lived_token'];
  }

  Future<Map<String, Review>> getReviewsAsMap() async {
    CollectionReference reviewsCollection =
        firestore.collection('users/$igUsername/reviews');
    QuerySnapshot reviews = await reviewsCollection.get();
    if (reviews.docs.length == 0) return null;
    Map<String, Review> reviewMap = {};
    for (int i = 0; i < reviews.docs.length; i++) {
      Review r = Review.fromFirestoreDocSnap(reviews.docs[i]);
      reviewMap['${r.mediaId}'] = r;
    }
    return reviewMap;
  }

  Future<Review> getReviewFromFirestore(String mediaId) async {
    DocumentSnapshot doc = await firestore
        .collection('users/$igUsername/reviews')
        .doc('$mediaId')
        .get();
    if (!doc.exists)
      return Review(); // if nothing in Firestore return empty review
    return Review.fromFirestoreDocSnap(doc);
  }

  Future<void> addLatLngToAllReviews() async {
    for (int i = 0; i < allReviews.length; i++) {
      getReviewFromFirestore(allReviews[i].mediaId).then((review) {
        allReviews[i].lat = review.lat;
        allReviews[i].lng = review.lng;
      });
    }
  }

  void calculateDistances(double lat, double lng) {
    for (int i = 0; i < allReviews.length; i++) {
      if (allReviews[i].lat == null || allReviews[i].lng == null) continue;
      final Distance distance = Distance();
      final int meters = distance(
          LatLng(allReviews[i].lat, allReviews[i].lng), LatLng(lat, lng));
      allReviews[i].distanceToUser = meters;
    }
  }

  Future<Stream<QuerySnapshot>> getReviewsAsStream() async =>
      FirebaseFirestore.instance
          .collection('users/$igUsername/reviews')
          .snapshots();

  Future<void> addReviewToFirestore(Review r) async {
    DocumentReference newReview = FirebaseFirestore.instance
        .collection('users/$igUsername/reviews/')
        .doc('${r.mediaId}');
    newReview
        .set({
          'restaurant_name': r.restaurantName,
          'stars': r.stars,
          'location': r.location,
          'permalink': r.permalink,
          'post_timestamp': r.postTimestamp,
          'media_url': r.mediaUrl,
          'media_id': r.mediaId, // Stored as the document id
        }, SetOptions(merge: true))
        .then((value) =>
            print("Review for ${r.restaurantName} added to Firestore"))
        .catchError((error) =>
            print("Failed to add review: ${r.restaurantName} $error"));
  }

  Future<void> addThumbnailUrlToFirestore(Review r, String thumbnailUrl) async {
    DocumentReference reviewRef = FirebaseFirestore.instance
        .collection('users/$igUsername/reviews/')
        .doc('${r.mediaId}');
    reviewRef
        .set({
          'thumbnail_url': thumbnailUrl,
        }, SetOptions(merge: true))
        .then((value) => print(
            "Download url for ${r.restaurantName} added to Firestore: $thumbnailUrl"))
        .catchError((error) => print(
            "Failed to add thumbnailUrl to firestore: ${r.restaurantName} $error"));
  }

  Future<void> addTagsToFirestore(Review r, Set<Tag> tags) async {
    DocumentReference reviewRef = FirebaseFirestore.instance
        .collection('users/$igUsername/reviews/')
        .doc('${r.mediaId}');
    reviewRef
        .set({
          'tags': tags.map((e) => e.displayName).toList(),
        }, SetOptions(merge: true))
        .then(
            (value) => print("Tags for ${r.restaurantName} added to Firestore"))
        .catchError((error) => print(
            "Failed to add tags to firestore: ${r.restaurantName} $error"));
  }

  int get numReviewsShown =>
      (showingAll) ? allReviews.length : currentReviews.length;

  int get totalNumReviews => allReviews.length;

  Future<void> getReviews() async {
    // Construct the Instagram API calls and get the response
    final String igToken = await getInstagramToken();
    final String igUrlMe = 'https://graph.instagram.com/me/';
    String queryStringMe = Uri(queryParameters: {
      'fields': 'id,media_count,username',
      'access_token': igToken
    }).query;
    var resMe = await http.get(igUrlMe + '?' + queryStringMe);
    var user = jsonDecode(resMe.body);
    igUsername = user['username'];
    igUserId = user['id'];
    final String igUrl = 'https://graph.instagram.com/me/media';
    final String igFields =
        'caption,id,media_type,thumbnail_url,media_url,permalink,timestamp';
    String queryString =
        Uri(queryParameters: {'fields': igFields, 'access_token': igToken})
            .query;
    var res = await http.get(igUrl + '?' + queryString);
    var curr25 = jsonDecode(res.body);
    // Get the list of posts from the response and convert them into Reviews
    List<dynamic> postList = curr25['data'];
    while (curr25['paging']['next'] != null) {
      // Get all pages until there are no more
      res = await http.get(curr25['paging']['next']);
      curr25 = jsonDecode(res.body);
      postList.addAll(curr25['data']);
    }
    allReviews = List.filled(postList.length, Review());
    currentReviews = List.filled(postList.length, Review());
    reviewsWithErrors = [];
    allNumStars = [0, 0, 0, 0, 0, 0]; // last index is skulls
    currNumStars = [0, 0, 0, 0, 0, 0];
    for (int i = 0; i < postList.length; i++) {
      final Review rev = Review.fromJson(postList[i]);
      if (rev.hasError) {
        // Issue parsing review
        reviewsWithErrors.add(rev);
      } else {
        currNumStars[rev.stars]++;
        allNumStars[rev.stars]++;
        allReviews[i] = rev;
        currentReviews[i] = rev;
        getReviewFromFirestore(rev.mediaId).then((firestoreReview) {
          if (!Review.reviewsEqual(rev, firestoreReview)) {
            // Update Firestore if the data from Instagram is different
            addReviewToFirestore(rev);
          }
          if (firestoreReview.thumbnailUrl == null) {
            http.get(rev.mediaUrl).then((response) async {
              final String base64Str = base64.encode(response.bodyBytes);
              firebase_storage.Reference ref =
                  storage.ref('users/ig_media/$igUserId/${rev.mediaId}.jpg');
              try {
                await ref.putString(base64Str,
                    format: firebase_storage.PutStringFormat.base64,
                    metadata: firebase_storage.SettableMetadata(
                        contentType: 'image/jpeg'));
              } on firebase_storage.FirebaseException catch (e) {
                print('Upload to firebase storage failed');
                print(e);
              }
              await Future.delayed(Duration(
                  milliseconds:
                      4000)); // Dumb way to make sure resized image is done saving (better to have a callback)
              firebase_storage.Reference thumbRef = storage
                  .ref('users/ig_media/$igUserId/${rev.mediaId}_100x100.jpg');
              thumbRef.getDownloadURL().then((thumbnailUrl) {
                allReviews[i].thumbnailUrl = thumbnailUrl;
                currentReviews[i].thumbnailUrl = thumbnailUrl;
                addThumbnailUrlToFirestore(rev, thumbnailUrl);
              });
            });
          } else {
            allReviews[i].thumbnailUrl = firestoreReview.thumbnailUrl;
            currentReviews[i].thumbnailUrl = firestoreReview.thumbnailUrl;
          }
          if (firestoreReview.tags == null || firestoreReview.tags.isEmpty) {
            HashSet<Tag> tags = HashSet<Tag>();
            List<String> parts;
            if (processStringForSearch(rev.location) == 'washingtondc')
              parts = [rev.location];
            else
              parts = rev.location.split(',');
            parts.forEach((part) {
              Tag t = Tag(part);
              tags.add(t);
              allTags.update(t, (value) => value + 1,
                  ifAbsent: () => 1); // track total occurences of each tag
            });
            addTagsToFirestore(rev, tags);
            allReviews[i].tags = tags;
            currentReviews[i].tags = tags;
          } else {
            // If there are tags in firestore just use them
            allReviews[i].tags = firestoreReview.tags;
            currentReviews[i].tags = firestoreReview.tags;
            for (Tag t in firestoreReview.tags)
              allTags.update(t, (value) => value + 1,
                  ifAbsent: () => 1); // track total
          }
          if (i == postList.length - 1) {
            // Once you've added the thumbnail/tag data from the last post build list screen
            // and also make the sorted list of tags
            var mapEntries = allTags.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            allTagsSorted
              ..clear()
              ..addEntries(mapEntries);
            ready = true;
            notifyListeners();
          }
        });
      }
    }
  }
}
