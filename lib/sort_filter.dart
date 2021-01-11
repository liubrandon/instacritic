import 'review.dart';

class Label {
  String text;
  Function(dynamic) mySort;
  Label({this.text, this.mySort});
}

final List<Label> sortLabels = [
  Label(text: 'Rating ↓', mySort: (reviewList) {return reviewList.sort((Review a, Review b) => b.stars.compareTo(a.stars));}),
  Label(text: 'Rating ↑', mySort: (reviewList) {return reviewList.sort((Review a, Review b) => a.stars.compareTo(b.stars));}),
  Label(text: 'Newest',   mySort: (reviewList) {return reviewList.sort((Review a, Review b) => b.postTimestamp.compareTo(a.postTimestamp));}),
  Label(text: 'Oldest',   mySort: (reviewList) {return reviewList.sort((Review a, Review b) => a.postTimestamp.compareTo(b.postTimestamp));}),
  Label(text: 'Distance', mySort: (reviewList) {return reviewList.sort((Review a, Review b) => a.distanceToUser.compareTo(b.distanceToUser));}),
];

const int DEFAULT_SORT_INDEX = 2;

int sortSelection = DEFAULT_SORT_INDEX;
List<bool> filterBoxChecked = [true,true,true,true,true];

void resetSortAndFilterOptions() {
  sortSelection = DEFAULT_SORT_INDEX;
  for(int i = 0; i < filterBoxChecked.length; i++)
    filterBoxChecked[i] = true;
}