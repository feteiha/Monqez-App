import 'dart:async';
import 'dart:convert';
import 'package:android_intent/android_intent.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:monqez_app/Backend/Authentication.dart';
import 'package:monqez_app/Screens/Model/Helper.dart';
import 'package:monqez_app/Screens/NormalUser/BodyMap.dart';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: must_be_immutable
class HelperRequestScreen extends StatefulWidget {
  double reqLong;
  double reqLat;
  double helperLong;
  double helperLat;

  HelperRequestScreen(
      double latitude, double longitude, double helperLat, double helperLong) {
    this.reqLong = longitude;
    this.reqLat = latitude;
    this.helperLong = helperLong;
    this.helperLat = helperLat;
  }

  @override
  _HelperRequestScreenState createState() =>
      _HelperRequestScreenState(reqLong, reqLat, helperLong, helperLat);
}

class _HelperRequestScreenState extends State<HelperRequestScreen>
    with SingleTickerProviderStateMixin {
  double reqLong, reqLat, helperLong, helperLat;
  LatLng initialLatLng;
  LatLng destinationLatLng;
  TextEditingController _detailedAddress;
  TextEditingController _additionalNotes;
  TextEditingController injuryTypeController;
  TextEditingController genderController;
  Position helperLocation ;
  var _prefs;


  int bodyMapValue;
  bool forMe;
  Widget avatar;

  _HelperRequestScreenState(
      double reqLong, double reqLat, double helperLong, double helperLat) {
    this.reqLat = reqLat;
    this.reqLong = reqLong;
    this.helperLat = helperLat;
    this.helperLong = helperLong;
    // calcualteDistance() ;
  }
  // LatLng initialLatLng = LatLng(30.029585, 31.022356);
  // LatLng destinationLatLng = LatLng(30.060567, 30.962413);

  initializeSourceAndDestination() {
    setState(() {
      initialLatLng = LatLng(helperLat, helperLong);
      destinationLatLng = LatLng(reqLat, reqLong);
    });
  }

  double CAMERA_ZOOM = 16;
  double CAMERA_TILT = 40;
  double CAMERA_BEARING = 110;

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints;
  final Set<Marker> _markers = {};

  Completer<GoogleMapController> _controller = Completer();
  static CameraPosition _position1 = CameraPosition(
    bearing: 192.833,
    target: LatLng(30.029585, 31.022356),
    tilt: 59.440,
    zoom: 12.0,
  );

  @override
  void initState() {
    _detailedAddress = TextEditingController(text: "Detailed Address");
    _additionalNotes = TextEditingController(text: 'Additional Notes');
    injuryTypeController = TextEditingController(text: 'Internal or External');
    genderController = TextEditingController(text: 'Gender');
    polylinePoints = PolylinePoints();
    initializeSourceAndDestination();
    super.initState();
  }

  void showPinsOnMap() {
    _markers.add(
      Marker(
        markerId: MarkerId(initialLatLng.toString()),
        position: LatLng(initialLatLng.latitude, initialLatLng.longitude),
        infoWindow: InfoWindow(
          title: 'This is a Title',
          snippet: 'This is a snippet',
        ),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );
    print(_markers);
    _markers.add(
      Marker(
        markerId: MarkerId(destinationLatLng.toString()),
        position:
            LatLng(destinationLatLng.latitude, destinationLatLng.longitude),
        infoWindow: InfoWindow(
          title: 'This is a Title',
          snippet: 'This is a snippet',
        ),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );
  }
  // void calcualteDistance (){
  //   _placeDistance = GeolocatorPlatform.instance.distanceBetween(helperLat, helperLong, reqLat, reqLong).toStringAsFixed(2);
  // }

  void setUrl() {
    String url =
        'https://www.google.com/maps/dir/?api=1&origin=${initialLatLng.latitude},${initialLatLng.longitude} &destination=${destinationLatLng.latitude},${destinationLatLng.longitude}'
        '&travelmode=driving&dir_action=navigate';
  }

  Future<bool> getAdditionalInformation() async{
    String token = Provider.of<Helper>(context, listen: false).token;
    final http.Response response = await http.post(
        Uri.parse('$url/helper/get_additional_information/'),
        headers: <String, String> {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'uid': "trdLyxPx9XPhRANKVzfmjK5Vkuy2"}
        ));
    if (response.statusCode == 200){
      Map mp = jsonDecode(response.body);
      _additionalNotes.text = mp["Additional Notes"];
      _detailedAddress.text = mp["Address"];
      bodyMapValue = int.parse(mp["avatarBody"]);
      print(bodyMapValue);
      avatar = BodyMap.init(bodyMapValue, 200);
      return true;
    }
    else{
      print(response.statusCode);
      return false;
    }
  }
  Widget _getText(String text, double fontSize, FontWeight fontWeight,
      Color color, int lines) {
    return AutoSizeText(text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: 'Cairo',
            fontWeight: fontWeight),
        maxLines: lines);
  }

  void setPolylines() async {
    print("--------------");
    print(initialLatLng);
    print(destinationLatLng);
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyBd1Dn-iC1y3-OeYcbdHv-gWUP883X5AMg",
      PointLatLng(initialLatLng.latitude, initialLatLng.longitude),
      PointLatLng(destinationLatLng.latitude, destinationLatLng.longitude),
    );
    print(result.status);
    if (result.status == 'OK') {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
      setState(() {
        _polylines.add(Polyline(
            width: 3,
            polylineId: PolylineId('polyLine'),
            color: Color(0xFF08A5CB),
            points: polylineCoordinates));
      });
    }
  }

  Widget getTextField(TextEditingController controller) {
    return Container(
      height: 50,
        child: TextField(
      controller: controller,
      style: TextStyle(
        color: Colors.deepOrange,
        fontFamily: 'OpenSans',
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.only(top: 14.0),
      ),
    ));
  }
  void _modalBottomSheetMenu() {
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        context: context,
        builder: (builder) {
          return new Container(
            height: 300,
            color: Colors.transparent, //could change this to Color(0xFF737373),
            //so you don't have to change MaterialApp canvasColor
            child: new Container(
                decoration: new BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(20))),

                child: ListView(
                  shrinkWrap: true,

                  children: [
                    SizedBox(height: 200, child: avatar),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 250, child: BodyMap()),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 4,),
                                Container(
                                  height: 25 ,
                                  width: 115,
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child:Center(
                                    child: _getText('Detailed Address', 15, FontWeight.normal,
                                        Colors.white, 1),
                                  ),
                                ),
                                SizedBox(width: 8,) ,
                                _getText(_detailedAddress.text, 15, FontWeight.normal, Colors.black, 1)
                              ],
                            ),
                          ),
                          SizedBox(height: 4,),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 4,),
                                Container(
                                  height: 25 ,
                                  width: 115,
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child:Center(
                                    child: _getText('Additional Notes', 15, FontWeight.normal,
                                        Colors.white, 1),
                                  ),
                                ),
                                SizedBox(width: 8,),
                                _getText(_additionalNotes.text, 15, FontWeight.normal, Colors.black, 1)
                              ],
                            ),
                          ),
                          //SizedBox(height: 4,),
                          SizedBox(height: 4,),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 4,),
                                Container(
                                  height: 25 ,
                                  width: 115,
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child:Center(
                                    child: _getText('Injury Type', 15, FontWeight.normal,
                                        Colors.white, 1),
                                  ),
                                ),
                                SizedBox(width: 8,),
                                _getText(injuryTypeController.text, 15, FontWeight.normal, Colors.black, 1)
                              ],
                            ),
                          ),
                          SizedBox(height: 4,) ,
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 4,),
                                Container(
                                  height: 25 ,
                                  width: 115,
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child:Center(
                                    child: _getText('Gender', 15, FontWeight.normal,
                                        Colors.white, 1),
                                  ),
                                ),
                                SizedBox(width: 8,),
                                _getText(genderController.text, 15, FontWeight.normal, Colors.black, 1)
                              ],
                            ),
                          ),
                          SizedBox(height: 4,),
                        ],
                      )
                    ],
                  ),
                )),
          );
        });
  }

  _launch() {
    AndroidIntent intent = new AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull(
            'https://www.google.com/maps/dir/?api=1&origin=${initialLatLng.latitude},${initialLatLng.longitude} &destination=${destinationLatLng.latitude},${destinationLatLng.longitude}'
            '&travelmode=driving&dir_action=navigate'),
        package: 'com.google.android.apps.maps');
    intent.launch();
  }
  _getCurrentUserLocation() async {
    helperLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
  Future<void> _completeRequest() async {
    await _getCurrentUserLocation();
    _prefs = await SharedPreferences.getInstance();
    String tempToken  = _prefs.getString("userToken");

    final http.Response response = await http.post(
      Uri.parse('$url/helper/complete_request/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $tempToken',
      },
      body: jsonEncode(<String, double>{
        'latitude': helperLocation.latitude,
        'longitude': helperLocation.longitude
      }),
    );
    if (response.statusCode == 200) {
      makeToast("Submitted");
    } else if (response.statusCode == 503) {
      makeToast("No Available Monqez");
    } else {
      makeToast('Failed to submit user.');
    }
  }
  Future<void> _cancelRequest() async {
    await _getCurrentUserLocation();
    _prefs = await SharedPreferences.getInstance();
    String tempToken  = _prefs.getString("userToken");

    final http.Response response = await http.post(
      Uri.parse('$url/helper/cancel_request/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $tempToken',
      },

    );
    if (response.statusCode == 200) {
      makeToast("Submitted");
    } else if (response.statusCode == 503) {
      makeToast("No Available Monqez");
    } else {
      makeToast('Failed to submit user.');
    }
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialCameraPosition = CameraPosition(
      zoom: CAMERA_ZOOM,
      tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
      target: initialLatLng,
    );
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Container(
        height: height,
        width: width,
        child: Scaffold(
          body: Stack(
            children: <Widget>[
              // Map View
              GoogleMap(
                markers: _markers,
                initialCameraPosition: _position1,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: false,
                polylines: _polylines,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  showPinsOnMap();
                  setPolylines();
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: width,
                  height: 90,
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        width: 100,
                        height: 50,
                        decoration: BoxDecoration(color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(30.0)),
                        child: FlatButton(
                          color: Colors.transparent,
                          splashColor: Colors.black26,
                          onPressed: () {
                            _launch();
                          },
                          child: _getText(
                              'Navigate', 14, FontWeight.w700, Colors.white, 1),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(30.0)),
                        child: FlatButton(
                          color: Colors.transparent,
                          splashColor: Colors.black26,
                          onPressed: () async {
                           _completeRequest() ;
                          },
                          child: _getText(
                              'Complete', 14, FontWeight.w700, Colors.white, 1),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 50,
                        decoration: BoxDecoration(color: Colors.red ,
                            borderRadius: BorderRadius.circular(30.0) ),
                        child: FlatButton(
                          color: Colors.transparent,
                          splashColor: Colors.black26,
                          onPressed: () {
                            _cancelRequest();
                          },
                          child: _getText(
                              'Cancel', 14, FontWeight.w700, Colors.white, 1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 50,
                          height: 50,
                          child: FlatButton(
                              color: Colors.transparent,
                              splashColor: Colors.black26,
                              onPressed: () async{
                                await getAdditionalInformation();
                                _modalBottomSheetMenu();
                              },
                              child: Icon(Icons.info,
                              color: Colors.blueAccent)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }
}