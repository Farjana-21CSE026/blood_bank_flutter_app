import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BloodRequestPage extends StatefulWidget {
  const BloodRequestPage({super.key});

  @override
  _BloodRequestPageState createState() => _BloodRequestPageState();
}

class _BloodRequestPageState extends State<BloodRequestPage> {
  String? selectedBloodGroup;
  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  List<Map<String, dynamic>> matchingDonors = [];
  bool isLoading = false;

  // ডোনার খোঁজার ফাংশন
  Future<void> fetchMatchingDonors() async {
    if (selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a blood group')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      matchingDonors = [];
    });

    try {
      final donorsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'donor')
          .where('bloodGroup', isEqualTo: selectedBloodGroup)
          .get();

      final donors = donorsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'No Name',
          'bloodGroup': data['bloodGroup'] ?? '',
          'location': data['location'] ?? '',
          'age': data['age'] ?? '',
          // অন্য ডাটা চাইলে এখানে যোগ করো
        };
      }).toList();

      setState(() {
        matchingDonors = donors;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching donors: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // রিকোয়েস্ট পাঠানোর ফাংশন
  Future<void> sendRequest(String donorId) async {
    final requester = FirebaseAuth.instance.currentUser;

    if (requester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to send request')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'requesterId': requester.uid,
        'donorId': donorId,
        'bloodGroup': selectedBloodGroup,
        'status': 'pending',
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to donor')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Blood'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              hint: const Text('Select Blood Group'),
              value: selectedBloodGroup,
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  selectedBloodGroup = value;
                });
              },
              items: bloodGroups.map((bg) {
                return DropdownMenuItem(
                  value: bg,
                  child: Text(bg),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: fetchMatchingDonors,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Text('Search Donors'),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (matchingDonors.isEmpty)
              const Center(child: Text('No donors found'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: matchingDonors.length,
                  itemBuilder: (context, index) {
                    final donor = matchingDonors[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(donor['name']),
                        subtitle: Text(
                            "Blood Group: ${donor['bloodGroup']}\nAge: ${donor['age']}\nLocation: ${donor['location']}"),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: () => sendRequest(donor['uid']),
                          child: const Text('Request'),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
