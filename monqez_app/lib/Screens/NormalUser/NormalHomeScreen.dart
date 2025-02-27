import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:monqez_app/Backend/FirebaseCloudMessaging.dart';
import 'package:monqez_app/Backend/NotificationRoutes/NormalUserNotification.dart';
import 'package:monqez_app/Backend/NotificationRoutes/NotificationRoute.dart';
import 'package:flutter/material.dart';
import 'package:monqez_app/Screens/InstructionsScreens/InstructionsScreen.dart';
import 'package:monqez_app/Models/User.dart';
import 'package:monqez_app/Screens/NormalUser/BodyMap.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Backend/Authentication.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monqez_app/Screens/Utils/MaterialUI.dart';
import 'package:monqez_app/Screens/AllUsers/Profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import '../Calls/VideoPage.dart';
import '../Authentication/LoginScreen.dart';
import '../Calls/VoicePage.dart';
import 'Chatbot.dart';
import 'NormalUserPreviousRequests.dart';
import 'package:provider/provider.dart';
import 'package:monqez_app/Models/Normal.dart';

// ignore: must_be_immutable
class NormalHomeScreen extends StatefulWidget {
  String token;
  NormalHomeScreen(this.token);
  @override
  _NormalHomeScreenState createState() => _NormalHomeScreenState(token);
}

class Item {
  const Item(this.name);
  final String name;
}

