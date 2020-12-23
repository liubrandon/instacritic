class Review {
  String restaurantName;
  int stars;
  String location;
  String permalink;
  DateTime timestamp;
  String mediaUrl;
  
  Review({this.restaurantName, this.stars, this.location, this.permalink, this.timestamp, this.mediaUrl});
  
  // Takes in a map representing a single Instagrom post from the
  // json returned by the Instagram API and creates a Review
  factory Review.fronJson(Map<String, dynamic> postData) {
    List<dynamic> captionData = postData['caption'].split("-");
    captionData.forEach((str) { str.trim(); });
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