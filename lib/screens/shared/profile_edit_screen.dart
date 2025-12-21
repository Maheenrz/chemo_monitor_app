import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemo_monitor_app/models/user_model.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Soft Color Palette
class SoftColors {
  static const Color primaryBlue = Color(0xFF7BA3D6);
  static const Color lightBlue = Color(0xFFE8F1FC);
  static const Color softGreen = Color(0xFF6FD195);
  static const Color paleGreen = Color(0xFFE8F8F0);
  static const Color softPurple = Color(0xFF9B8ED4);
  static const Color palePurple = Color(0xFFF2F0FC);
  static const Color textPrimary = Color(0xFF2D3E50);
  static const Color textSecondary = Color(0xFF8E9AAF);
  static const Color riskModerate = Color(0xFFFAB87F);
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  UserModel? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      if (profile != null && mounted) {
        setState(() {
          _userProfile = profile;
          _nameController.text = profile.name;
          _phoneController.text = profile.phoneNumber ?? '';
          _specializationController.text = profile.specialization ?? '';
          _ageController.text = profile.age?.toString() ?? '';
          _selectedGender = profile.gender;
          _selectedBloodGroup = profile.bloodGroup;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      Map<String, dynamic> updates = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
      };

      // Role-specific updates
      if (_userProfile?.role == 'doctor') {
        updates['specialization'] = _specializationController.text.trim().isEmpty
            ? null
            : _specializationController.text.trim();
      } else {
        // Patient-specific updates
        updates['age'] = _ageController.text.isEmpty 
          ? null 
          : int.tryParse(_ageController.text);
        updates['gender'] = _selectedGender;
        updates['bloodGroup'] = _selectedBloodGroup;
      }

      // TODO: Upload image to Firebase Storage and get URL
      // For now, we'll just update the text fields
      // if (_selectedImage != null) {
      //   final imageUrl = await _uploadImage(_selectedImage!);
      //   updates['profileImageUrl'] = imageUrl;
      // }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully! ✓'),
            backgroundColor: SoftColors.softGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: SoftColors.riskModerate,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: SoftColors.lightBlue,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(SoftColors.primaryBlue),
          ),
        ),
      );
    }

    final isDoctor = _userProfile?.role == 'doctor';

    return Scaffold(
      backgroundColor: SoftColors.lightBlue,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SoftColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, size: 20, color: SoftColors.primaryBlue),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: SoftColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Profile Picture
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [SoftColors.primaryBlue, SoftColors.softPurple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: SoftColors.primaryBlue.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _selectedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _userProfile?.profileImageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _userProfile!.profileImageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      isDoctor 
                                        ? Icons.medical_services_rounded
                                        : Icons.person_rounded,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: SoftColors.softGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: SoftColors.softGreen.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    isDoctor ? 'Dr. ${_userProfile?.name ?? ""}' : _userProfile?.name ?? '',
                    style: TextStyle(
                      color: SoftColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDoctor ? SoftColors.palePurple : SoftColors.paleGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isDoctor ? 'Healthcare Provider' : 'Patient',
                      style: TextStyle(
                        color: isDoctor ? SoftColors.softPurple : SoftColors.softGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Form
            Padding(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: TextStyle(
                        color: SoftColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Name
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Please enter your name' : null,
                    ),

                    SizedBox(height: 16),

                    // Phone
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      hint: '+1 234 567 8900',
                    ),

                    if (isDoctor) ...[
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _specializationController,
                        label: 'Specialization',
                        icon: Icons.medical_services_outlined,
                        hint: 'e.g., Oncology, Cardiology',
                      ),
                    ],

                    if (!isDoctor) ...[
                      SizedBox(height: 24),
                      Text(
                        'Health Information',
                        style: TextStyle(
                          color: SoftColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _ageController,
                              label: 'Age',
                              icon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: SoftColors.primaryBlue.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedGender,
                                decoration: InputDecoration(
                                  labelText: 'Gender',
                                  labelStyle: TextStyle(color: SoftColors.textSecondary),
                                  prefixIcon: Icon(Icons.wc_outlined, 
                                    color: SoftColors.primaryBlue),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: ['Male', 'Female', 'Other'].map((gender) {
                                  return DropdownMenuItem(
                                    value: gender,
                                    child: Text(gender),
                                  );
                                }).toList(),
                                onChanged: (value) => 
                                  setState(() => _selectedGender = value),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: SoftColors.primaryBlue.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedBloodGroup,
                          decoration: InputDecoration(
                            labelText: 'Blood Group',
                            labelStyle: TextStyle(color: SoftColors.textSecondary),
                            prefixIcon: Icon(Icons.bloodtype_outlined, 
                              color: SoftColors.primaryBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                              .map((bg) {
                            return DropdownMenuItem(
                              value: bg,
                              child: Text(bg),
                            );
                          }).toList(),
                          onChanged: (value) => 
                            setState(() => _selectedBloodGroup = value),
                        ),
                      ),
                    ],

                    SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SoftColors.softGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Info Card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SoftColors.lightBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, 
                            color: SoftColors.primaryBlue, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Note: Profile picture upload will be available soon. For now, we\'ll show your initials.',
                              style: TextStyle(
                                color: SoftColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SoftColors.primaryBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: SoftColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: SoftColors.textSecondary),
          hintStyle: TextStyle(color: SoftColors.textSecondary.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: SoftColors.primaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}