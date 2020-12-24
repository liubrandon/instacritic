import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:instacritic/instagram_repository.dart';
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
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/marker.png').then((onValue) {
        pinLocationIcon = onValue;
      });
    LatLng steamedPos = LatLng(41.3126, -72.9218);
    _markers.add(Marker(
      markerId: MarkerId('Steamed'),
      position: steamedPos,
      icon: pinLocationIcon,
      ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(41.3163, -72.9223),
      zoom: 14.4746,
    );

    return WillPopScope(
      onWillPop: () async => false,
      child: GoogleMap(
        markers: _markers,
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}