import 'dart:convert';
import 'package:http/http.dart' as http;

/// Email OTP Authentication
class EmailOtpAuth {
  /// Variables for [EmailOtpAuth]
  static String _email = "";
  static String _hash = "";

  /// Sends an OTP to the user's email address.
  /// [email]: The email address to which the OTP will be sent.
  static Future<Map<String, dynamic>> sendOTP({required String email}) async {
    try {
      // Creating the URL
      var url = Uri.https(
          "definite-emilee-kamesh-564a9766.koyeb.app", "api/send-otp");

      // Sending a POST request and receiving the response
      var res = await http.Client().post(
        url,
        headers: {"Content-type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "email": email,
        }),
      );

      // Converting JSON to a Map
      Map<String, dynamic> mapData = jsonDecode(res.body);

      // Assigning email and hash key
      _email = email;
      _hash = mapData["data"];

      // Returning the decoded JSON data
      return mapData;
    } catch (error) {
      throw error.toString();
    }
  }

  /// Verifies the OTP using the [verifyOtp] method.
  /// [otp]: The OTP sent to the email address.
  static Future<Map<String, dynamic>> verifyOtp({
    required String otp,
  }) async {
    try {
      // Creating the URL
      var url = Uri.https(
          "definite-emilee-kamesh-564a9766.koyeb.app", "api/verify-otp");

      // Sending a POST request and receiving the response
      var res = await http.Client().post(
        url,
        headers: {"Content-type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "email": _email,
          "hash": _hash,
          "otp": otp,
        }),
      );

      // Converting JSON to a Map
      Map<String, dynamic> mapData = jsonDecode(res.body);

      // Returning the decoded JSON data
      return mapData;
    } catch (error) {
      throw error.toString();
    }
  }
}
