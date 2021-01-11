import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:instacritic/instagram_repository.dart';
import 'package:instacritic/review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  final TabController tabController;
  final TextEditingController textController;
  final FocusNode searchBoxFocusNode;
  const MapScreen(this.tabController, this.textController, this.searchBoxFocusNode);
  @override _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true; // Used to keep tab alive
  Set<Marker> _markers = {};
  List<BitmapDescriptor> _markerIcons = [null,null,null,null,null];
  GoogleMapController _mapController;
  TextEditingController _mapTextController;
  FocusNode _mapFocusNode;
  
  double maxLat = -90.0, minLat =  90.0, maxLng = -180.0, minLng = 180.0;

  void _onMapCreated(GoogleMapController controller) {
    if(controller != null) {
      _mapController = controller;
      if(ModalRoute.of(context).isCurrent)
        Timer(Duration(milliseconds: 500), _updateMapBounds); 
    }
  }
  
  @override
  void initState() {
    super.initState();
    _mapTextController = TextEditingController();
    _mapFocusNode = FocusNode();
    for(int i = 0; i < _markerIcons.length; i++) { // initialize custom markers
      BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 3.5), 'assets/star-$i.png').then(
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
            if(!this.mounted || snapshot == null || snapshot.connectionState == ConnectionState.waiting ||
              !Provider.of<InstagramRepository>(context).ready || _markerIcons[4] == null) {
              return Center(child: CircularProgressIndicator());
            }
            if(this.mounted)
              _updateMarkers(snapshot);
            return Stack(
              children: [
                if(this.mounted)
                  Scaffold(
                    body: _buildGoogleMap(), // TODO: Change to MapBox
                    floatingActionButton: _buildUpdateBoundsButton(),
                  ),
                if(this.mounted)
                  _buildSearchBar(),
              ]
            );
          }
        );
      }
    );
  }
  Widget _buildSearchBar() {
    double mobileWidth = 500;
    bool isMobile = MediaQuery.of(context).size.width < mobileWidth;
    final borderRadius = BorderRadius.circular(15.0);
    return Align(
      alignment: isMobile ? Alignment.topCenter : Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(top: 15, left: isMobile ? 0 : 15),
        child: Container(
          width: isMobile ? MediaQuery.of(context).size.width - 30 : 400,
          child: Material(
            elevation: 3.0,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            child: TextField(
                focusNode: _mapFocusNode,
                controller: widget.textController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: borderRadius,
                  ),
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search',
                  contentPadding: EdgeInsets.only(top: 14),
                ),
                onTap: () async {
                  widget.tabController.animateTo(0);
                  // await Future.delayed(Duration(milliseconds: 50));
                  widget.textController.selection = TextSelection(baseOffset: 0, extentOffset: widget.textController.text.length);
                  widget.searchBoxFocusNode.requestFocus();
                },
              ),
          ),
        ),
      ),
    );
  }
  GoogleMap _buildGoogleMap() {
    return GoogleMap(
      onTap: (_) {},
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
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer(),),
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
            heroTag: 'updateBoundsButton',
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
    if(_mapController != null && this.mounted && _markers.isNotEmpty) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: ne,
            southwest: sw,
          ),
          1000.0,
        )
      );
      if(_markers.length == 1) {
        for(int i = 0; i < 5; i++)
          _mapController.animateCamera(CameraUpdate.zoomOut());    
      }
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
      title: review['restaurant_name'] + ' (${review['stars'] > 0 ? '${review['stars']}/4 ⭐' : '💀'})',
      snippet: review['gmap_address'] + '\n (Tap window to view in Google Maps)',
      onTap: () {
        String cleanedAddress = review['gmap_address'].replaceAll(RegExp(r"[!*'();:@&=+$,/?%#\[\]]"), '');
        String cleanedUrl = "https://www.google.com/maps/search/?api=1&query=$cleanedAddress&query_place_id=${review['gmap_place_id']}";
        launch(cleanedUrl, webOnlyWindowName: '_blank');
      }
    );
    return Marker(
      markerId: MarkerId(review['media_id']),
      position: LatLng(review['gmap_location'].latitude, review['gmap_location'].longitude),
      infoWindow: infoWindow,
      icon: _markerIcons[review['stars']],
    );
  }
}