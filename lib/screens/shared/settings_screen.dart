import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/models/user_model.dart';
import 'package:chemo_monitor_app/screens/shared/profile_edit_screen.dart';
import 'package:chemo_monitor_app/screens/shared/login_screen.dart';

// Add this if not in your constants
class AppInfo {
  static const String appName = 'Chemo Monitor';
  static const String version = '1.0.0';
  static const String description = 'Oncology patient monitoring app with AI-powered risk assessment and real-time health tracking.';
}

// Password strength enum
enum PasswordStrength {
  weak,
  medium,
  strong,
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  UserModel? _userProfile;
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadPreferences();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _notificationsEnabled = true;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.riskHighBg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: AppColors.riskHigh,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: AppTextStyles.heading3,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.riskHigh,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: AppColors.riskHigh,
            ),
          );
        }
      }
    }
  }

  // ✅ Change Password Functionality
  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    // Password visibility states
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;
    
    // Password strength tracking
    PasswordStrength passwordStrength = PasswordStrength.weak;
    bool isPasswordLoading = false;

    // Calculate password strength
    PasswordStrength calculatePasswordStrength(String password) {
      int score = 0;
      
      if (password.length >= 8) score++;
      if (password.contains(RegExp(r'[a-z]'))) score++;
      if (password.contains(RegExp(r'[A-Z]'))) score++;
      if (password.contains(RegExp(r'[0-9]'))) score++;
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
      
      if (score >= 4) return PasswordStrength.strong;
      if (score >= 2) return PasswordStrength.medium;
      return PasswordStrength.weak;
    }

    Color getPasswordStrengthColor(PasswordStrength strength) {
      switch (strength) {
        case PasswordStrength.weak:
          return AppColors.riskHigh;
        case PasswordStrength.medium:
          return AppColors.riskModerate;
        case PasswordStrength.strong:
          return AppColors.softGreen;
      }
    }

    String getPasswordStrengthText(PasswordStrength strength) {
      switch (strength) {
        case PasswordStrength.weak:
          return 'Weak password';
        case PasswordStrength.medium:
          return 'Medium strength';
        case PasswordStrength.strong:
          return 'Strong password';
      }
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Update strength when password changes
          void updateStrength() {
            setState(() {
              passwordStrength = calculatePasswordStrength(newPasswordController.text);
            });
          }

          Widget buildRequirement(String text, bool isMet) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    isMet ? Icons.check_circle : Icons.circle_outlined,
                    size: 14,
                    color: isMet ? AppColors.softGreen : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTextStyles.caption.copyWith(
                        color: isMet ? AppColors.softGreen : AppColors.textSecondary,
                        decoration: isMet ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          void showSnackBar(String message, Color color) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: color,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Change Password',
                    style: AppTextStyles.heading3,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Password
                  TextField(
                    controller: currentPasswordController,
                    obscureText: !showCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryBlue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.primaryBlue,
                        ),
                        onPressed: () {
                          setState(() => showCurrentPassword = !showCurrentPassword);
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // New Password with real-time strength validation
                  TextField(
                    controller: newPasswordController,
                    obscureText: !showNewPassword,
                    onChanged: (value) => updateStrength(),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      prefixIcon: Icon(Icons.lock, color: AppColors.primaryBlue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showNewPassword ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.primaryBlue,
                        ),
                        onPressed: () {
                          setState(() => showNewPassword = !showNewPassword);
                        },
                      ),
                    ),
                  ),
                  
                  // Password Strength Indicator
                  if (newPasswordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Column(
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
                            widthFactor: passwordStrength == PasswordStrength.weak
                                ? 0.33
                                : passwordStrength == PasswordStrength.medium
                                    ? 0.66
                                    : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: getPasswordStrengthColor(passwordStrength),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Strength Text
                        Row(
                          children: [
                            Icon(
                              passwordStrength == PasswordStrength.strong
                                  ? Icons.check_circle
                                  : passwordStrength == PasswordStrength.medium
                                      ? Icons.warning_amber_rounded
                                      : Icons.error,
                              size: 14,
                              color: getPasswordStrengthColor(passwordStrength),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              getPasswordStrengthText(passwordStrength),
                              style: AppTextStyles.caption.copyWith(
                                color: getPasswordStrengthColor(passwordStrength),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Confirm Password
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryBlue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.primaryBlue,
                        ),
                        onPressed: () {
                          setState(() => showConfirmPassword = !showConfirmPassword);
                        },
                      ),
                    ),
                  ),
                  
                  // Password Requirements
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
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
                        const SizedBox(height: 8),
                        buildRequirement(
                          'At least 8 characters',
                          newPasswordController.text.length >= 8,
                        ),
                        buildRequirement(
                          'One uppercase letter',
                          newPasswordController.text.contains(RegExp(r'[A-Z]')),
                        ),
                        buildRequirement(
                          'One lowercase letter',
                          newPasswordController.text.contains(RegExp(r'[a-z]')),
                        ),
                        buildRequirement(
                          'One number',
                          newPasswordController.text.contains(RegExp(r'[0-9]')),
                        ),
                        buildRequirement(
                          'One special character',
                          newPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isPasswordLoading ? null : () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isPasswordLoading ? AppColors.textSecondary : AppColors.primaryBlue,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  disabledBackgroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                onPressed: isPasswordLoading ? null : () async {
                  // ✅ COMPREHENSIVE VALIDATION
                  
                  // 1. Check if fields are empty
                  if (currentPasswordController.text.isEmpty) {
                    showSnackBar(
                      'Please enter your current password',
                      AppColors.riskModerate,
                    );
                    return;
                  }
                  
                  if (newPasswordController.text.isEmpty) {
                    showSnackBar(
                      'Please enter a new password',
                      AppColors.riskModerate,
                    );
                    return;
                  }
                  
                  // 2. ✅ VALIDATE PASSWORD STRENGTH
                  if (passwordStrength == PasswordStrength.weak) {
                    showSnackBar(
                      'Password is too weak. Please use a stronger password',
                      AppColors.riskHigh,
                    );
                    return;
                  }
                  
                  // 3. Check if passwords match
                  if (newPasswordController.text != confirmPasswordController.text) {
                    showSnackBar(
                      'New passwords do not match',
                      AppColors.riskModerate,
                    );
                    return;
                  }
                  
                  // 4. ✅ VALIDATE MINIMUM LENGTH
                  if (newPasswordController.text.length < 8) {
                    showSnackBar(
                      'Password must be at least 8 characters',
                      AppColors.riskModerate,
                    );
                    return;
                  }
                  
                  // 5. ✅ CHECK PASSWORD COMPLEXITY
                  final password = newPasswordController.text;
                  final hasUppercase = password.contains(RegExp(r'[A-Z]'));
                  final hasLowercase = password.contains(RegExp(r'[a-z]'));
                  final hasNumber = password.contains(RegExp(r'[0-9]'));
                  final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
                  
                  if (!hasUppercase || !hasLowercase || !hasNumber) {
                    showSnackBar(
                      'Password must contain uppercase, lowercase, and numbers',
                      AppColors.riskModerate,
                    );
                    return;
                  }
                  
                  // 6. Check if new password is different from current
                  if (currentPasswordController.text == newPasswordController.text) {
                    showSnackBar(
                      'New password must be different from current password',
                      AppColors.riskModerate,
                    );
                    return;
                  }
                  
                  setState(() => isPasswordLoading = true);
                  
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null || user.email == null) {
                      throw Exception('User not logged in');
                    }
                    
                    // Reauthenticate
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: currentPasswordController.text,
                    );
                    
                    await user.reauthenticateWithCredential(credential);
                    
                    // Update password
                    await user.updatePassword(newPasswordController.text);
                    
                    // Success
                    Navigator.pop(context, true);
                    
                  } on FirebaseAuthException catch (e) {
                    setState(() => isPasswordLoading = false);
                    
                    String errorMessage;
                    switch (e.code) {
                      case 'wrong-password':
                      case 'invalid-credential':
                        errorMessage = 'Current password is incorrect';
                        break;
                      case 'weak-password':
                        errorMessage = 'Password is too weak';
                        break;
                      case 'requires-recent-login':
                        errorMessage = 'Please log out and log in again to change password';
                        break;
                      case 'network-request-failed':
                        errorMessage = 'Network error. Check your connection';
                        break;
                      default:
                        errorMessage = 'Error: ${e.message}';
                    }
                    
                    showSnackBar(errorMessage, AppColors.riskHigh);
                  } catch (e) {
                    setState(() => isPasswordLoading = false);
                    showSnackBar(
                      'Unexpected error: ${e.toString()}',
                      AppColors.riskHigh,
                    );
                  }
                },
                child: isPasswordLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Password updated successfully!')),
            ],
          ),
          backgroundColor: AppColors.softGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ Notification Toggle
  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.primaryBlue,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _userProfile?.profileImageUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    _userProfile!.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          _userProfile?.name.isNotEmpty == true
                                              ? _userProfile!.name[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _userProfile?.name.isNotEmpty == true
                                        ? _userProfile!.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userProfile?.name ?? 'User',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FirebaseAuth.instance.currentUser?.email ?? '',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _userProfile?.role == 'doctor' ? 'Doctor' : 'Patient',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Settings Sections
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Account Section
                        _buildSection(
                          title: 'Account',
                          items: [
                            SettingsItem(
                              icon: Icons.person_outlined,
                              title: 'Edit Profile',
                              subtitle: 'Update your personal information',
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileEditScreen(),
                                  ),
                                );
                                _loadUserProfile(); // Reload after edit
                              },
                            ),
                            SettingsItem(
                              icon: Icons.lock_outlined,
                              title: 'Change Password',
                              subtitle: 'Update your password',
                              onTap: _changePassword,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Preferences Section (Language option REMOVED)
                        _buildSection(
                          title: 'Preferences',
                          items: [
                            SettingsItem(
                              icon: Icons.notifications_outlined,
                              title: 'Notifications',
                              subtitle: 'Manage notification settings',
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Notification Settings'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SwitchListTile(
                                          title: const Text('Enable Notifications'),
                                          value: _notificationsEnabled,
                                          onChanged: _toggleNotifications,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Receive alerts for high-risk patients, messages, and updates',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Done'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // About Section
                        _buildSection(
                          title: 'About',
                          items: [
                            SettingsItem(
                              icon: Icons.info_outlined,
                              title: 'About App',
                              subtitle: 'Version ${AppInfo.version}',
                              onTap: () {
                                _showAboutDialog(context);
                              },
                            ),
                            SettingsItem(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              subtitle: 'View our privacy policy',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Privacy policy document will be available soon',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: AppColors.primaryBlue,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SettingsItem(
                              icon: Icons.description_outlined,
                              title: 'Terms of Service',
                              subtitle: 'View terms and conditions',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Terms of Service document will be available soon',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: AppColors.primaryBlue,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Additional Settings
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                            boxShadow: AppShadows.elevation1,
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBlue,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                  ),
                                  child: Icon(
                                    Icons.storage_rounded,
                                    color: AppColors.primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  'Storage',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text('Cloudinary Storage Active'),
                                trailing: Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.softGreen,
                                  size: 20,
                                ),
                              ),
                              const Divider(height: 1, indent: 68),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBlue,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                  ),
                                  child: Icon(
                                    Icons.data_usage_rounded,
                                    color: AppColors.primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  'Data Usage',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text('Firebase Database Active'),
                                trailing: Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.softGreen,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Logout Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                            boxShadow: AppShadows.elevation1,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleLogout,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.riskHighBg,
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                      ),
                                      child: Icon(
                                        Icons.logout_rounded,
                                        color: AppColors.riskHigh,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'Sign Out',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.riskHigh,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: AppColors.riskHigh,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: AppShadows.elevation1,
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildSettingsItem(item),
                  if (index < items.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 68,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(SettingsItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Icon(
                  item.icon,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppInfo.appName,
              style: AppTextStyles.heading3,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version ${AppInfo.version}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppInfo.description,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'Storage: Cloudinary\nDatabase: Firebase\nML Model: TFLite\nAI Chat: Mistral AI',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                '© 2024 Chemo Monitor. All rights reserved.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}