import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main(){

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String locationMessage = "Waiting for location";
  late String lat;
  late String long;
  int counter = 0;

  Future<Position> _getCurrentLocation() async {
    bool locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationServiceEnabled){
      return Future.error("Location services are disabled!");
    }

    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied){
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied){
        return Future.error("Location permissions are denied!");
      }
    }

    if (locationPermission == LocationPermission.deniedForever){
      return Future.error("Location permissions are PERMANENTLY denied! Cannot request one more time.");
    }

    return await Geolocator.getCurrentPosition();
  }


  void _liveLocation(){
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // 1 metr
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      lat = position.latitude.toString();
      long = position.longitude.toString();

      setState(() {
        locationMessage = 'Latitude: $lat, Longitude: $long';
        _saveToShared(lat, long);
      });
    });
  }

  Future<void> _openMap(String lat, String long) async {
    String googleURL =
        'https://www.google.com/maps/search/?api=1&query=$lat,$long';

    await canLaunchUrlString(googleURL)
        ? await launchUrlString(googleURL)
        : throw 'cannot launch $googleURL';
  }

  void _saveToShared(String lat, String long) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('$counter', '$lat   $long');
    counter++;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Location Tracking'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              locationMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _getCurrentLocation().then((value) {
                  lat = '${value.latitude}';
                  long = '${value.longitude}';
                  setState(() {
                    locationMessage = 'Latitude: $lat, Longitude: $long';
                  });
                  _liveLocation();
                });
              },
              child: const Text("Get current location"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  _openMap(lat, long);
                },
                child: const Text("Open in Google Maps")),
          ],
        ),
      ),
    );
  }
}
