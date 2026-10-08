import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

const _navy = Color(0xFF0D47A1);

// ENHANCEMENT 3: Fetch getUserData() and show details based on LoginType.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUserData();
  }

  void _reload() {
    setState(() {
      _userFuture = _userService.getUserData();
    });
  }

  bool _isFirebase(Map<String, dynamic> user) =>
      user['loginType'] == 'firebase';

  // ENHANCEMENT 1: Logout button — clears session/token and redirects to login.
  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  Future<void> _updateUsername(Map<String, dynamic> user) async {
    final controller = TextEditingController(
      text: '${user['username'] ?? ''}',
    );
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: CustomText(
          text: 'Update Username',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (username == null || username.isEmpty) return;

    try {
      if (_isFirebase(user)) {
        await _userService.updateUsername(username: username);
      }
      final updated = Map<String, dynamic>.from(user);
      updated['username'] = username;
      await _userService.saveUserData(updated);
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update username: $e')),
      );
    }
  }

  Future<void> _changePassword(Map<String, dynamic> user) async {
    if (!_isFirebase(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Change password is available for Firebase accounts.'),
        ),
      );
      return;
    }

    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: CustomText(
          text: 'Change Password',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    final currentPassword = currentController.text;
    final newPassword = newController.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentController.dispose();
      newController.dispose();
    });

    if (confirmed != true) return;
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters'),
        ),
      );
      return;
    }

    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        email: '${user['email']}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change password: $e')),
      );
    }
  }

  Future<void> _deleteAccount(Map<String, dynamic> user) async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: CustomText(
          text: 'Delete Account',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              text: _isFirebase(user)
                  ? 'Enter your password to delete this Firebase account.'
                  : 'This will clear your DummyJSON session and return to login.',
              fontSize: 14.sp,
            ),
            if (_isFirebase(user)) ...[
              SizedBox(height: 12.h),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    final password = passwordController.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      passwordController.dispose();
    });

    if (confirmed != true) return;

    try {
      if (_isFirebase(user)) {
        await _userService.deleteAccount(
          email: '${user['email']}',
          password: password,
        );
      }
      await _userService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: CustomText(
              text: 'Unable to load profile.',
              fontSize: 14.sp,
            ),
          );
        }

        final user = snapshot.data!;
        final isFirebase = _isFirebase(user);
        final firstName = '${user['firstName'] ?? ''}';
        final lastName = '${user['lastName'] ?? ''}';
        final username = '${user['username'] ?? ''}';
        final image = '${user['image'] ?? ''}';

        return SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 20.h,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36.r,
                        backgroundColor: const Color(0xFFE3F2FD),
                        backgroundImage:
                            image.isNotEmpty ? NetworkImage(image) : null,
                        child: image.isEmpty
                            ? Icon(Icons.person, size: 36.sp)
                            : null,
                      ),
                      SizedBox(height: 12.h),
                      CustomText(
                        text: '$firstName $lastName'.trim().isEmpty
                            ? username
                            : '$firstName $lastName',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        text: '@$username',
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: '${user['email'] ?? ''}',
              ),
              if (isFirebase) ...[
                _InfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Age',
                  value: '${user['age'] ?? 0}',
                ),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Contact No',
                  value: '${user['phone'] ?? ''}',
                ),
              ] else ...[
                _InfoRow(
                  icon: Icons.wc_outlined,
                  label: 'Gender',
                  value: '${user['gender'] ?? ''}',
                ),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'User ID',
                  value: '#${user['id'] ?? 0}',
                ),
              ],
              SizedBox(height: 16.h),
              _ActionButton(
                label: 'Update Username',
                icon: Icons.edit_outlined,
                color: _navy,
                onPressed: () => _updateUsername(user),
              ),
              SizedBox(height: 10.h),
              _ActionButton(
                label: 'Change Password',
                icon: Icons.lock_outline,
                color: _navy,
                onPressed: () => _changePassword(user),
              ),
              SizedBox(height: 10.h),
              _ActionButton(
                label: 'Delete Account',
                icon: Icons.delete_outline,
                color: const Color(0xFFE53935),
                onPressed: () => _deleteAccount(user),
              ),
              SizedBox(height: 10.h),
              // ENHANCEMENT 1: Logout button on the profile screen.
              _ActionButton(
                label: 'Log Out',
                icon: Icons.logout,
                color: const Color(0xFFFF7043),
                onPressed: _logout,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        icon: Icon(icon),
        label: CustomText(
          text: label,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 22.sp),
      title: CustomText(
        text: label,
        fontSize: 12.sp,
        color: Colors.grey,
      ),
      subtitle: CustomText(
        text: value.isEmpty ? '—' : value,
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
