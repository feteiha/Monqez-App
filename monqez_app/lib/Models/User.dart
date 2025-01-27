import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:monqez_app/Backend/Authentication.dart';
import 'package:monqez_app/Backend/FirebaseCloudMessaging.dart';
import 'package:monqez_app/Screens/InstructionsScreens/ImageController.dart';

class User {
  String name;
  String nationalID;
  String phone;
  String birthdate;
  String country;
  String city;
  String street;
  String buildNumber;
  String gender;
  String token;
  ImageController image;
  String diseases = "";
  static FirebaseCloudMessaging fcm;
  User.empty();

  setToken(String token) {
    this.token = token;
    if (fcm == null) {
      fcm = new FirebaseCloudMessaging(token);
    }
  }

  getUser() async {
    http.Response response2 = await http.get(
      Uri.parse('$url/user/getprofile/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response2.statusCode == 200) {
      var parsed = jsonDecode(response2.body).cast<String, dynamic>();
      this.name = parsed['name'];
      this.nationalID = parsed['national_id'];
      this.phone = parsed['phone'];
      this.birthdate = parsed['birthdate'];
      this.country = parsed['country'];
      this.city = parsed['city'];
      this.street = parsed['street'];
      this.buildNumber = parsed['buildNumber'];
      this.gender = parsed['gender'];
      if (parsed['image'] != null)
        this.image = parsed['image'].toString().length < 5 ? null : new ImageController.fromBase64(parsed['image']);
      this.diseases = parsed['chronicDiseases'];
    } else {
      makeToast("Error getting profile");
    }
  }

  Future<bool> saveUser() async {
    final http.Response response = await http.post(
      Uri.parse('$url/user/edit'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'national_id': nationalID,
        'phone': phone,
        'birthdate': birthdate,
        'gender': gender,
        'country': country,
        'city': city,
        'street': street,
        'buildNumber': buildNumber,
        'image': image == null ? '' : image.base_64,
        'chronicDiseases': diseases
      }),
    );
    if (response.statusCode == 200) {
      makeToast("Saved");
      return true;
    } else {
      makeToast('Failed to save changes');
      return false;
    }
  }
}
