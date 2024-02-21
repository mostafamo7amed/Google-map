import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapsView extends StatefulWidget {
  const MapsView({super.key});

  @override
  State<MapsView> createState() => _MapsViewState();
}

class _MapsViewState extends State<MapsView> {
  @override
  void initState() {
    super.initState();
    _getLocationUpdate().then((_) => getPolylinePoints().then((coordinates) {
          generatePolylineFromPoint(coordinates);
        }));
  }

  final _locationController = Location();
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();

  LatLng pointOne = const LatLng(37.4223, -122.0848);
  LatLng pointTwo = const LatLng(37.3346, -122.0090);
  LatLng? currentposition;
  Map<PolylineId, Polyline> polylines = {};

  @override
  Widget build(BuildContext context) {
    return currentposition == null
        ? const Center(
            child: Text('Loading...'),
          )
        : GoogleMap(
            onMapCreated: (controller) => mapController.complete(controller),
            mapType: MapType.terrain,
            myLocationEnabled: true,
            initialCameraPosition: CameraPosition(
              target: pointOne,
              zoom: 13,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('currentLocation'),
                icon: BitmapDescriptor.defaultMarker,
                position: currentposition!,
              ),
              Marker(
                markerId: const MarkerId('sourceLocation'),
                icon: BitmapDescriptor.defaultMarker,
                position: pointOne,
              ),
              Marker(
                markerId: const MarkerId('distinationLocation'),
                icon: BitmapDescriptor.defaultMarker,
                position: pointTwo,
              ),
            },
            polylines: Set<Polyline>.of(polylines.values),
          );
  }

  Future cameraToPoistion(LatLng pos) async {
    final GoogleMapController controller = await mapController.future;
    CameraPosition newCameraPos = CameraPosition(
      target: pos,
      zoom: 13,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPos),
    );
  }

  Future _getLocationUpdate() async {
    bool serviceEnabled;
    PermissionStatus premissionGranted;
    serviceEnabled = await _locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    premissionGranted = await _locationController.hasPermission();
    if (premissionGranted == PermissionStatus.denied) {
      premissionGranted = await _locationController.requestPermission();
      if (premissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          currentposition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          cameraToPoistion(currentposition!);
        });
      }
    });
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGAL_MAP_KAY,
      PointLatLng(pointOne.latitude, pointOne.longitude),
      PointLatLng(pointTwo.latitude, pointTwo.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    return polylineCoordinates;
  }

  void generatePolylineFromPoint(List<LatLng> polylineCoordinates) async {
    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );
    setState(() {
      polylines[id] = polyline;
    });
  }
}
