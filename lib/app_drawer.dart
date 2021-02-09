import 'package:flutter/material.dart';
import 'package:instacritic/chart_screen.dart';
import 'package:instacritic/review.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';
import 'instagram_repository.dart';


class MyDrawer extends StatelessWidget {
  final TextEditingController textController;
  const MyDrawer(this.textController);
  @override
  Widget build(BuildContext context) {
    List<Review> reviewsWithErrors = Provider.of<InstagramRepository>(context).reviewsWithErrors;
    return Padding(
      padding: EdgeInsets.only(left: 0, right: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(padding: EdgeInsets.all(8)),
          Row(
            children: [
              const SizedBox(width: 10),
              ClipOval(
                child: Image.asset('assets/icon.png',
                  height: 50.0, width: 50.0,
                ),
              ),
              const SizedBox(width: 10),
              Text('Instacritic', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,),),
            ],
          ),
          Padding(padding: EdgeInsets.all(5)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text('Restaurant ratings from Instagram with searching, filtering, and a map.', style: TextStyle(fontSize: 15),)
          ),
          Padding(padding: EdgeInsets.all(5)),
          ListTile(
            leading: Icon(Icons.insert_chart_outlined),//, color: Colors.grey[600]),
            title: Text('Charts'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ChartScreen(textController)));
            },
          ),
          Padding(padding: EdgeInsets.all(5)),
          if(reviewsWithErrors.isNotEmpty) 
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Failed to import ${reviewsWithErrors.length} post${reviewsWithErrors.length != 1 ? 's' : ''}:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),)
            ),
          if(reviewsWithErrors.isNotEmpty)   
            _buildReviewsWithErrorsList(context, reviewsWithErrors),
          Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text('Made with ♡ by Brandon Liu.', style: TextStyle(fontSize: 14),)
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text('Version 1.${(const String.fromEnvironment('APP_VERSION'))}', style: TextStyle(fontSize: 14),),
          ),
          Padding(padding: EdgeInsets.all(8)),
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
                              title: Text(reviewsWithErrors[i].restaurantName,
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