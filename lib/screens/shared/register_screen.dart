import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/screens/shared/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

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
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    
    // Listen to password changes to update strength
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

  // Calculate password strength
  void _updatePasswordStrength() {
    final password = _passwordController.text;
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    
    // Contains lowercase
    if (password.contains(RegExp(r'[a-z]'))) score++;
    
    // Contains uppercase
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    
    // Contains numbers
    if (password.contains(RegExp(r'[0-9]'))) score++;
    
    // Contains special characters
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

  String _getPasswordStrengthText() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return 'Weak password';
      case PasswordStrength.medium:
        return 'Medium strength';
      case PasswordStrength.strong:
        return 'Strong password';
    }
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return AppColors.riskHigh;
      case PasswordStrength.medium:
        return AppColors.riskModerate;
      case PasswordStrength.strong:
        return AppColors.softGreen;
    }
  }

  String _getPasswordStrengthDescription() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return 'Add uppercase, numbers, and special characters';
      case PasswordStrength.medium:
        return 'Good! Make it stronger with special characters';
      case PasswordStrength.strong:
        return 'Excellent! Your password is secure';
    }
  }

  List<String> _getPasswordRequirements() {
    return [
      'At least 8 characters',
      'One uppercase letter',
      'One lowercase letter',
      'One number',
      'One special character (!@#\$% etc.)',
    ];
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleRegister() async {
    // Validate password strength
    if (_passwordStrength == PasswordStrength.weak) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please use a stronger password for security'),
          backgroundColor: AppColors.riskHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      );
      return;
    }
    
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
        _nextStep(); // Go to success screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.riskHigh,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
        );
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
      backgroundColor: AppColors.mainBackground,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar with Progress
            _buildAppBar(),
            
            // Progress Bar
            _buildProgressBar(),
            
            // Content Area
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
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
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.elevation1,
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: AppDimensions.iconS,
                  color: AppColors.primaryBlue,
                ),
              ),
              onPressed: _previousStep,
            )
          else
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: AppDimensions.iconS,
                  color: AppColors.primaryBlue,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          
          SizedBox(width: AppDimensions.spaceM),
          
          Expanded(
            child: Text(
              'Create Your Account',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          
          Text(
            'Step ${_currentStep + 1} of ${_steps.length}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _progressValue,
            backgroundColor: AppColors.lightBlue,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            minHeight: 4,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          ),
          SizedBox(height: AppDimensions.spaceS),
          Text(
            _steps[_currentStep],
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Role Selection
  Widget _buildStep1RoleSelection() {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: AppDimensions.spaceXL),
          
          Text(
            'Choose Your Role',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppDimensions.spaceM),
          
          Text(
            'Select how you\'ll use Chemo Monitor',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppDimensions.spaceXXXL),
          
          // Doctor Card
          _buildRoleCard(
            title: 'I\'m a Doctor',
            subtitle: 'Healthcare Provider',
            icon: Icons.medical_services_rounded,
            isSelected: _isDoctor,
            onTap: () {
              setState(() => _isDoctor = true);
              _nextStep();
            },
            gradient: AppGradients.primary,
          ),
          
          SizedBox(height: AppDimensions.spaceXL),
          
          // Patient Card
          _buildRoleCard(
            title: 'I\'m a Patient',
            subtitle: 'I need health monitoring',
            icon: Icons.person_rounded,
            isSelected: !_isDoctor,
            onTap: () {
              setState(() => _isDoctor = false);
              _nextStep();
            },
            gradient: AppGradients.success,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Gradient gradient,
  }) {
    return AnimatedContainer(
      duration: AppAnimations.normal,
      height: AppDimensions.cardHeightLarge,
      decoration: BoxDecoration(
        gradient: isSelected ? gradient : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        boxShadow: isSelected ? AppShadows.elevation3 : AppShadows.elevation1,
        border: Border.all(
          color: isSelected ? Colors.transparent : AppColors.lightBlue,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: AppDimensions.iconXXL,
                      height: AppDimensions.iconXXL,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white.withOpacity(0.2)
                            : AppColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: AppDimensions.iconXL,
                        color: isSelected ? Colors.white : AppColors.primaryBlue,
                      ),
                    ),
                    
                    SizedBox(height: AppDimensions.spaceL),
                    
                    Text(
                      title,
                      style: AppTextStyles.heading3.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    
                    SizedBox(height: AppDimensions.spaceS),
                    
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
                if (isSelected)
                  Positioned(
                    top: AppDimensions.spaceL,
                    right: AppDimensions.spaceL,
                    child: Container(
                      padding: EdgeInsets.all(AppDimensions.spaceS),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: AppDimensions.iconM,
                        color: AppColors.softGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 2: Account Information
  Widget _buildStep2AccountInfo() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          Text(
            'Basic Information',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppDimensions.spaceM),
          
          Text(
            'Enter your account details',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          SizedBox(height: AppDimensions.spaceXXXL),
          
          // Name Field
          _buildInputField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your name' : null,
          ),
          
          SizedBox(height: AppDimensions.spaceL),
          
          // Email Field
          _buildInputField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          
          SizedBox(height: AppDimensions.spaceL),
          
          // Password Field with Strength Indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordField(
                controller: _passwordController,
                label: 'Password',
                showPassword: _showPassword,
                onToggleVisibility: () {
                  setState(() => _showPassword = !_showPassword);
                },
              ),
              
              SizedBox(height: AppDimensions.spaceS),
              
              // Password Strength Indicator
              if (_passwordController.text.isNotEmpty)
                _buildPasswordStrengthIndicator(),
              
              // Password Requirements List
              _buildPasswordRequirementsList(),
            ],
          ),
          
          SizedBox(height: AppDimensions.spaceL),
          
          // Confirm Password Field
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            showPassword: _showConfirmPassword,
            onToggleVisibility: () {
              setState(() => _showConfirmPassword = !_showConfirmPassword);
            },
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              if (value != null && _passwordStrength == PasswordStrength.weak) {
                return 'Password is too weak. Use a stronger password';
              }
              return null;
            },
          ),
          
          SizedBox(height: AppDimensions.spaceXXXL),
          
          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  text: 'Back',
                  type: ButtonType.secondary,
                  onPressed: _previousStep,
                ),
              ),
              
              SizedBox(width: AppDimensions.spaceL),
              
              Expanded(
                child: _buildButton(
                  text: 'Next',
                  type: ButtonType.primary,
                  onPressed: _nextStep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength Bar
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
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
        
        SizedBox(height: 4),
        
        // Strength Text
        Row(
          children: [
            Icon(
              _passwordStrength == PasswordStrength.strong
                  ? Icons.check_circle
                  : Icons.info_outline,
              size: 14,
              color: _getPasswordStrengthColor(),
            ),
            
            SizedBox(width: 4),
            
            Text(
              _getPasswordStrengthText(),
              style: AppTextStyles.caption.copyWith(
                color: _getPasswordStrengthColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
            
            Spacer(),
            
            Text(
              _getPasswordStrengthDescription(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordRequirementsList() {
    final password = _passwordController.text;
    
    return Container(
      margin: EdgeInsets.only(top: AppDimensions.spaceS),
      padding: EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.lightBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: AppDimensions.spaceS),
          
          ..._getPasswordRequirements().map((requirement) {
            bool isMet = false;
            
            if (requirement == 'At least 8 characters') {
              isMet = password.length >= 8;
            } else if (requirement == 'One uppercase letter') {
              isMet = password.contains(RegExp(r'[A-Z]'));
            } else if (requirement == 'One lowercase letter') {
              isMet = password.contains(RegExp(r'[a-z]'));
            } else if (requirement == 'One number') {
              isMet = password.contains(RegExp(r'[0-9]'));
            } else if (requirement == 'One special character (!@#\$% etc.)') {
              isMet = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
            }
            
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    isMet ? Icons.check_circle : Icons.circle,
                    size: 12,
                    color: isMet ? AppColors.softGreen : AppColors.textSecondary,
                  ),
                  
                  SizedBox(width: 6),
                  
                  Text(
                    requirement,
                    style: AppTextStyles.caption.copyWith(
                      color: isMet ? AppColors.softGreen : AppColors.textSecondary,
                      decoration: isMet ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Step 3: Role-specific Details
  Widget _buildStep3Details() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          Text(
            _isDoctor ? 'Professional Details' : 'Health Profile',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppDimensions.spaceM),
          
          Text(
            _isDoctor 
                ? 'Tell us about your practice'
                : 'Help us understand your health needs',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          SizedBox(height: AppDimensions.spaceXXXL),
          
          if (_isDoctor) ...[
            // Doctor: Specialization
            _buildInputField(
              controller: _specializationController,
              label: 'Specialization (Optional)',
              icon: Icons.medical_services_outlined,
              hint: 'e.g., Oncology, Cardiology',
            ),
          ] else ...[
            // Patient: Doctor Code
            _buildInputField(
              controller: _doctorCodeController,
              label: 'Doctor Code',
              icon: Icons.vpn_key_outlined,
              hint: '6-digit code from your doctor',
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter doctor code' : null,
            ),
            
            SizedBox(height: AppDimensions.spaceL),
            
            // Patient: Age
            _buildInputField(
              controller: _ageController,
              label: 'Age (Optional)',
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
            ),
            
            SizedBox(height: AppDimensions.spaceL),
            
            // Patient: Gender
            _buildDropdownField(
              value: _selectedGender,
              label: 'Gender (Optional)',
              icon: Icons.wc_outlined,
              items: ['Male', 'Female', 'Other'],
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            
            SizedBox(height: AppDimensions.spaceL),
            
            // Patient: Blood Group
            _buildDropdownField(
              value: _selectedBloodGroup,
              label: 'Blood Group (Optional)',
              icon: Icons.bloodtype_outlined,
              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
              onChanged: (value) => setState(() => _selectedBloodGroup = value),
            ),
          ],
          
          SizedBox(height: AppDimensions.spaceXXXL),
          
          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  text: 'Back',
                  type: ButtonType.secondary,
                  onPressed: _previousStep,
                ),
              ),
              
              SizedBox(width: AppDimensions.spaceL),
              
              Expanded(
                child: _buildButton(
                  text: _isLoading ? 'Creating...' : 'Create Account',
                  type: ButtonType.primary,
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

  // Step 4: Success Screen
  Widget _buildStep4Success() {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppGradients.success,
              shape: BoxShape.circle,
              boxShadow: AppShadows.elevation3,
            ),
            child: Icon(
              Icons.check_rounded,
              size: AppDimensions.iconXXL,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: AppDimensions.spaceXXXL),
          
          Text(
            'Welcome to Chemo Monitor!',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppDimensions.spaceL),
          
          Text(
            'Your account has been created successfully',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppDimensions.spaceXXXL),
          
          Container(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.paleGreen,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.softGreen,
                  size: AppDimensions.iconM,
                ),
                
                SizedBox(width: AppDimensions.spaceL),
                
                Expanded(
                  child: Text(
                    _isDoctor
                        ? 'Share your doctor code with patients to start monitoring'
                        : 'You can now start tracking your health and chatting with your doctor',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: AppDimensions.spaceXXXL),
          
          _buildButton(
            text: 'Continue to Dashboard',
            type: ButtonType.primary,
            onPressed: () {
              // Navigate to appropriate dashboard
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(), // Will auto-redirect based on role
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppShadows.elevation1,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primaryBlue,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            borderSide: BorderSide(
              color: AppColors.primaryBlue,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceXL,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppShadows.elevation1,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !showPassword,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: AppColors.primaryBlue,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              showPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.primaryBlue,
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            borderSide: BorderSide(
              color: AppColors.primaryBlue,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceXL,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppShadows.elevation1,
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primaryBlue,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            borderSide: BorderSide(
              color: AppColors.primaryBlue,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceXL - 4,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: AppTextStyles.bodyLarge,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        style: AppTextStyles.bodyLarge,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        icon: Icon(
          Icons.arrow_drop_down_rounded,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required ButtonType type,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    Color backgroundColor;
    Color textColor;
    List<BoxShadow> shadows;
    
    switch (type) {
      case ButtonType.primary:
        backgroundColor = AppColors.primaryBlue;
        textColor = Colors.white;
        shadows = AppShadows.buttonShadow;
        break;
      case ButtonType.secondary:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primaryBlue;
        shadows = [];
        break;
    }
    
    return AnimatedContainer(
      duration: AppAnimations.fast,
      height: AppDimensions.buttonHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: type == ButtonType.secondary
            ? Border.all(color: AppColors.primaryBlue, width: 2)
            : null,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          onTap: onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                duration: AppAnimations.fast,
                opacity: isLoading ? 0.0 : 1.0,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.spaceL),
                  child: Text(
                    text,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              if (isLoading)
                SizedBox(
                  width: AppDimensions.iconM,
                  height: AppDimensions.iconM,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ButtonType {
  primary,
  secondary,
}

enum PasswordStrength {
  weak,
  medium,
  strong,
}