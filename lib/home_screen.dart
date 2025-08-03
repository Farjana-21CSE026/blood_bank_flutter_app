import 'package:flutter/material.dart';
import 'donor_list_screen.dart';
import 'donor_registration_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'nearby_donor_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userEmail = user.email ?? "User";

    return WillPopScope(
      onWillPop: () async {
        // ব্যাক প্রেস ডিসেবল করতে চাইলে false রিটার্ন করো
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Welcome to Blood Bank"),
          backgroundColor: Colors.redAccent,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "👋 Welcome, $userEmail!",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                _buildButton(
                  context,
                  icon: Icons.group_add,
                  label: "Donor Registration",
                  color: Colors.redAccent,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DonorRegistrationScreen()),
                    );
                  },
                ),
                const SizedBox(height: 25),
                _buildButton(
                  context,
                  icon: Icons.list,
                  label: "View Donor List",
                  color: Colors.deepPurple,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DonorListScreen()),
                    );
                  },
                ),
                const SizedBox(height: 25),
                _buildButton(
                  context,
                  icon: Icons.location_searching,
                  label: "Search Nearby Donors",
                  color: Colors.deepOrange,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NearbyDonorListScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        backgroundColor: color,
        elevation: 6,
        shadowColor: color.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
