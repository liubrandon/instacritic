import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  String restaurantName;
  int stars;
  String location;
  String permalink;
  DateTime postTimestamp;
  String mediaUrl;
  String mediaId;
  bool hasError;
  bool isVideo;
  double lat;
  double lng;
  int distanceToUser; // meters
  String thumbnailUrl;

  Review({
    this.restaurantName, 
    this.stars, 
    this.location, 
    this.permalink, 
    this.postTimestamp, 
    this.mediaUrl, 
    this.mediaId,
    this.hasError = false,
    this.lat,
    this.lng,
    this.distanceToUser,
    this.thumbnailUrl,
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
    String mediaUrl = (postData['media_type'] == 'VIDEO') ? postData['thumbnail_url'] : postData['media_url'];
    bool isSkull = captionData[0].contains('💀');
    int slashIndex = captionData[0].indexOf('/');
    if(captionData.length != 3 || (!isSkull && slashIndex == -1))
      return Review(hasError: true, restaurantName: postData['caption'], permalink: postData['permalink'], postTimestamp: DateTime.parse(postData['timestamp']));
    for(int i = 0; i < captionData.length; i++) captionData[i] = captionData[i].trim();
    int stars = (isSkull) ? 0 : int.parse(captionData[0].substring(0,slashIndex));
    String location = captionData[2];
    if(location == 'New York, New York')
      location = 'New York, NY';
    return Review(
      restaurantName: captionData[1],
      stars: stars,
      location: location,
      permalink: postData['permalink'],
      postTimestamp: DateTime.parse(postData['timestamp']),
      mediaUrl: mediaUrl,
      mediaId: postData['id'],
      distanceToUser: 1<<31,
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
      lat: doc.data()['gmap_location'] == null ? null : doc['gmap_location'].latitude,
      lng: doc.data()['gmap_location'] == null ? null : doc['gmap_location'].longitude,
      thumbnailUrl: doc.data()['thumbnail_url'] == null ? null : doc['thumbnail_url'],
    );
  }

  @override
  String toString() {
    return restaurantName+'\n'+
    stars.toString()+'\n'+
    location+'\n'+
    // permalink+'\n'+
    // postTimestamp.toString()+'/'+
    // mediaUrl+'\n'+
    mediaId;
    // thumbnailUrl;
  }

  static bool reviewsEqual(Review a, Review b) {
    if(a == null || b == null)
      return false;
    if (a.restaurantName == b.restaurantName &&
        a.stars == b.stars &&
        a.location == b.location &&
        a.permalink == b.permalink &&
        // a.postTimestamp == b.postTimestamp && // Ignore differences in DateTime objects (looks slight)
        // a.mediaUrl == b.mediaUrl && // Instagram CDN changes urls regularly
        a.mediaId == b.mediaId) {
          return true;
    }
    // print(a);
    // print(b);
    return false;
  }
}