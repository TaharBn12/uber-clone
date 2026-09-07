import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/global/global_var.dart';

class PushNotificationService {
  /// Location (inside the Flutter asset bundle) of the Firebase service-account
  /// key used to call the FCM HTTP v1 API.
  ///
  /// The real key is **not** committed to git – copy your own key to
  /// `assets/firebase/service_account.json` (see `assets/firebase/README.md`).
  /// When the file is missing, notifications are skipped with a log message
  /// instead of crashing the app.
  static const String serviceAccountAssetPath =
      'assets/firebase/service_account.json';

  static const List<String> _scopes = [
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/firebase.database",
    "https://www.googleapis.com/auth/firebase.messaging"
  ];

  static Map<String, dynamic>? _serviceAccountCache;

  /// Loads and validates the service-account JSON from the asset bundle.
  /// Returns `null` (after logging why) when it is missing or a placeholder.
  static Future<Map<String, dynamic>?> loadServiceAccount() async {
    if (_serviceAccountCache != null) return _serviceAccountCache;
    String raw;
    try {
      raw = await rootBundle.loadString(serviceAccountAssetPath);
    } catch (e) {
      debugPrint(
          'FCM: $serviceAccountAssetPath not found in the app bundle ($e). '
          'Push notifications are disabled – see assets/firebase/README.md.');
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> &&
          decoded['type'] == 'service_account' &&
          decoded['project_id'] is String &&
          decoded['client_email'] is String &&
          decoded['private_key'] is String &&
          (decoded['private_key'] as String).contains('BEGIN PRIVATE KEY')) {
        _serviceAccountCache = decoded;
        return decoded;
      }
      debugPrint('FCM: $serviceAccountAssetPath is not a valid service-account '
          'key (placeholder values?). Push notifications are disabled.');
    } catch (e) {
      debugPrint('FCM: could not parse $serviceAccountAssetPath: $e');
    }
    return null;
  }

  /// Returns an OAuth2 access token for the FCM v1 API, or `null` when no
  /// service-account key is bundled with the app.
  static Future<String?> getAccessToken() async {
    final serviceAccountJson = await loadServiceAccount();
    if (serviceAccountJson == null) return null;
    final http.Client client = http.Client();
    try {
      final auth.AccessCredentials credentials =
          await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        _scopes,
        client,
      );
      return credentials.accessToken.data;
    } catch (e) {
      debugPrint("Failed to obtain access token: $e");
      rethrow;
    } finally {
      client.close();
    }
  }

  static sendNotificationToSelectedDriver(
      String deviceToken, BuildContext context, String tripID) async {
        print('device token, ${deviceToken}');
    String dropOffDesitinationAddress =
        Provider.of<AppInfoClass>(context, listen: false)
            .dropOffLocation!
            .placeName
            .toString();
    String pickUpAddress = Provider.of<AppInfoClass>(context, listen: false)
        .pickUpLocation!
        .placeName
        .toString();
    print('pickup address is ${pickUpAddress}');
    final String? serverKeyTokenKey = await getAccessToken();
    if (serverKeyTokenKey == null) {
      debugPrint('Push notification to driver skipped: no FCM service-account '
          'key configured.');
      return;
    }
    // Same Firebase project the app was initialised with (see firebase_options.dart).
    final String firebaseProjectId = Firebase.app().options.projectId;
    final String? keyProjectId =
        (await loadServiceAccount())?['project_id'] as String?;
    if (keyProjectId != null && keyProjectId != firebaseProjectId) {
      debugPrint('FCM: service-account key belongs to project "$keyProjectId" '
          'but the app uses project "$firebaseProjectId" – sending will fail.');
    }
    String endpointFirebaseCloudMessaging =
        "https://fcm.googleapis.com/v1/projects/$firebaseProjectId/messages:send";
    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken,
        'notification': {
          'title': "New Trip Request From $userName",
          'body':
              "PickUp Location: $pickUpAddress \nDropOff Location: $dropOffDesitinationAddress"
        },
        'data': {
          'tripID': tripID,
        }
      }
    };
    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKeyTokenKey'
      },
      body: jsonEncode(message),
    );
    if (response.statusCode == 200) {
      print("Notifcation send successfully. ${response.statusCode}");
    } else {
      print('Failed to send notification, ${response.statusCode}');
    }
  }
}
