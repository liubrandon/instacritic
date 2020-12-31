import 'package:flutter/material.dart';
import 'package:instacritic/review.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';
import 'instagram_repository.dart';


class InfoScreen extends StatelessWidget {
  final TextEditingController textController;
  const InfoScreen(this.textController);
  @override
  Widget build(BuildContext context) {
    List<Review> reviewsWithErrors = Provider.of<InstagramRepository>(context).reviewsWithErrors;
    List<int> numStars = Provider.of<InstagramRepository>(context).currNumReviewsWithStars;
    int numShown = Provider.of<InstagramRepository>(context).numReviewsShown;
    int totalReviews = Provider.of<InstagramRepository>(context).numReviewsShown;
    String searchQuery = textController.text;
    return Padding(
      padding: EdgeInsets.only(left: 15, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: EdgeInsets.all(10)),
          Text('Instacritic', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,),),
          Padding(padding: EdgeInsets.all(5)),
          Text('Made with ♡ by Brandon Liu.', style: TextStyle(fontSize: 14),),
          Padding(padding: EdgeInsets.all(5)),
          Text('Restaurant reviews from Instagram with searching, filtering, and a map.', style: TextStyle(fontSize: 14),),
          Padding(padding: EdgeInsets.all(5)),
          Text('Version: ${const String.fromEnvironment('APP_VERSION')}.', style: TextStyle(fontSize: 14),),
          Padding(padding: EdgeInsets.all(15)),
          Text("Breakdown of${searchQuery.isEmpty ? ' all' : ' the'} $numShown reviews${searchQuery.isEmpty ? '' : " matching \"$searchQuery\""}:"),
          Padding(padding: EdgeInsets.all(5)),
          Center(child:Text("~${format((numStars[0]/numShown)*100)}% 0 stars")),
          Center(child:Text("~${format((numStars[1]/numShown)*100)}% 1 stars")),
          Center(child:Text("~${format((numStars[2]/numShown)*100)}% 2 stars")),
          Center(child:Text("~${format((numStars[3]/numShown)*100)}% 3 stars")),
          Center(child:Text("~${format((numStars[4]/numShown)*100)}% 4 stars")),
          Padding(padding: EdgeInsets.all(5)),
          if(reviewsWithErrors.isNotEmpty) 
            Text('Could not import ${reviewsWithErrors.length} post(s):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
          if(reviewsWithErrors.isNotEmpty)   
            _buildReviewsWithErrorsList(context, reviewsWithErrors),
        ],
      ),
    );
    
  }

  String format(double n) {
    return n.toStringAsFixed(n.round() == n ? 0 : 0);
  }

  Widget _buildReviewsWithErrorsList(BuildContext context, List<Review> reviewsWithErrors) {
    return Expanded(
          child: Container(
                height: MediaQuery.of(context).size.height,
                width: 300,
                child: ListView.builder(
                      itemCount: reviewsWithErrors.length,
                      itemBuilder: (BuildContext context, int i) {  
                        return Link(
                          uri: Uri.parse(reviewsWithErrors[i].permalink),
                          target: LinkTarget.self,
                          builder: (_, followLink) {
                            return ListTile(
                              title: Text('Caption: ' + reviewsWithErrors[i].restaurantName,
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(DateFormat.yMMMMd('en_US').format(reviewsWithErrors[i].postTimestamp),
                                    style: TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(icon: Icon(Icons.open_in_new, size: 18), onPressed: followLink),
                              dense: true,
                            );
                          }
                        );
                      },
                    ),
                ),
    );
  }
}