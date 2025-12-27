import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/screens/shared/login_screen.dart';
import 'package:chemo_monitor_app/screens/shared/doctor_directory_screen.dart'; // Added import

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _doctorCodeController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // State
  int _currentStep = 0;
  bool _isDoctor = false;
  bool _isLoading = false;
  String? _selectedGender;
  String? _selectedBloodGroup;
  final List<String> _steps = ['Role', 'Account', 'Details', 'Complete'];
  
  // Password strength
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );
    _animationController.forward();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _doctorCodeController.dispose();
    _specializationController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    setState(() {
      if (score >= 4) {
        _passwordStrength = PasswordStrength.strong;
      } else if (score >= 2) {
        _passwordStrength = PasswordStrength.medium;
      } else {
        _passwordStrength = PasswordStrength.weak;
      }
    });
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return AppColors.pastelPetal;
      case PasswordStrength.medium:
        return AppColors.powderBlue;
      case PasswordStrength.strong:
        return AppColors.frozenWater;
    }
  }

  void _nextStep() {
    // Validate before moving to next step
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      
      // Check password match
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Passwords do not match');
        return;
      }
      
      // Check password strength
      if (_passwordStrength == PasswordStrength.weak) {
        _showError('Please use a stronger password for security');
        return;
      }
    }
    
    if (_currentStep == 2) {
      // Validate details step
      if (!_isDoctor) {
        if (_doctorCodeController.text.trim().isEmpty) {
          _showError('Please enter your doctor code');
          return;
        }
        if (_doctorCodeController.text.trim().length != 6) {
          _showError('Doctor code must be 6 digits');
          return;
        }
      }
    }
    
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.pastelPetal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    
    try {
      if (_isDoctor) {
        await _authService.registerDoctor(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          specialization: _specializationController.text.trim().isEmpty
              ? null
              : _specializationController.text.trim(),
        );
      } else {
        // Validate age if provided
        int? age;
        if (_ageController.text.isNotEmpty) {
          age = int.tryParse(_ageController.text);
          if (age == null || age < 1 || age > 120) {
            _showError('Please enter a valid age between 1 and 120');
            setState(() => _isLoading = false);
            return;
          }
        }
        
        await _authService.registerPatient(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          doctorCode: _doctorCodeController.text.trim(),
          age: age,
          gender: _selectedGender,
          bloodGroup: _selectedBloodGroup,
        );
      }

      if (mounted) {
        _nextStep();
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _progressValue => (_currentStep + 1) / _steps.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1RoleSelection(),
                  _buildStep2AccountInfo(),
                  _buildStep3Details(),
                  _buildStep4Success(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.elevation1,
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.honeydew,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.wisteriaBlue),
              ),
              onPressed: _previousStep,
            )
          else
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.honeydew,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close_rounded, size: 20, color: AppColors.wisteriaBlue),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Create Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            'Step ${_currentStep + 1}/${_steps.length}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: _progressValue,
              backgroundColor: AppColors.lightBackground,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.wisteriaBlue),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _steps[_currentStep],
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.wisteriaBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1RoleSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Choose Your Role',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select how you\'ll use Chemo Monitor',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildRoleCard(
            title: 'I\'m a Doctor',
            subtitle: 'Healthcare Provider',
            icon: Icons.medical_services_rounded,
            color: AppColors.wisteriaBlue,
            isSelected: _isDoctor,
            onTap: () {
              setState(() => _isDoctor = true);
              Future.delayed(const Duration(milliseconds: 300), _nextStep);
            },
          ),
          const SizedBox(height: 20),
          _buildRoleCard(
            title: 'I\'m a Patient',
            subtitle: 'Health Monitoring',
            icon: Icons.person_rounded,
            color: AppColors.frozenWater,
            isSelected: !_isDoctor,
            onTap: () {
              setState(() => _isDoctor = false);
              Future.delayed(const Duration(milliseconds: 300), _nextStep);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? AppShadows.elevation3 : AppShadows.elevation1,
          border: Border.all(
            color: isSelected ? color : AppColors.lightBackground,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 40,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2AccountInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Account Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your basic details',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _passwordController,
              label: 'Password',
              showPassword: _showPassword,
              onToggle: () => setState(() => _showPassword = !_showPassword),
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPasswordStrengthIndicator(),
            ],
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              showPassword: _showConfirmPassword,
              onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    text: 'Back',
                    isPrimary: false,
                    onPressed: _previousStep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    text: 'Next',
                    isPrimary: true,
                    onPressed: _nextStep,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _passwordStrength == PasswordStrength.weak
                ? 0.33
                : _passwordStrength == PasswordStrength.medium
                    ? 0.66
                    : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: _getPasswordStrengthColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _passwordStrength == PasswordStrength.weak
              ? 'Weak password'
              : _passwordStrength == PasswordStrength.medium
                  ? 'Medium strength'
                  : 'Strong password',
          style: TextStyle(
            fontSize: 11,
            color: _getPasswordStrengthColor(),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            _isDoctor ? 'Professional Details' : 'Health Profile',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isDoctor ? 'Tell us about your practice' : 'Help us understand your needs',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          if (_isDoctor) ...[
            // DOCTOR FIELDS
            _buildTextField(
              controller: _specializationController,
              label: 'Specialization (Optional)',
              icon: Icons.medical_services_outlined,
              hint: 'e.g., Oncology, Cardiology',
            ),
          ] else ...[
            // PATIENT FIELDS
            
            // 🆕 FIND YOUR DOCTOR BUTTON
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.frozenWater.withOpacity(0.1),
                    AppColors.wisteriaBlue.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.frozenWater.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: AppShadows.elevation1,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    // Navigate to Doctor Directory
                    final selectedCode = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoctorDirectoryScreen(),
                      ),
                    );
                    
                    // If doctor was selected, auto-fill the code
                    if (selectedCode != null && selectedCode.isNotEmpty) {
                      setState(() {
                        _doctorCodeController.text = selectedCode;
                      });
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('Doctor code added: $selectedCode'),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.softGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.frozenWater,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.frozenWater.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Find Your Doctor',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Browse doctors and get their 6-digit code',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Arrow
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.frozenWater.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.frozenWater,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // OR DIVIDER
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR ENTER CODE MANUALLY',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // DOCTOR CODE INPUT
            _buildTextField(
              controller: _doctorCodeController,
              label: 'Doctor Code *',
              icon: Icons.vpn_key_outlined,
              hint: '6-digit code',
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 16),
            
            // AGE
            _buildTextField(
              controller: _ageController,
              label: 'Age (Optional)',
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              hint: 'Enter your age',
            ),
            
            const SizedBox(height: 16),
            
            // GENDER
            _buildDropdown(
              value: _selectedGender,
              label: 'Gender (Optional)',
              icon: Icons.wc_outlined,
              items: const ['Male', 'Female', 'Other'],
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            
            const SizedBox(height: 16),
            
            // BLOOD GROUP
            _buildDropdown(
              value: _selectedBloodGroup,
              label: 'Blood Group (Optional)',
              icon: Icons.bloodtype_outlined,
              items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
              onChanged: (value) => setState(() => _selectedBloodGroup = value),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // BUTTONS
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  text: 'Back',
                  isPrimary: false,
                  onPressed: _previousStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  text: _isLoading ? 'Creating...' : 'Create Account',
                  isPrimary: true,
                  onPressed: _isLoading ? null : _handleRegister,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Success() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.frozenWater,
              shape: BoxShape.circle,
              boxShadow: AppShadows.elevation3,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to Chemo Monitor!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your account has been created successfully',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.honeydew.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.frozenWater.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.frozenWater,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _isDoctor
                        ? 'Share your doctor code with patients to start monitoring'
                        : 'You can now start tracking your health',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildButton(
            text: 'Continue to Dashboard',
            isPrimary: true,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.elevation1,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.wisteriaBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.wisteriaBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.elevation1,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !showPassword,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.wisteriaBlue),
          suffixIcon: IconButton(
            icon: Icon(
              showPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary,
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.wisteriaBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.elevation1,
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.wisteriaBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.wisteriaBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required bool isPrimary,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.wisteriaBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isPrimary ? null : Border.all(color: AppColors.wisteriaBlue, width: 2),
        boxShadow: isPrimary ? AppShadows.elevation2 : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPrimary ? Colors.white : AppColors.wisteriaBlue,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

enum PasswordStrength { weak, medium, strong }