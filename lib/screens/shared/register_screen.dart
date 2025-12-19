import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _doctorCodeController = TextEditingController();
  
  final AuthService _authService = AuthService();
  
  bool _isDoctor = false;
  bool _isLoading = false;

  void _register() async {
    setState(() => _isLoading = true);
    String? error;

    if (_isDoctor) {
      error = await _authService.signUpDoctor(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      if (_doctorCodeController.text.isEmpty) {
        error = "Please enter your Doctor's Code";
      } else {
        error = await _authService.signUpPatient(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          doctorCode: _doctorCodeController.text.trim(),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Patient"),
                  Switch(
                    value: _isDoctor,
                    onChanged: (val) => setState(() => _isDoctor = val),
                  ),
                  const Text("Doctor"),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              if (!_isDoctor) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _doctorCodeController,
                  decoration: const InputDecoration(
                    labelText: "Enter Doctor Code",
                    helperText: "Ask your doctor for their unique ID",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: Text(_isDoctor ? "Register as Doctor" : "Register as Patient"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}