import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monqez_app/Backend/FirebaseCloudMessaging.dart';
import 'package:monqez_app/Backend/NotificationRoutes/HelperUserNotification.dart';
import 'package:monqez_app/Backend/NotificationRoutes/NotificationRoute.dart';
import 'package:monqez_app/Models/Helper.dart';
import 'package:monqez_app/Screens/HelperUser/CallingQueueScreen.dart';
import 'package:monqez_app/Screens/HelperUser/RatingsScreen.dart';
import 'package:monqez_app/Screens/AllUsers/Profile.dart';
import 'package:monqez_app/Screens/Authentication/LoginScreen.dart';
import 'package:provider/provider.dart';
import 'package:monqez_app/Screens/Utils/MaterialUI.dart';
import 'package:monqez_app/Backend/Authentication.dart';

import 'HelperRequestScreen.dart';
import 'HelperUserPreviousRequests.dart';

// ignore: must_be_immutable
class HelperHomeScreen extends StatelessWidget {
  String token;
  Position helperLocation ;

  HelperHomeScreen(String token) {
    this.token = token;
  }

  List<String> _statusDropDown = <String>[
    "Available",
    "Busy"
  ];

  List<Icon> icons;
  bool _isLoaded = false;
  String messageTitle = "Empty";
  String notificationAlert = "alert";

  Widget getCard(String title, String trail, Widget nextScreen, IconData icon,
      double width, BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        width: width,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          color: firstColor,
          elevation: 4,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ListTile(
                onTap: () => navigate(nextScreen, context, false),
                contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                title: Icon(
                  icon,
                  size: 70,
                  color: secondColor,
                ),
              ),
              ListTile(
                onTap: () => navigate(nextScreen, context, false),
                leading:
                    getTitle(title, 16, secondColor, TextAlign.center, true),
                trailing:
                    getTitle(trail, 16, secondColor, TextAlign.center, true),
              ),
            ],
          ),
        ),
      ),
    );
  }
  _getCurrentUserLocation() async {
    helperLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      _isLoaded = true;
      Provider.of<Helper>(context, listen: false).setToken(token);
      checkNotification(context);
    }
    if (Provider.of<Helper>(context, listen: true).status == null) {
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
                  ))));
    } else
      return Scaffold(
        backgroundColor: secondColor,
        appBar: AppBar(
          title: getTitle("Monqez", 22.0, secondColor, TextAlign.start, true),
          shadowColor: Colors.black,
          backgroundColor: firstColor,
          iconTheme: IconThemeData(color: secondColor),
          elevation: 5,
          actions: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  dropdownColor: firstColor,
                  value: Provider.of<Helper>(context, listen: true).status,
                  onChanged: (newValue) {
                    Provider.of<Helper>(context, listen: false).status =
                        newValue;
                    Provider.of<Helper>(context, listen: false)
                        .changeStatus(newValue);
                  },
                  items: (Provider.of<Helper>(context, listen: false).hasActiveRequest()) ? null :
                  _statusDropDown.map((location) {
                    return DropdownMenuItem(
                        child: SizedBox(
                          width: 140,
                          child: getTitle(
                              location, 16, secondColor, TextAlign.end, true),
                        ),
                        value: location);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Container(
                    alignment: Alignment.centerLeft,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          getTitle(
                              Provider.of<Helper>(context, listen: true).name,
                              26,
                              secondColor,
                              TextAlign.start,
                              true),
                          Container(
                            width: 90,
                            height: 90,
                            child: CircularProfileAvatar(
                              null,
                              child: Provider.of<Helper>(context, listen: true).image == null ? Icon(Icons.account_circle_rounded,
                                  size: 90, color: secondColor): Image.memory(Provider.of<Helper>(context, listen: true).image.decode()),
                              radius: 100,
                              backgroundColor: Colors.transparent,
                              borderColor: Provider.of<Helper>(context, listen: true).image == null ? firstColor : secondColor,
                              elevation: 5.0,
                              cacheImage: true,
                              onTap: () {
                              }, // sets on tap
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
                  ListTile(
                    title: getTitle(
                        'My Profile', 18, firstColor, TextAlign.start, true),
                    leading: Icon(Icons.account_circle_rounded,
                        size: 30, color: firstColor),
                    onTap: () {
                      Navigator.pop(context);
                      navigate(
                          ProfileScreen(
                              Provider.of<Helper>(context, listen: false)),
                          context,
                          false);
                    },
                  ),
                  ListTile(
                    title: getTitle(
                        'Call Queue', 18, firstColor, TextAlign.start, true),
                    leading: Icon(Icons.call, size: 30, color: firstColor),
                    onTap: () {
                      Navigator.pop(context);
                      navigate(CallingQueueScreen(), context, false);
                    },
                  ),
                  ListTile(
                    title: getTitle(
                        'My Requests', 18, firstColor, TextAlign.start, true),
                    leading: Icon(Icons.history,
                        size: 30, color: firstColor),
                    onTap: () {
                      navigate(HelperPreviousRequests(Provider.of<Helper>(context, listen: false)), context, false);
                    },
                  ),
                  ListTile(
                    title: getTitle(
                        'My Ratings', 18, firstColor, TextAlign.start, true),
                    leading: Icon(Icons.star_rate, size: 30, color: firstColor),
                    onTap: () {
                      Navigator.pop(context);
                      navigate(HelperRatingsScreen(Provider.of<Helper>(context, listen: false).ratings), context, false);
                    },
                  ),
                  ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        getTitle(
                            'My Points', 18, firstColor, TextAlign.start, true),
                        getTitle(
                            (Provider.of<Helper>(context, listen: false)
                                .myPoints).toString(), 18, firstColor, TextAlign.start, true),                      ],
                    ),
                    leading: Icon(Icons.money, size: 30, color: firstColor),
                  ),
                  Visibility(
                    visible: Provider.of<Helper>(context, listen: false).hasActiveRequest(),
                    child: ListTile(
                      title:
                          getTitle(
                              'Active Request', 18, firstColor, TextAlign.start, true),
                      onTap: () async {

                        var provider = Provider.of<Helper>(context, listen: false);
                        await _getCurrentUserLocation();
                        navigate(HelperRequestScreen(provider.requestPhone,provider.requestID,provider.requestLatitude,provider.requestLongitude,helperLocation.latitude,helperLocation.longitude),
                            context, true);
                      },
                      leading: Icon(Icons.navigation, size: 30, color: firstColor),
                    ),
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
                              if (Provider.of<Helper>(context, listen: false)
                                      .status ==
                                  "Available") {
                                Provider.of<Helper>(context, listen: false)
                                    .stopBackgroundProcess();
                                Provider.of<Helper>(context, listen: false)
                                    .changeStatus("Busy");
                              }
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
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              height: double.infinity,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 10.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    getCard(
                        "Call Queue",
                        Provider.of<Helper>(context, listen: true).callCount.toString(),
                        CallingQueueScreen(),
                        Icons.call,
                        MediaQuery.of(context).size.width,
                        context),
                    getCard(
                        "My Ratings",
                        Provider.of<Helper>(context, listen: true).ratings.toStringAsFixed(2),
                        HelperRatingsScreen(Provider.of<Helper>(context, listen: false)
                            .ratings),
                        Icons.star_rate,
                        MediaQuery.of(context).size.width,
                        context),
                  ],
                ),
              ),
            ),
          )
        ),
      );
  }
}

void checkNotification(BuildContext context) async {
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage message) {
    if (message != null) {
      FirebaseCloudMessaging.route = new HelperUserNotification(message, true);
      navigate(NotificationRoute.selectNavigate, context, true);
    }
  });
}
