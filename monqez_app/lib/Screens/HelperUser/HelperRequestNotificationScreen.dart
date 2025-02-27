import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monqez_app/Screens/HelperUser/HelperHomeScreen.dart';
import 'package:monqez_app/Screens/Utils/MaterialUI.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Backend/Authentication.dart';
import 'package:http/http.dart' as http;
import '../../main.dart';
import 'HelperRequestScreen.dart';
import '../../Models/Helper.dart';

// ignore: must_be_immutable
class HelperRequestNotificationScreen extends StatelessWidget {

  static String requestID;
  static double reqLongitude;
  static double reqLatitude;
  String phone ;
  var _prefs;
  String token;
  Position helperLocation ;


  Future<void> decline(BuildContext context) async {
    _prefs = await SharedPreferences.getInstance();
    token = _prefs.getString("userToken");

    final http.Response response = await http.post(
      Uri.parse('$url/helper/decline_request'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
        body: jsonEncode(<String, String>{
          "uid": requestID
        })
    );
    if (response.statusCode == 200) {
      makeToast("Successful");
    }
  }

  Future<int> accept(BuildContext context) async {
    token = Provider.of<Helper>(context, listen: false).token;
    _prefs = await SharedPreferences.getInstance();
    if (token == null) {
      _prefs = await SharedPreferences.getInstance();
      token = _prefs.getString("userToken");
      Provider.of<Helper>(context, listen: false).setToken(token);
    }
    int returned = 0;
    final http.Response response = await http.post(
      Uri.parse('$url/helper/accept_request'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
        body: jsonEncode(<String, String>{
      "uid": requestID
    })
    );
    if (response.statusCode == 200) {
      makeToast("Successful");
      Provider.of<Helper>(context, listen: false).changeStatus("Busy");
      var parsed = jsonDecode(response.body).cast<String, dynamic>();
      phone = parsed["phone"] ;

    } else if (response.statusCode == 201){
      makeToast("Someone already accepted the request!");
      returned = 201;
    }
    return returned;
  }
  _getCurrentUserLocation() async {
    helperLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading:  Visibility(
              child: new IconButton(
                  icon: new Icon(Icons.arrow_back),
                  onPressed: (){
                    decline(context);
                    Navigator.pop(context);
                  }
              ),
              visible: true,
            ),
            title: getTitle(
                "Monqez - Helper", 22.0, secondColor, TextAlign.start, true),
            shadowColor: Colors.black,
            backgroundColor: firstColor,
            iconTheme: IconThemeData(color: secondColor),
            elevation: 5),
        backgroundColor: Colors.white,
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
              Container(
                  padding: const EdgeInsets.only(top: 20),
                  color: Colors.white,
                  child: Text('SOS',
                      style: TextStyle(
                        color: primary,
                        fontSize: 48,
                        letterSpacing: 1.75,
                        fontWeight: FontWeight.bold,
                      ))),
              Container(
                  padding: const EdgeInsets.only(top: 20),
                  color: Colors.white,
                  child: Text('A nearby person needs your help on-site!',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                      ))),
              new Container(
                padding: const EdgeInsets.only(top: 20),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new ElevatedButton(
                      child: Icon(Icons.check, size: 60.0),
                      style: ElevatedButton.styleFrom(
                          primary: Colors.green, shape: CircleBorder()),
                      onPressed: () async {
                        int result = await accept(context);
                        if (result == 0){
                          await _getCurrentUserLocation();

                          Provider.of<Helper>(navigatorKey.currentContext, listen: false).saveRequest(phone, requestID, reqLatitude, reqLongitude);
                        navigate(HelperRequestScreen(phone,requestID,reqLatitude,reqLongitude,helperLocation.latitude,helperLocation.longitude),
                            context, true);}
                        else{
                          navigate(HelperHomeScreen(token), context, true);
                        }
                      },
                    ),
                    new ElevatedButton(
                      child: Icon(Icons.close, size: 60.0),
                      style: ElevatedButton.styleFrom(
                          primary: Colors.red, shape: CircleBorder()),
                      onPressed: () async {
                        await decline(context);

                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ])));
  }
}
