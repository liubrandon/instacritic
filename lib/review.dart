import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  String restaurantName;
  int stars;
  String location;
  String permalink;
  DateTime postTimestamp;
  String mediaUrl;
  String mediaId;
  
  Review({
    this.restaurantName, 
    this.stars, 
    this.location, 
    this.permalink, 
    this.postTimestamp, 
    this.mediaUrl, 
    this.mediaId
  });
  
  // Takes in a map representing a single Instagram post from the
  // json returned by the Instagram API and creates a Review
  factory Review.fromJson(Map<String, dynamic> postData) {
    List<dynamic> captionData; 
    try {
      captionData = postData['caption'].split("-");
    } catch (e) {
      print(e);
      return null;
    }
    if(captionData.length != 3) return null;
    for(int i = 0; i < captionData.length; i++) captionData[i] = captionData[i].trim();
    int stars = (captionData[0].contains('💀')) ? 0 : int.parse(captionData[0].substring(0,captionData[0].indexOf('/')));
    return Review(
      restaurantName: captionData[1],
      stars: stars,
      location: captionData[2],
      permalink: postData['permalink'],
      postTimestamp: DateTime.parse(postData['timestamp']),
      mediaUrl: postData['media_url'],
      mediaId: postData['id'],
    );
  }

  factory Review.fromFirestoreDocSnap(DocumentSnapshot doc) {
    return Review(
      restaurantName: doc['restaurant_name'],
      stars: doc['stars'],
      location: doc['location'],
      permalink: doc['permalink'],
      postTimestamp: doc['post_timestamp'].toDate(),
      mediaUrl: doc['media_url'],
      mediaId: doc['media_id'],
    );
  }

  @override
  String toString() {
    return restaurantName+'/'+
    stars.toString()+'/'+
    location+'/'+
    permalink+'/'+
    postTimestamp.toString()+'/'+
    mediaUrl+'/'+
    mediaId;
  }

  static bool reviewsEqual(Review a, Review b) {
    if (a.restaurantName == b.restaurantName &&
        a.stars == b.stars &&
        a.location == b.location &&
        a.permalink == b.permalink &&
        // a.postTimestamp == b.postTimestamp && // Ignore differences in DateTime objects (looks slight)
        a.mediaUrl == b.mediaUrl &&
        a.mediaId == b.mediaId) {
          return true;
    }
    return false;
  }
}