class _NormalHomeScreenState extends State<NormalHomeScreen>
    with SingleTickerProviderStateMixin {
  bool firstTimeLocation = true;
  static User user;

  List<Icon> icons;
  var _detailedAddress = TextEditingController();
  var _aditionalNotes = TextEditingController();
  var _additionalInfoController = TextEditingController();
  BodyMap avatar;
  bool isLoaded = false;
  bool _locationLoaded = false;
  bool _dataLoaded = false;

  int firstStatusCode;
  final _drawerKey = GlobalKey<ScaffoldState>();

  _NormalHomeScreenState(String token) {
    Future.delayed(Duration.zero, () async {
      user = new User.empty();
      user.setToken(token);
      await user.getUser();
      setState(() {
        _dataLoaded = true;
      });
    });
  }
  Animation<double> animation;
  AnimationController controller;
  GoogleMapController mapController;

  Marker _marker;
  MapType _currentMapType = MapType.normal;
  Position _newUserPosition;
  bool _radioValue;

  static CameraPosition _position1;

  Future<void> _goToPosition1() async {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(_position1),
    );
    showPinsOnMap();
    setState(() {});
  }

  showPinsOnMap() {
    _marker = Marker(
      markerId: MarkerId(_newUserPosition.toString()),
      position: LatLng(_newUserPosition.latitude, _newUserPosition.longitude),
      draggable: true,
      onDragEnd: ((newPosition) {}),
      icon: BitmapDescriptor.defaultMarker,
    );
  }

  void _sendAdditionalInformation() async {
    String tempToken = user.token;
    Map<String, dynamic> body = {
      'additionalInfo': {
        'Address': _detailedAddress.text,
        'Additional Notes': _aditionalNotes.text,
        'avatarBody': avatar.getSelected().toString(),
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
    String tempToken = user.token;
    final http.Response response = await http.post(
      Uri.parse('$url/user/request/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $tempToken',
      },
      body: jsonEncode(<String, double>{
        'latitude': _marker.position.latitude,
        'longitude': _marker.position.longitude
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

  Future<void> _cancelRequest() async {
    await _getCurrentUserLocation();
    String tempToken = user.token;
    final http.Response response = await http.post(
      Uri.parse('$url/user/cancel_request/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $tempToken',
      },
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
                  borderRadius: BorderRadius.circular(20.0)),
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
                      SizedBox(height: 400, child: avatar),
                      SizedBox(
                        width: 200,
                        // ignore: deprecated_member_use
                        child: RaisedButton(
                          onPressed: () {
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

  _showMaterialDialog([String notes = ""]) {
    _aditionalNotes.clear();
    _detailedAddress.clear();
    _aditionalNotes.text = notes;
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
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
                                // ignore: deprecated_member_use
                                child: RaisedButton(
                                  onPressed: () {
                                    _showAvatar();
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
                                // ignore: deprecated_member_use
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


  _getCurrentUserLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      _newUserPosition = position;
      _position1 = CameraPosition(
          target: LatLng(_newUserPosition.latitude, _newUserPosition.longitude),
          zoom: 17.0);
      setState(() {
        // to check if that step is valid or not
        _locationLoaded = true;
      });
    }).catchError((e) {
      navigate(LoginScreen(), context, true);
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

  @override
  void initState() {
    super.initState();
    avatar = BodyMap();
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
    if (!_locationLoaded || !_dataLoaded) {
      if (firstTimeLocation) {
        firstTimeLocation = false;
        Future.delayed(Duration.zero, () async {
          await _getCurrentUserLocation();
          showPinsOnMap();
        });
      }
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
      var provider = Provider.of<Normal>(context, listen: true);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
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
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.video_call,
                  color: Colors.white,
                ),
                onPressed: () {
                  _showCallDialog("video");
                },
              )
            ],
          ),
          drawer: Drawer(
            key: _drawerKey,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  child: Container(
                      alignment: Alignment.centerLeft,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            getTitle(user.name, 26, secondColor,
                                TextAlign.start, true),
                            Container(
                              width: 90,
                              height: 90,
                              child: CircularProfileAvatar(
                                null,
                                child: user.image == null
                                    ? Icon(Icons.account_circle_rounded,
                                        size: 90, color: secondColor)
                                    : Image.memory(user.image.decode()),
                                radius: 100,
                                backgroundColor: Colors.transparent,
                                borderColor: user.image == null
                                    ? firstColor
                                    : secondColor,
                                elevation: 5.0,
                                cacheImage: true,
                                onTap: () {},
                              ),
                            ),
                          ])),
                  decoration: BoxDecoration(
                    color: firstColor,
                  ),
                ),
                Container(
                  color: secondColor,
                  height: (MediaQuery.of(context).size.height) - 200,
                  child: Column(children: [
                    Visibility(
                      visible: user.name != "One Time Request",
                      child: ListTile(
                        title: getTitle('My Profile', 18, firstColor,
                            TextAlign.start, true),
                        leading: Icon(Icons.account_circle_rounded,
                            size: 30, color: firstColor),
                        onTap: () {
                          Navigator.pop(_drawerKey.currentContext);
                          navigate(ProfileScreen(user), context, false);
                        },
                      ),
                    ),
                    Visibility(
                      visible: user.name != "One Time Request",
                      child: ListTile(
                        title: getTitle('My Requests', 18, firstColor,
                            TextAlign.start, true),
                        leading:
                            Icon(Icons.history, size: 30, color: firstColor),
                        onTap: () {
                          Navigator.pop(_drawerKey.currentContext);
                          navigate(
                              NormalPreviousRequests(user), context, false);
                        },
                      ),
                    ),
                    ListTile(
                      title: getTitle('Emergency Instructions', 18, firstColor,
                          TextAlign.start, true),
                      leading: Icon(Icons.help_center_outlined,
                          size: 30, color: firstColor),
                      onTap: () {
                        Navigator.pop(_drawerKey.currentContext);
                        navigate(InstructionsScreen(false, user.token), context,
                            false);
                      },
                    ),
                    ListTile(
                      title: getTitle(
                          'Chatbot', 18, firstColor, TextAlign.start, true),
                      leading: Icon(Icons.chat_bubble_outline_rounded,
                          size: 30, color: firstColor),
                      onTap: () {
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ChatbotScreen(user.token)))
                            .then((returned) {
                          Navigator.pop(_drawerKey.currentContext);

                          if (returned == null) return;

                          if (returned[0] == "request") {
                            String notes;
                            if (returned.length == 2) {
                              notes = returned[1];
                            }
                            _makeRequest().then((value) {
                              if (firstStatusCode == 200)
                                _showMaterialDialog(notes);
                            });
                          } else if (returned[0] == "voice") {
                            _showCallDialog("voice");
                            if (returned.length == 2) {
                              String notes = returned[1];
                              setState(() {
                                _additionalInfoController.text = notes;
                              });
                            }
                          } else if (returned[0] == "video") {
                            _showCallDialog("video");
                            if (returned.length == 2) {
                              String notes = returned[1];
                              setState(() {
                                _additionalInfoController.text = notes;
                              });
                            }
                          } else if (returned[0] == "instructions") {
                            navigate(InstructionsScreen(false, user.token),
                                context, false);
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 40,
                          width: 120,
                          // ignore: deprecated_member_use
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
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                },
                initialCameraPosition: _position1,
                mapType: _currentMapType,
                markers: {_marker},
                compassEnabled: true,
                tiltGesturesEnabled: false,
                onLongPress: (latlang) {
                  _addMarkerLongPressed(latlang);
                  setState(() {});
                },
              ),
              Visibility(
                visible: provider.visible[0],
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      // ignore: deprecated_member_use
                      child: RaisedButton(
                        onPressed: () async {
                          await _makeRequest();
                          if (firstStatusCode == 200) {
                            _showMaterialDialog();
                            provider.visible[0] = !provider.visible[0];
                            provider.visible[1] = !provider.visible[1];
                            setState(() {});
                          }
                        },
                        child: Text('Get Help!'),
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: provider.visible[1],
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      // ignore: deprecated_member_use
                      child: RaisedButton(
                        onPressed: () async {
                          await _cancelRequest();
                          provider.visible[0] = !provider.visible[0];
                          provider.visible[1] = !provider.visible[1];
                          setState(() {});
                        },
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.black)),
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: provider.visible[2],
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 4,
                            offset: Offset(4, 8),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      width: 220,
                      height: 100,
                      // ignore: deprecated_member_use
                      child: Column(children: [
                        SizedBox(
                          height: 15,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 8,
                              ),
                              Container(
                                height: 30,
                                width: 110,
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange,
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: Center(
                                  child: _getText('Monqez Name', 14,
                                      FontWeight.bold, Colors.black, 1),
                                ),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              _getText(provider.helperName, 14, FontWeight.bold,
                                  Colors.black, 1),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 6,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 8,
                              ),
                              Container(
                                height: 30,
                                width: 110,
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange,
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: Center(
                                  child: _getText('Phone Number', 14,
                                      FontWeight.bold, Colors.black, 1),
                                ),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              GestureDetector(
                                onTap: () {
                                  _launchCaller(provider.helperPhone);
                                },
                                child: _getText(provider.helperPhone, 10,
                                    FontWeight.bold, Colors.black, 1),
                              ),
                            ],
                          ),
                        ),
                      ]),
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

  _launchCaller(String number) async {
    String url = "tel:$number";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    await permission.request();
  }

  Future<void> onJoin(String type) async {
    if (type == "video") await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    String token = user.token;
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
      channelID = response.body;
    } else {
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
            )).then((value) => Navigator.pop(context));
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoicePage(
                channelName: channelID,
                userType: "normal",
              ),
            )).then((value) => Navigator.pop(context));
      }
    }
  }

  Future _addMarkerLongPressed(LatLng latlang) async {
    _marker = Marker(
      markerId: MarkerId(_newUserPosition.toString()),
      position: latlang,
      draggable: true,
      onDragEnd: ((newPosition) {}),
      icon: BitmapDescriptor.defaultMarker,
    );
  }

  _showCallDialog(String type) {
    _additionalInfoController.clear();
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
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
                        "Call Additional Information",
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
                                // ignore: deprecated_member_use
                                child: RaisedButton(
                                  onPressed: () {
                                    if (_additionalInfoController
                                        .text.isEmpty) {
                                      _additionalInfoController.text = " ";
                                    }
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
