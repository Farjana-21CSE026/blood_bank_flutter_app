import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:geoflutterfire2/geoflutterfire2.dart';  // v2+ version এ এই প্যাকেজ নাম
import 'package:location/location.dart';

class DonorListScreen extends StatefulWidget {
  const DonorListScreen({super.key});

  @override
  State<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends State<DonorListScreen> {
  final geo = GeoFlutterFire();  // geoflutterfire2 প্যাকেজ থেকে
  final location = Location();

  Stream<List<DocumentSnapshot>>? stream;

  String searchGroup = "";

  @override
  void initState() {
    super.initState();
    _startQuery();
  }

  Future<void> _startQuery() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final userLocation = await location.getLocation();

    final center = geo.point(
      latitude: userLocation.latitude!,
      longitude: userLocation.longitude!,
    );

    const double radius = 10; // 10 km

    setState(() {
      stream = geo
          .collection(
            collectionRef: FirebaseFirestore.instance.collection('donors'),
          )
          .within(center: center, radius: radius, field: 'position');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Donor List")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Blood Group',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  searchGroup = val.trim().toUpperCase();
                });
              },
            ),
          ),
          Expanded(
            child: stream == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<DocumentSnapshot>>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final filteredDocs = snapshot.data!.where((doc) {
                        final data = doc.data()! as Map<String, dynamic>;
                        final bloodGroup = data['bloodGroup']?.toString().toUpperCase() ?? '';
                        return searchGroup.isEmpty || bloodGroup.contains(searchGroup);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return const Center(child: Text("No donors found nearby."));
                      }

                      return ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final donor = filteredDocs[index].data()! as Map<String, dynamic>;
                          final donorId = filteredDocs[index].id;

                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text(donor['name'] ?? 'No Name'),
                              subtitle: Text("Blood Group: ${donor['bloodGroup'] ?? '-'}"),
                              trailing: ElevatedButton(
                                child: const Text("Request"),
                                onPressed: () async {
                                  final currentUser = FirebaseAuth.instance.currentUser;
                                  if (currentUser == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please login first.")),
                                    );
                                    return;
                                  }

                                  await FirebaseFirestore.instance.collection('blood_requests').add({
                                    'recipientId': currentUser.uid,
                                    'donorId': donorId,
                                    'bloodGroup': donor['bloodGroup'],
                                    'status': 'pending',
                                    'timestamp': Timestamp.now(),
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Blood request sent!")),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
