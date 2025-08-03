import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';

class DonorSearchService {
  final geo = GeoFlutterFire();

  Stream<List<DocumentSnapshot>> getNearbyDonors({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? bloodGroupFilter,
  }) {
    final center = geo.point(latitude: latitude, longitude: longitude);

    final collectionRef = FirebaseFirestore.instance.collection('donors');

    final stream = geo.collection(collectionRef: collectionRef).within(
      center: center,
      radius: radiusInKm,
      field: 'position',
      strictMode: true,
    );

    // Optional blood group filtering
    return stream.map((docs) {
      if (bloodGroupFilter == null || bloodGroupFilter.isEmpty) return docs;
      return docs.where((doc) => doc['bloodGroup'] == bloodGroupFilter).toList();
    });
  }
}
