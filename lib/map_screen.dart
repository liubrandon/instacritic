import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:instacritic/instagram_repository.dart';
import 'package:instacritic/review.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  final Completer<GoogleMapController> mapController;
  final void Function({LatLng northeast, LatLng southwest}) passBoundsUp;
  const MapScreen({this.mapController, this.passBoundsUp});
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
  List<BitmapDescriptor> _markerIcons = [null,null,null,null,null];

  double maxLat = -91.0, minLat =  91.0, maxLng = -181.0, minLng = 181.0;
  
  @override
  void initState() {
    initMarkerIcons();
    super.initState();
  }

  Future<void> initMarkerIcons() async {
    _markerIcons[0] = await BitmapDescriptor.fromAssetImage(ImageConfiguration(), 'assets/number_0.png');
    _markerIcons[1] = await BitmapDescriptor.fromAssetImage(ImageConfiguration(), 'assets/number_1.png');
    _markerIcons[2] = await BitmapDescriptor.fromAssetImage(ImageConfiguration(), 'assets/number_2.png');
    _markerIcons[3] = await BitmapDescriptor.fromAssetImage(ImageConfiguration(), 'assets/number_3.png');
    _markerIcons[4] = await BitmapDescriptor.fromAssetImage(ImageConfiguration(), 'assets/number_4.png');
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
                if(!widget.mapController.isCompleted)
                  widget.mapController.complete(controller);
              },
            );
          }
        );
      }
    );
  }

  Future<void> _updateMarkers(AsyncSnapshot<QuerySnapshot> snapshot) async {
    _markers = {};
    List<Review> currReviews = Provider.of<InstagramRepository>(context).currentReviews;
    Set<String> currMediaIds = {};
    currReviews.forEach((rev) {currMediaIds.add(rev.mediaId);});
    List<QueryDocumentSnapshot> docs = snapshot.data.docs;
    maxLat = -91.0; minLat =  91.0; maxLng = -181.0; minLng = 181.0;
    for(int i = 0; i < docs.length; i++) {
      Map<String, dynamic> review = docs[i].data();
      if(review['gmap_location'] != null && currMediaIds.contains(review['media_id'])) {
        double lat = review['gmap_location'].latitude;
        double lng = review['gmap_location'].longitude;
        maxLat = max(maxLat, lat); maxLng = max(maxLng, lng);
        minLat = min(minLat, lat); minLng = min(minLng, lng);
        Marker m = _markerFromFirestoreDocSnap(review);
        _markers.add(m);
      }
    }
    // widget.passBoundsUp(
    //   northeast: LatLng(maxLng,maxLat),
    //   southwest: LatLng(minLng,minLat),
    // );
    // final GoogleMapController controller = await widget.mapController.future;
    // controller.moveCamera(
    //   CameraUpdate.newLatLngBounds(
    //     LatLngBounds(
    //       // northeast: LatLng(maxLng,maxLat),
    //       // southwest: LatLng(minLng,minLat),
    //       northeast: LatLng(41.4993, -81.6944),
    //       southwest: LatLng(39.9612, -82.9988), 
    //     ),
    //     32.0,
    //   )
    // );
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
      icon: _markerIcons[review['stars']],
    );
  }
}