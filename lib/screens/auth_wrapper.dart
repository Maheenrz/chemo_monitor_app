import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
import 'shared/login_screen.dart';       // Look in shared folder
import 'patient/patient_home_screen.dart'; 
import 'package:chemo_monitor_app/screens/doctor/doctor_home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          User? user = snapshot.data;
          
          // 🛑 FETCH USER ROLE FROM FIRESTORE
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                Map<String, dynamic> data = userSnapshot.data!.data() as Map<String, dynamic>;
                String role = data['role'] ?? 'patient';

                // 🚦 ROUTING LOGIC
                if (role == 'doctor') {
                  return const DoctorHomeScreen();
                } else {
                  return const PatientHomeScreen();
                }
              }

              return const LoginScreen(); // Fallback if data missing
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}