import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monqez_app/Backend/Authentication.dart';
import 'package:monqez_app/Models/Helper.dart';
import 'package:monqez_app/Screens/Calls/VideoPage.dart';
import 'package:monqez_app/Screens/Utils/MaterialUI.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../Calls/VoicePage.dart';

class CallingQueueScreen extends StatefulWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ratings',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: CallingQueueScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  @override
  _CallingQueueScreenState createState() => _CallingQueueScreenState();
}

class _CallingQueueScreenState extends State<CallingQueueScreen>
    with SingleTickerProviderStateMixin {
  List<Widget> _calls = <Widget>[];
  bool _isLoading = true;

  void iterateJson(String jsonStr) {
    _calls = [];
    List<dynamic> callss = json.decode(jsonStr);

    //m7taga ttshal bs ana 5ayf asheel l for each
    callss.forEach((call) {
      var singleCall = call as Map<String, dynamic>;
      if (singleCall == null) return;
      for (int i = 0; i < singleCall.keys.length; i++) {
        var key = singleCall.keys.elementAt(i);
        String normalUID = key;
        String channelID = singleCall[key]['channelId'];
        String type = singleCall[key]['type'];
        String data = singleCall[key]['data'];
        String name = singleCall[key]['name'];
        //String date = singleCall['date'];
        IconData icon;
        if (type == "video") {
          icon = Icons.video_call;
        } else {
          icon = Icons.call;
        }
        _calls.add(getCard(name, data, icon, MediaQuery.of(context).size.width,
            channelID, type, normalUID));
      }
    });
  }

  getAllCalls() async {
    _isLoading = true;
    var token = Provider.of<Helper>(context, listen: false).token;

    final http.Response response = await http.post(
      Uri.parse('$url/helper/get_call_queue/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      iterateJson(response.body);
      setState(() {
        _isLoading = false;
      });
      return true;
    } else {
      setState(() {
        _isLoading = false;
      });
      return false;
    }
  }

  Future<int> acceptCall(String normalUID) async {
    var token = Provider.of<Helper>(context, listen: false).token;

    final http.Response response = await http.post(
      Uri.parse('$url/helper/accept_call/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{'uid': normalUID}),
    );
    return response.statusCode;
  }

  @override
  void initState() {
    super.initState();
    getAllCalls();
    //callController.addListener();
  }

  Widget getCard(String name, String comment, IconData icon, double width,
      String channelID, type, String normalUID) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () async {
          int statusCode = await acceptCall(normalUID);
          if (statusCode == 200) {
            if (type == "video") await _handleCameraAndMic(Permission.camera);
            await _handleCameraAndMic(Permission.microphone);
            if (type == "video") {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallPage(channelName: channelID),
                  ));
              await getAllCalls();
              setState(() {});
            } else {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VoicePage(channelName: channelID),
                  ));
              await getAllCalls();
              setState(() {});
            }
          } else if (statusCode == 503) {
            makeToast("Call is already answered");
          } else {
            makeToast(statusCode.toString());
          }
        },
        child: Container(
          width: width,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            color: firstColor,
            elevation: 6,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  title: getTitle(name, 24, secondColor, TextAlign.start, true),
                  trailing: Icon(
                    icon,
                    size: 45,
                    color: secondColor,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                  title: getTitle(
                      comment, 16, secondColor, TextAlign.start, false),
                ),
                //ListT
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                    //    valueColor:
                    //      new AlwaysStoppedAnimation<Color>(firstColor)
                  ))));
    } else
      return Scaffold(
        backgroundColor: secondColor,
        appBar: AppBar(
          title:
              getTitle("Call Queue", 22.0, secondColor, TextAlign.start, true),
          shadowColor: Colors.black,
          backgroundColor: firstColor,
          iconTheme: IconThemeData(color: secondColor),
          elevation: 4,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, true),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 15, 0),
              child: Center(
                  child: getTitle(_calls.length.toString(), 22, secondColor,
                      TextAlign.center, true)),
            ),
          ],
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
                  vertical: 20.0,
                ),
                child: Column(children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      await getAllCalls();
                      return true;
                    },
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      physics: const AlwaysScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _calls.length,
                      itemBuilder: (BuildContext context, int index) {
                        return _calls[index];
                      },
                    ),
                  )
                ]),
              ),
            ),
          ),
        ),
      );
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
     await permission.request();
  }
}
