import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:instacritic/instagram_repository.dart';
import 'package:instacritic/review.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  @override _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true; // Used to keep tab alive
  Set<Marker> _markers = {};
  List<BitmapDescriptor> _markerIcons = List.filled(5,null);
  GoogleMapController _mapController;
  double maxLat = -90.0, minLat =  90.0, maxLng = -180.0, minLng = 180.0;
  bool _firstRun = true;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Workaround from https://github.com/flutter/flutter/issues/34473#issuecomment-592962722
    Timer(Duration(milliseconds: 500), _updateMapBounds); 
    print(_firstRun);
    if(!_firstRun || !Provider.of<InstagramRepository>(context, listen: false).showingAll) { // TODO: UNTESTED
      Timer(Duration(milliseconds: 500), () {
        for(int i = 0; i < 8; i++)
          _mapController?.animateCamera(CameraUpdate.zoomIn());
      }); 
    }
    _firstRun = false;
  }
  
  @override
  void initState() {
    super.initState();
    for(int i = 0; i < _markerIcons.length; i++) { // initialize custom markers
      BitmapDescriptor.fromAssetImage(ImageConfiguration(), 'assets/star-$i.png').then(
        (value) => _markerIcons[i] = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: Provider.of<InstagramRepository>(context).getReviewsAsStream(),
      builder: (_, AsyncSnapshot<Stream<QuerySnapshot>> snapshot) {
        if(!snapshot.hasData || !Provider.of<InstagramRepository>(context).ready)
          return Center(child: CircularProgressIndicator());
        return StreamBuilder(
          stream: snapshot.data,
          builder: (context, snapshot) {
            if(snapshot == null || snapshot.connectionState == ConnectionState.waiting ||
              !Provider.of<InstagramRepository>(context).ready || _markerIcons[4] == null) {
              return Center(child: CircularProgressIndicator());
            }
            _updateMarkers(snapshot);
            return Scaffold(
              body: _buildGoogleMap(),
              floatingActionButton: _buildUpdateBoundsButton(),
              // floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
            );
          }
        );
      }
    );
  }

  GoogleMap _buildGoogleMap() {
    return GoogleMap(
              zoomControlsEnabled: false,
              markers: _markers,
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: LatLng(0, 0),
                zoom: 0,
              ),
              onMapCreated: _onMapCreated,
              //https://stackoverflow.com/questions/54280541/google-map-in-flutter-not-responding-to-touch-events
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                 new Factory<OneSequenceGestureRecognizer>(() => new EagerGestureRecognizer(),),
              ].toSet(),
            );
  }

  Padding _buildUpdateBoundsButton() {
    return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: FloatingActionButton(
                        onPressed: _updateMapBounds,
                        foregroundColor: Color(0xff666666),
                        backgroundColor: Colors.white,
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        child: Transform.rotate(child:Icon(Icons.control_camera, size: 33), angle: 0.785398),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                );
  }

  Future _updateMapBounds() async {
    LatLng ne = LatLng(maxLat,maxLng);
    LatLng sw = LatLng(minLat,minLng);
    if(_mapController != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: ne,
            southwest: sw,
          ),
          10.0,
        )
      );    
    }
  }

  void _updateMarkers(AsyncSnapshot<QuerySnapshot> snapshot) {
    _markers = {};
    List<Review> currReviews = Provider.of<InstagramRepository>(context, listen: false).currentReviews;
    Set<String> currMediaIds = {};
    currReviews.forEach((rev) {currMediaIds.add(rev.mediaId);});
    List<QueryDocumentSnapshot> docs = snapshot.data.docs;
    if(currMediaIds.isNotEmpty) {
      maxLat = -90.0; minLat =  90.0; maxLng = -180.0; minLng = 180.0;
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
    }
  }

  Marker _markerFromFirestoreDocSnap(Map<String, dynamic> review) {
    InfoWindow infoWindow = InfoWindow(
      title: review['restaurant_name'] + ' (${review['stars']}/4 ⭐)',
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