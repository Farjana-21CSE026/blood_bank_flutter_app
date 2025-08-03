// lib/donor_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blood_bank_app/location_service.dart';
import 'package:location/location.dart';

Future<void> registerDonor({
  required String name,
  required String bloodGroup,
  required String phone,
}) async {
  LocationData? currentLocation = await getCurrentLocation();

  if (currentLocation != null) {
    GeoPoint geoPoint = GeoPoint(
      currentLocation.latitude!,
      currentLocation.longitude!,
    );

    await FirebaseFirestore.instance.collection('donors').add({
      'name': name,
      'bloodGroup': bloodGroup,
      'phone': phone,
      'location': geoPoint,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
