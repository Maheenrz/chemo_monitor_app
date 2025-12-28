import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // ----------------------------------------------------------------
  // 1. Register Doctor (Updated)
  // ----------------------------------------------------------------
  Future<User?> registerDoctor({
    required String email,
    required String password,
    required String name, // NEW
    String? specialization, // NEW
  }) async {
    try {
      // Create Auth User
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Generate Unique Code
        String doctorCode = _generateDoctorCode();
        
        // Create User Model with new fields
        UserModel userModel = UserModel(
          uid: user.uid,
          email: email,
          role: 'doctor',
          name: name,
          specialization: specialization,
          doctorCode: doctorCode, // Note: Ensure UserModel uses 'doctorCode', not 'myDoctorCode'
          createdAt: DateTime.now(),
        );

        // Save to Firestore
        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
        
        return user;
      }
    } catch (e) {
      throw Exception('Doctor registration failed: $e');
    }
    return null;
  }

  // ----------------------------------------------------------------
  // 2. Register Patient (Updated)
  // ----------------------------------------------------------------
  Future<User?> registerPatient({
    required String email,
    required String password,
    required String name, // NEW
    required String doctorCode,
    int? age, // NEW
    String? gender, // NEW
    String? bloodGroup, // NEW
  }) async {
    try {
      // Validate Doctor Code first
      String? doctorId = await validateDoctorCode(doctorCode);
      if (doctorId == null) {
        throw Exception('Invalid doctor code');
      }

      // Create Auth User
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Create User Model with new fields
        UserModel userModel = UserModel(
          uid: user.uid,
          email: email,
          role: 'patient',
          name: name,
          age: age,
          gender: gender,
          bloodGroup: bloodGroup,
          assignedDoctorId: doctorId,
          createdAt: DateTime.now(),
        );

        // Save to Firestore
        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
        
        return user;
      }
    } catch (e) {
      throw Exception('Patient registration failed: $e');
    }
    return null;
  }

  // ----------------------------------------------------------------
  // 3. User Profile & Helpers
  // ----------------------------------------------------------------
  
  // Add method to get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  // Helper: Validate Doctor Code (Required for registerPatient)
Future<String?> validateDoctorCode(String code) async {
  try {
    QuerySnapshot query = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('doctorCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      // Return the UID from the document data
      return data['uid'] ?? doc.id;
    }
  } on FirebaseException catch (e) {
    print("Firestore error validating code: ${e.code} - ${e.message}");
    throw Exception("Unable to validate doctor code. Please check your connection.");
  } catch (e) {
    print("Error validating code: $e");
    throw Exception("Invalid doctor code or server error.");
  }
  return null;
}

  // Helper: Generate 6-digit code
  String _generateDoctorCode() {
    var rng = Random();
    return (rng.nextInt(900000) + 100000).toString();
  }

  // ----------------------------------------------------------------
  // 4. Standard Auth Methods
  // ----------------------------------------------------------------

  // Login
  Future<String?> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unknown error occurred";
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}