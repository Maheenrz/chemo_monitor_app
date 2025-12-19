import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // 1. Sign Up DOCTOR
  Future<String?> signUpDoctor({required String email, required String password}) async {
    try {
      // Create Auth User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Generate a unique 6-digit code
      String doctorCode = _generateDoctorCode();

      // Create User Model
      UserModel newUser = UserModel(
        uid: result.user!.uid,
        email: email,
        role: 'doctor',
        myDoctorCode: doctorCode,
      );

      // Save to Firestore
      await _firestore.collection('users').doc(result.user!.uid).set(newUser.toMap());
      
      return null; // Success (null means no error)
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 2. Sign Up PATIENT
  Future<String?> signUpPatient({
    required String email, 
    required String password, 
    required String doctorCode
  }) async {
    try {
      // VERIFY DOCTOR CODE FIRST
      QuerySnapshot doctorQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('myDoctorCode', isEqualTo: doctorCode)
          .get();

      if (doctorQuery.docs.isEmpty) {
        return "Invalid Doctor Code. Please check with your doctor.";
      }

      // Get the doctor's ID to link them
      String doctorId = doctorQuery.docs.first['uid'];

      // Create Auth User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // Create User Model
      UserModel newUser = UserModel(
        uid: result.user!.uid,
        email: email,
        role: 'patient',
        assignedDoctorId: doctorId, // LINKED!
      );

      // Save to Firestore
      await _firestore.collection('users').doc(result.user!.uid).set(newUser.toMap());

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 3. Login
  Future<String?> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 4. Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper: Generate 6-digit code
  String _generateDoctorCode() {
    var rng = Random();
    return (rng.nextInt(900000) + 100000).toString();
  }
}