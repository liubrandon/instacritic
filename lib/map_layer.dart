import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gradient_colors/flutter_gradient_colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instacritic/review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'instagram_repository.dart';

class MapLayer extends StatefulWidget {
  @override
  _MapLayerState createState() => _MapLayerState();
}

class _MapLayerState extends State<MapLayer> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true; // Used to keep tab alive
  Set<Marker> _markers = {};
  List<BitmapDescriptor> _markerIcons = [null,null,null,null,null];
  GoogleMapController _mapController;
  InstagramRepository igRepository;
  double maxLat = -90.0, minLat =  90.0, maxLng = -180.0, minLng = 180.0;
  bool isMobile;
  @override
  void initState() {
    super.initState();
    for(int i = 0; i < _markerIcons.length; i++) { // initialize custom markers
      BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 3.5), 'assets/star-$i.png').then(
        (value) => _markerIcons[i] = value);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if(controller != null) {
      _mapController = controller;
      if(ModalRoute.of(context).isCurrent) {
        Timer(Duration(milliseconds: 250), _updateMapBounds); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    isMobile = MediaQuery.of(context).size.width < Constants.mobileWidth;
    igRepository = Provider.of<InstagramRepository>(context,listen:false);
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Scaffold(
        body: FutureBuilder(
          future: igRepository.getReviewsAsStream(),
          builder: (_, AsyncSnapshot<Stream<QuerySnapshot>> snapshot) {
            if(!snapshot.hasData || !Provider.of<InstagramRepository>(context).ready)
              return Center(child: CircularProgressIndicator());
            return StreamBuilder(
            stream: snapshot.data,
            builder: (context, snapshot) {
              if(!this.mounted || snapshot == null || snapshot.connectionState == ConnectionState.waiting ||
                !igRepository.ready || _markerIcons[4] == null) {
                  return Center(child: CircularProgressIndicator());
                }
                if(this.mounted)
                  _updateMarkers(snapshot);
                return _buildGoogleMap();
              }
            );
          }
        ),
        floatingActionButton: _buildUpdateBoundsButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      onTap: (_) {},
      zoomControlsEnabled: false,
      markers: _markers,
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: LatLng(0, 0),
        zoom: isMobile ? 0 : 1,
      ),
      onMapCreated: _onMapCreated,
    );
  }

  void _updateMarkers(AsyncSnapshot<QuerySnapshot> snapshot) {
    _markers = {};
    List<Review> currReviews = Provider.of<InstagramRepository>(context,listen: false).currentReviews;
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
  
  Padding _buildUpdateBoundsButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom:38),
      child: SizedBox(
        width: 90,
        height: 35,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: GradientColors.purplePink,
          )),
          child: FloatingActionButton.extended(
              heroTag: 'updateBoundsButton',
              onPressed: _updateMapBounds,
              backgroundColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              label: Text('Recenter', style: TextStyle(color: Colors.white, fontSize: 15, letterSpacing: .5)),
            ),
        ),
        ),
    );
  }

  Future _updateMapBounds() async {
    LatLng ne = LatLng(maxLat,maxLng);
    LatLng sw = LatLng(minLat,minLng);
    try {
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
        _mapController.animateCamera(CameraUpdate.zoomOut());
        if(_markers.length == 1) {
          for(int i = 0; i < 4; i++)
            _mapController.animateCamera(CameraUpdate.zoomOut());    
        }
      }
    } catch(e) {
      print('Update bounds failed');
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