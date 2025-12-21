import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../config/app_constants.dart'; // ✅ FIXED: Added this import

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _doctorCodeController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  
  // State Variables
  bool _isDoctor = false;
  bool _isLoading = false;
  String? _selectedGender;
  String? _selectedBloodGroup;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _doctorCodeController.dispose();
    _specializationController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isDoctor) {
        // Register Doctor
        await _authService.registerDoctor(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          specialization: _specializationController.text.trim().isEmpty
              ? null
              : _specializationController.text.trim(),
        );
      } else {
        // Register Patient
        await _authService.registerPatient(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          doctorCode: _doctorCodeController.text.trim(),
          age: _ageController.text.isEmpty ? null : int.tryParse(_ageController.text),
          gender: _selectedGender,
          bloodGroup: _selectedBloodGroup,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful!'), 
            backgroundColor: AppColors.success
          ),
        );
        // Navigate to Home or Login
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception:", "")), 
            backgroundColor: AppColors.danger
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppDimensions.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role Switch Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  activeColor: AppColors.primary,
                  title: Text(
                    _isDoctor ? 'Register as Doctor' : 'Register as Patient',
                    style: AppTextStyles.heading3,
                  ),
                  subtitle: Text(_isDoctor ? 'Healthcare Provider' : 'Patient Account'),
                  value: _isDoctor,
                  onChanged: (value) {
                    setState(() {
                      _isDoctor = value;
                      // Clear role-specific fields when switching
                      _doctorCodeController.clear();
                      _specializationController.clear();
                    });
                  },
                ),
              ),
              
              SizedBox(height: 24),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter your name' : null,
              ),

              SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter email';
                  if (!value.contains('@')) return 'Please enter valid email';
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter password';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),

              SizedBox(height: 16),

              // ---------------------------------------------------------------
              // DOCTOR SPECIFIC FIELDS
              // ---------------------------------------------------------------
              if (_isDoctor) ...[
                TextFormField(
                  controller: _specializationController,
                  decoration: InputDecoration(
                    labelText: 'Specialization',
                    prefixIcon: Icon(Icons.medical_services),
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Oncology',
                  ),
                ),
              ],

              // ---------------------------------------------------------------
              // PATIENT SPECIFIC FIELDS
              // ---------------------------------------------------------------
              if (!_isDoctor) ...[
                // Doctor Code
                TextFormField(
                  controller: _doctorCodeController,
                  decoration: InputDecoration(
                    labelText: 'Doctor Code *',
                    prefixIcon: Icon(Icons.vpn_key),
                    border: OutlineInputBorder(),
                    hintText: '6-digit code provided by doctor',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter doctor code' : null,
                ),
                
                SizedBox(height: 16),

                // Age
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),

                SizedBox(height: 16),

                // Gender
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc),
                    border: OutlineInputBorder(),
                  ),
                  items: ['Male', 'Female', 'Other'].map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedGender = value),
                ),

                SizedBox(height: 16),

                // Blood Group
                DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: Icon(Icons.bloodtype),
                    border: OutlineInputBorder(),
                  ),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((bg) {
                    return DropdownMenuItem(
                      value: bg,
                      child: Text(bg),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedBloodGroup = value),
                ),
              ],

              SizedBox(height: 32),

              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Register',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
              ),

              SizedBox(height: 16),

              // Login Link
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}