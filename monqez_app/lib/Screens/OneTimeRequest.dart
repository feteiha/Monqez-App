import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:monqez_app/Backend/FirebaseCloudMessaging.dart';
import 'package:monqez_app/Backend/NotificationRoutes/NormalUserNotification.dart';
import 'package:monqez_app/Backend/NotificationRoutes/NotificationRoute.dart';
import 'package:flutter/material.dart';
import 'package:monqez_app/Screens/NormalUser/BodyMap.dart';
import '../../Backend/Authentication.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monqez_app/Screens/Utils/MaterialUI.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Instructions/InstructionsScreen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'CallPage.dart';
import 'LoginScreen.dart';
import 'VoicePage.dart';

// ignore: must_be_immutable
class OneTimeRequestScreen extends StatefulWidget {
  String token;
  String uid;
  OneTimeRequestScreen(String uid, String token) {
    this.uid = uid;
    this.token = token;
  }

  @override
  _OneTimeRequestScreenState createState() =>
      _OneTimeRequestScreenState(uid, token);
}

class Item {
  const Item(this.name);
  final String name;
}

class _OneTimeRequestScreenState extends State<OneTimeRequestScreen>
    with SingleTickerProviderStateMixin {
  List<Icon> icons;
  bool _isLoading = true;
  var _detailedAddress = TextEditingController();
  var _aditionalNotes = TextEditingController();
  var _additionalInfoController = TextEditingController();
  String uid;
  String token;
  int bodyMap;
  bool isLoaded = false;
  int firstStatusCode;
  _OneTimeRequestScreenState(String uid, String token) {
    this.uid = uid;
    this.token = token;
  }
  Animation<double> animation;
  AnimationController controller;

  Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  MapType _currentMapType = MapType.normal;
  Position _newUserPosition;
  bool _radioValue;
  var _nameController = TextEditingController();

  List<Item> users = <Item>[
    const Item('Very dangerous'),
    const Item('Dangerous'),
    const Item('Normal'),
  ];

  static CameraPosition _position1;

  Future<void> _goToPosition1() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_position1));
  }

  showPinsOnMap() {
    print(_newUserPosition);
    _markers.add(
      Marker(
        markerId: MarkerId(_newUserPosition.toString()),
        position: LatLng(_newUserPosition.latitude, _newUserPosition.longitude),
        infoWindow: InfoWindow(
          title: 'This is a Title',
          snippet: 'This is a snippet',
        ),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );
  }

  _onMapCreated(GoogleMapController controller) async {
    print(_position1);
    await _getCurrentUserLocation();
    await _goToPosition1();
    _controller.complete(controller);
    setState(() {
      _position1 = CameraPosition(
          bearing: 192.833,
          target: LatLng(_newUserPosition.latitude, _newUserPosition.longitude),
          tilt: 59.440,
          zoom: 11.0);
      ;
    });
  }

  void _sendAdditionalInformation() async {
    String tempToken = token;
    Map<String, dynamic> body = {
      'additionalInfo': {
        'Address': _detailedAddress.text,
        'Additional Notes': _aditionalNotes.text,
        'avatarBody': bodyMap.toString(),
        'forMe': _radioValue.toString()
      },
    };
    final http.Response response = await http.post(
      Uri.parse('$url/user/request_information/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $tempToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      makeToast("Submitted");
    } else {
      makeToast('Failed to submit user.');
    }
  }

  Future<void> _makeRequest() async {
    await _getCurrentUserLocation();
    String tempToken = token;
    final http.Response response = await http.post(
      Uri.parse('$url/user/request/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $tempToken',
      },
      body: jsonEncode(<String, double>{
        'latitude': _newUserPosition.latitude,
        'longitude': _newUserPosition.longitude
      }),
    );
    firstStatusCode = response.statusCode;
    if (response.statusCode == 200) {
      makeToast("Submitted");
    } else if (response.statusCode == 503) {
      makeToast("No Available Monqez");
    } else {
      makeToast('Failed to submit user.');
    }
  }

  void _showAvatar() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)), //this right here
              child: Container(
                height: 550,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.0, 24.0, 12.0, 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                          child: Text(
                        "Injuries",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      )),
                      SizedBox(height: 20),
                      SizedBox(height: 400, child: BodyMap()),
                      SizedBox(
                        width: 200,
                        child: RaisedButton(
                          onPressed: () {
                            bodyMap = BodyMap.getSelected();
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "Done",
                            style: TextStyle(color: Colors.white),
                          ),
                          color: Colors.deepOrange,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  _showMaterialDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)), //this right here
              child: Container(
                height: 400,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Text(
                        "Additional details",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      )),
                      SizedBox(height: 20),
                      // Container(
                      //   child :Row(
                      //     children: [
                      //       Text("Severity  ") ,
                      //       DropdownButton<Item>(
                      //         hint: Text("Select item"),
                      //         value: _selectedSeviirty,
                      //         onChanged: (Item value) {
                      //           setState(() {
                      //             _selectedSeviirty = value;
                      //             print(_selectedSeviirty.name) ;
                      //           });
                      //         },
                      //         items: users.map((Item user) {
                      //           return  DropdownMenuItem<Item>(
                      //             value: user,
                      //             child: Row(
                      //               children: <Widget>[
                      //                 SizedBox(width: 10,),
                      //                 Text(
                      //                   user.name,
                      //                   style:  TextStyle(color: Colors.black),
                      //                 ),
                      //               ],
                      //             ),
                      //           );
                      //         }).toList(),
                      //       ),
                      //     ],
                      //   ),
                      // ),

                      Container(
                        child: Row(
                          children: [
                            Text("For Me"),
                            Radio(
                              value: true,
                              groupValue: _radioValue,
                              onChanged: (value) {
                                setState(() {
                                  _radioValue = value;
                                  print(_radioValue);
                                });
                              },
                            ),
                            Text("For Other"),
                            Radio(
                              value: false,
                              groupValue: _radioValue,
                              onChanged: (value) {
                                setState(() {
                                  _radioValue = value;
                                  print(_radioValue);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      TextField(
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Your detailed address ?'),
                        controller: _detailedAddress,
                      ),
                      TextField(
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Notes for your coming monqez ?'),
                        controller: _aditionalNotes,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 200,
                                child: RaisedButton(
                                  onPressed: () {
                                    _showAvatar();
                                    //Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    "Show Avatar",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  color: Colors.deepOrange,
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: RaisedButton(
                                  onPressed: () {
                                    _sendAdditionalInformation();
                                    Navigator.of(context).pop();
                                    navigate(
                                        InstructionsScreen(), context, false);
                                  },
                                  child: Text(
                                    "Submit",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  _getCurrentUserLocation() async {
    Position _newPosition;
    _newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _newUserPosition = _newPosition;
    _position1 = CameraPosition(
        bearing: 192.833,
        target: LatLng(_newUserPosition.latitude, _newUserPosition.longitude),
        tilt: 59.440,
        zoom: 11.0);
    _isLoading = false;
    setState(() {});
    print("heeeeeeere");
    print(_newPosition);
  }

  _onAddMarkerButtonPressed() async {
    await _getCurrentUserLocation();
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(_newUserPosition.toString()),
          position:
              LatLng(_newUserPosition.latitude, _newUserPosition.longitude),
          infoWindow: InfoWindow(
            title: 'This is a Title',
            snippet: 'This is a snippet',
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  Widget button(Function function, IconData icon, String hero) {
    return FloatingActionButton(
      heroTag: hero,
      onPressed: function,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      backgroundColor: Colors.deepOrangeAccent,
      child: Icon(
        icon,
        size: 36.0,
      ),
    );
  }

  Widget _buildBtn(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: RaisedButton(
        elevation: 5.0,
        onPressed: () {
          logout();
          Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 500),
                  transitionsBuilder:
                      (context, animation, animationTime, child) {
                    return SlideTransition(
                      position: Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
                          .animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.ease,
                      )),
                      child: child,
                    );
                  },
                  pageBuilder: (context, animation, animationTime) {
                    return LoginScreen();
                  }));
        },
        padding: EdgeInsets.all(15.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        color: Colors.white,
        child: Text(text,
            style: TextStyle(
                color: Colors.deepOrange,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    bodyMap = 0;
    //showPinsOnMap() ;
    _radioValue = true;
    controller = new AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this);
    animation = new Tween(begin: 0.0, end: 200.0).animate(controller);
    animation.addListener(() {
      setState(() {
        //The state of the animation has changed
      });
    });

    controller.forward();
  }

  void checkNotification(BuildContext context) async {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage message) {
      if (message != null) {
        FirebaseCloudMessaging.route =
            new NormalUserNotification(message, true);
        navigate(NotificationRoute.selectNavigate, context, false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      checkNotification(context);
      isLoaded = true;
    }
    if (_isLoading) {
      _getCurrentUserLocation();
      return Scaffold(
          backgroundColor: secondColor,
          body: Container(
              height: double.infinity,
              alignment: Alignment.center,
              child: SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                      backgroundColor: secondColor,
                      strokeWidth: 5,
                      valueColor:
                          new AlwaysStoppedAnimation<Color>(firstColor)))));
    } else {
      showPinsOnMap();

      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: getTitle("Monqez", 22.0, secondColor, TextAlign.start, true),
            shadowColor: Colors.black,
            backgroundColor: firstColor,
            iconTheme: IconThemeData(color: secondColor),
            elevation: 5,
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.call,
                  color: Colors.white,
                ),
                onPressed: () {
                  _showCallDialog("voice");
                }
                // do something
                ,
              ),
              IconButton(
                icon: Icon(
                  Icons.video_call,
                  color: Colors.white,
                ),
                onPressed: () {
                  _showCallDialog("video");
                }
                // do something
                ,
              )
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  color: secondColor,
                  height: (MediaQuery.of(context).size.height) - 200,
                  child: Column(children: [
                    ListTile(
                      title: getTitle('Instructions', 18, firstColor,
                          TextAlign.start, true),
                      leading: Icon(Icons.account_circle_rounded,
                          size: 30, color: firstColor),
                      onTap: () {
                        //Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 40,
                          width: 120,
                          child: RaisedButton(
                              elevation: 5.0,
                              onPressed: () {
                                logout();
                                navigate(LoginScreen(), context, true);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              color: firstColor,
                              child: getTitle("Logout", 18, secondColor,
                                  TextAlign.start, true)),
                        ),
                      ),
                    )
                  ]),
                ),
              ],
            ),
          ),
          body: Stack(
            children: <Widget>[
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: _position1,
                mapType: _currentMapType,
                markers: _markers,
              ),
              /*SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SearchMapPlaceWidget(
                  hasClearButton: true,
                  placeType: PlaceType.address,
                  placeholder: "Enter the location",
                  apiKey: 'AIzaSyD3bOWy1Uu61RerNF9Mam9Ieh-0z4PDYPo',
                  onSelected: (Place place) async {
                    Geolocation geoLocation = await place.geolocation;
                  },
                ),
              ),*/
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 200,
                    height: 50,
                    child: RaisedButton(
                      onPressed: () async {
                        //_createPolylines();
                        await _makeRequest();
                        if (firstStatusCode == 200) _showMaterialDialog();
                      },
                      child: Text('Get Help!'),
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Column(
                    children: <Widget>[
                      button(_onMapTypeButtonPressed, Icons.map, 'map'),
                      SizedBox(
                        height: 16.0,
                      ),
                      button(
                          _goToPosition1, Icons.location_searching, 'position'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  Future<void> onJoin(String type) async {
    if (type == "video") await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    String channelID;

    final http.Response response = await http.post(Uri.parse('$url/user/call/'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'data': _additionalInfoController.text,
          'type': type
        }));

    if (response.statusCode == 200) {
      //var parsed = jsonDecode(response.body).cast<String, dynamic>();
      channelID = response.body;
    } else {
      print(response.statusCode);
      return;
    }
    if (channelID != null) {
      if (type == "video") {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallPage(
                channelName: channelID,
                userType: "normal",
              ),
            ));
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoicePage(
                channelName: channelID,
                userType: "normal",
              ),
            ));
      }
    }
    /*
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VoicePage(channelName: "channelID"),
        ));
        */
  }

  _showCallDialog(String type) {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)), //this right here
              child: Container(
                height: 200,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Text(
                        "Additional Information",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      )),
                      SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Additional Information'),
                        controller: _additionalInfoController,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 200,
                                child: RaisedButton(
                                  onPressed: () {
                                    if (_additionalInfoController
                                        .text.isEmpty) {
                                      makeToast(
                                          "Please enter additional information");
                                    } else
                                      onJoin(type);
                                  },
                                  child: Text(
                                    "Submit",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }
}