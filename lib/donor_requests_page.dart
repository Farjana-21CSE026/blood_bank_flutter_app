import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonorRequestsPage extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  const DonorRequestsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Incoming Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .where('donorId', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("No requests yet"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              final docId = requests[index].id;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Blood Group: ${data['bloodGroup']}"),
                  subtitle: Text("Requested by: ${data['recipientId']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => updateStatus(docId, 'accepted'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => updateStatus(docId, 'declined'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void updateStatus(String requestId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(requestId)
          .update({'status': newStatus});
    } catch (e) {
      print('Error updating status: $e');
    }
  }
}
