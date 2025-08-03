import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart'; // ✅ Updated import

class DonorRegistrationScreen extends StatefulWidget {
  const DonorRegistrationScreen({super.key});

  @override
  State<DonorRegistrationScreen> createState() => _DonorRegistrationScreenState();
}

class _DonorRegistrationScreenState extends State<DonorRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final geo = GeoFlutterFire(); // ✅ works with geoflutterfire2
  final location = Location();

  bool _isLoading = false;

  Future<LocationData?> _getCurrentLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return null;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }

    return await location.getLocation();
  }

  Future<void> _submitDonor() async {
    if (_nameController.text.isEmpty ||
        _bloodGroupController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ সব তথ্য পূরণ করুন")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final locationData = await _getCurrentLocation();

      if (locationData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ লোকেশন পাওয়া যায়নি")),
        );
        setState(() => _isLoading = false);
        return;
      }

      final geoPoint = geo.point(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
      );

      await FirebaseFirestore.instance.collection('donors').add({
        'name': _nameController.text.trim(),
        'bloodGroup': _bloodGroupController.text.trim().toUpperCase(),
        'phone': _phoneController.text.trim(),
        'position': geoPoint.data, // ✅ GeoFlutterFire2 compatible
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Donor Registered Successfully")),
      );

      _nameController.clear();
      _bloodGroupController.clear();
      _phoneController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bloodGroupController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _bloodGroupController,
                decoration: const InputDecoration(labelText: 'Blood Group (e.g. A+, B-)'),
              ),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitDonor,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register Donor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
