import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/models/user_model.dart';
import 'package:chemo_monitor_app/screens/shared/profile_edit_screen.dart';
import 'package:chemo_monitor_app/screens/shared/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
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
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
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
              Text(
                'Change Password',
                style: AppTextStyles.heading3,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: !_showCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _showCurrentPassword = !_showCurrentPassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: !_showNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNewPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _showNewPassword = !_showNewPassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _showConfirmPassword = !_showConfirmPassword);
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
                        'Password must contain:',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• At least 8 characters\n• One uppercase letter\n• One lowercase letter\n• One number',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                // Validate inputs
                if (currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your current password'),
                      backgroundColor: AppColors.riskModerate,
                    ),
                  );
                  return;
                }
                
                if (newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a new password'),
                      backgroundColor: AppColors.riskModerate,
                    ),
                  );
                  return;
                }
                
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match'),
                      backgroundColor: AppColors.riskModerate,
                    ),
                  );
                  return;
                }
                
                if (newPasswordController.text.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 8 characters'),
                      backgroundColor: AppColors.riskModerate,
                    ),
                  );
                  return;
                }
                
                // Check if new password is different from current
                if (currentPasswordController.text == newPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New password must be different from current password'),
                      backgroundColor: AppColors.riskModerate,
                    ),
                  );
                  return;
                }
                
                setState(() => _isLoading = true);
                
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    throw Exception('User not logged in');
                  }
                  
                  if (user.email == null) {
                    throw Exception('User email not available');
                  }
                  
                  // Try to reauthenticate with current password
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );
                  
                  await user.reauthenticateWithCredential(credential);
                  
                  // Update password
                  await user.updatePassword(newPasswordController.text);
                  
                  // Success - close dialog and show success message
                  Navigator.pop(context, true);
                  
                } catch (e) {
                  setState(() => _isLoading = false);
                  
                  String errorMessage = 'Error updating password';
                  
                  if (e is FirebaseAuthException) {
                    switch (e.code) {
                      case 'wrong-password':
                        errorMessage = 'Current password is incorrect';
                        break;
                      case 'weak-password':
                        errorMessage = 'Password is too weak. Use a stronger password';
                        break;
                      case 'requires-recent-login':
                        errorMessage = 'Please log in again to change password';
                        break;
                      case 'user-not-found':
                        errorMessage = 'User account not found';
                        break;
                      case 'user-disabled':
                        errorMessage = 'User account is disabled';
                        break;
                      case 'invalid-credential':
                        errorMessage = 'Invalid credentials';
                        break;
                      case 'network-request-failed':
                        errorMessage = 'Network error. Check your internet connection';
                        break;
                      default:
                        errorMessage = 'Error: ${e.message}';
                    }
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: AppColors.riskHigh,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: _isLoading
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

  if (result == true) {
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: AppColors.softGreen,
          duration: Duration(seconds: 3),
        ),
      );
    }
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
                            _SettingsItem(
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
                            _SettingsItem(
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
                            _SettingsItem(
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
                            // ❌ LANGUAGE OPTION COMPLETELY REMOVED
                          ],
                        ),

                        const SizedBox(height: 16),

                        // About Section
                        _buildSection(
                          title: 'About',
                          items: [
                            _SettingsItem(
                              icon: Icons.info_outlined,
                              title: 'About App',
                              subtitle: 'Version ${AppInfo.version}',
                              onTap: () {
                                _showAboutDialog(context);
                              },
                            ),
                            _SettingsItem(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              subtitle: 'View our privacy policy',
                              onTap: () {
                                // Show snackbar instead of opening URL
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
                            _SettingsItem(
                              icon: Icons.description_outlined,
                              title: 'Terms of Service',
                              subtitle: 'View terms and conditions',
                              onTap: () {
                                // Show snackbar instead of opening URL
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
    required List<_SettingsItem> items,
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
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.lightBlue,
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

  Widget _buildSettingsItem(_SettingsItem item) {
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

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}