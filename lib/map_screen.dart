import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:instacritic/instagram_repository.dart';
import 'package:instacritic/review.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  static final route = '/map';
  @override _MapScreenState createState() => _MapScreenState();
}
/* TODO: 
- Make custom markers work (or just use regular markers)
- Get lat lon for each restaurant
*/
class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true; // Used to keep tab alive
  BitmapDescriptor pinLocationIcon;
  Set<Marker> _markers = {};
  Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print('rebuild map screen');
    final CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(41.3163, -72.9223),
      zoom: 14.4746,
    );

    return FutureBuilder(
      future: Provider.of<InstagramRepository>(context,listen: false).getReviewsAsStream(),
      builder: (context, AsyncSnapshot<Stream<QuerySnapshot>> snapshot) {
        if(!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        return StreamBuilder(
          stream: snapshot.data,
          builder: (context, snapshot) {
            if(snapshot == null || snapshot.connectionState == ConnectionState.waiting ||
              !Provider.of<InstagramRepository>(context).ready) {
              return Center(child: CircularProgressIndicator());
            }
            _updateMarkers(snapshot);
            return GoogleMap(
              markers: _markers,
              mapType: MapType.normal,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                if(!_controller.isCompleted)
                  _controller.complete(controller);
              },
            );
          }
        );
      }
    );
  }

  void _updateMarkers(AsyncSnapshot<QuerySnapshot> snapshot) {
    _markers = {};
    List<Review> currReviews = Provider.of<InstagramRepository>(context).currentReviews;
    Set<String> currMediaIds = {};
    currReviews.forEach((rev) {currMediaIds.add(rev.mediaId);});
    List<QueryDocumentSnapshot> docs = snapshot.data.docs;
    for(int i = 0; i < docs.length; i++) {
      Map<String, dynamic> review = docs[i].data();
      if(review['gmap_location'] != null && currMediaIds.contains(review['media_id'])) {
        Marker m = _markerFromFirestoreDocSnap(review);
        _markers.add(m);
      }
    }
  }

  Marker _markerFromFirestoreDocSnap(Map<String, dynamic> review) {
    InfoWindow infoWindow = InfoWindow(
      title: review['restaurant_name'],
      snippet: review['gmap_address'],
    );
    return Marker(
      markerId: MarkerId(review['media_id']),
      position: LatLng(review['gmap_location'].latitude, review['gmap_location'].longitude),
      infoWindow: infoWindow,
    );
  }
}