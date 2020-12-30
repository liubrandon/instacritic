import 'package:flutter/material.dart';
import 'package:instacritic/review.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';
import 'instagram_repository.dart';


class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Review> reviewsWithErrors = Provider.of<InstagramRepository>(context).reviewsWithErrors;
    return Padding(
      padding: EdgeInsets.only(left: 15, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: EdgeInsets.all(10)),
          Text('Instacritic', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,),),
          Text('Made with ♡ by Brandon Liu.', style: TextStyle(fontSize: 14),),
          Padding(padding: EdgeInsets.all(5)),
          Text('Restaurant reviews from Instagram with searching, filtering, and a map.', style: TextStyle(fontSize: 14),),
          Padding(padding: EdgeInsets.all(5)),
          Text('Version: ${const String.fromEnvironment('APP_VERSION')}.', style: TextStyle(fontSize: 14),),
          Padding(padding: EdgeInsets.all(15)),
          if(reviewsWithErrors.isNotEmpty) 
            Text('Could not import these posts:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
          if(reviewsWithErrors.isNotEmpty)   
            _buildReviewsWithErrorsList(context, reviewsWithErrors),
        ],
      ),
    );
                
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