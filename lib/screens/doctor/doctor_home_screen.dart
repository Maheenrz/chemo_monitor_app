import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query: Find all users where 'assignedDoctorId' matches this doctor's UID
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('assignedDoctorId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No patients found."),
                  const SizedBox(height: 10),
                  // Fetch the doctor code to display it (A bit complex for inline, simplified for now)
                  const Text("Share your Doctor Code to link patients."),
                ],
              ),
            );
          }

          var patients = snapshot.data!.docs;

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              var data = patients[index].data() as Map<String, dynamic>;
              UserModel patient = UserModel.fromMap(data);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(child: Text(patient.email[0].toUpperCase())),
                  title: Text(patient.email),
                  subtitle: const Text("Status: Unknown (No ML Data yet)"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Open Patient Detail Screen
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Patient Details Coming Soon!")));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}