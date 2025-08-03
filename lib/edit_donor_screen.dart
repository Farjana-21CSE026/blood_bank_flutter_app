import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDonorScreen extends StatefulWidget {
  final String donorId;
  final String currentName;
  final String currentBloodGroup;
  final String currentPhone;
  final String currentLocation;

  const EditDonorScreen({
    super.key,
    required this.donorId,
    required this.currentName,
    required this.currentBloodGroup,
    required this.currentPhone,
    required this.currentLocation,
  });

  @override
  State<EditDonorScreen> createState() => _EditDonorScreenState();
}

class _EditDonorScreenState extends State<EditDonorScreen> {
  late TextEditingController nameController;
  late TextEditingController bloodGroupController;
  late TextEditingController phoneController;
  late TextEditingController locationController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    bloodGroupController = TextEditingController(text: widget.currentBloodGroup);
    phoneController = TextEditingController(text: widget.currentPhone);
    locationController = TextEditingController(text: widget.currentLocation);
  }

  @override
  void dispose() {
    nameController.dispose();
    bloodGroupController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> updateDonor() async {
    await FirebaseFirestore.instance.collection('donors').doc(widget.donorId).update({
      'name': nameController.text.trim(),
      'bloodGroup': bloodGroupController.text.trim(),
      'phone': phoneController.text.trim(),
      'location': locationController.text.trim(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donor updated successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Donor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: bloodGroupController,
              decoration: const InputDecoration(labelText: 'Blood Group'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateDonor,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
