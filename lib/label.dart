import 'review.dart';

class Label {
  String text;
  Function(dynamic) mySort;
  Label({this.text, this.mySort});
}

final List<Label> sortLabels = [
  Label(text: 'Newest', mySort: (reviewList) {return reviewList.sort((Review a, Review b) => b.timestamp.compareTo(a.timestamp));}),
  Label(text: 'Oldest', mySort: (reviewList) {return reviewList.sort((Review a, Review b) => a.timestamp.compareTo(b.timestamp));}),
  Label(text: 'A-Z by restaurant', mySort: (reviewList) {return reviewList.sort((Review a, Review b) => a.restaurantName.compareTo(b.restaurantName));}),
  Label(text: 'A-Z by location', mySort: (reviewList) {return reviewList.sort((Review a, Review b) => a.location.compareTo(b.location));}),
  Label(text: 'Rating ascending', mySort: (reviewList) {return reviewList.sort((Review a, Review b) => a.stars.compareTo(b.stars));}),
  Label(text: 'Rating descending', mySort: (reviewList) {return reviewList.sort((Review a, Review b) => b.stars.compareTo(a.stars));}),
];