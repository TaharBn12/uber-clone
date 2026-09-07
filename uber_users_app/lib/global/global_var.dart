import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";
String userPhone = "";
String userEmail = "";
String userID = FirebaseAuth.instance.currentUser!.uid;
// API keys are injected at build time so that no secret is committed:
//   flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=... \
//       --dart-define=STRIPE_PUBLISHABLE_KEY=... --dart-define=STRIPE_SECRET_KEY=...
// (CI reads them from repository secrets, see .github/workflows/build-apks.yml).
const String googleMapKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
const String stripeSecretAPIKey = String.fromEnvironment('STRIPE_SECRET_KEY');
const String stripePublishedKey =
    String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);
