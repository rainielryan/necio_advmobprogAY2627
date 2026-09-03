import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// ENHANCEMENT 3: Profile screen that renders the saved User model.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUser();
  }

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
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
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
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
                          backgroundImage: user.image.isNotEmpty
                              ? NetworkImage(user.image)
                              : null,
                          child: user.image.isEmpty
                              ? Icon(Icons.person, size: 36.sp)
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        CustomText(
                          text: '${user.firstName} ${user.lastName}',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 4.h),
                        CustomText(
                          text: '@${user.username}',
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
                  value: user.email,
                ),
                _InfoRow(
                  icon: Icons.wc_outlined,
                  label: 'Gender',
                  value: user.gender,
                ),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'User ID',
                  value: '#${user.id}',
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7043),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: CustomText(
                      text: 'Log Out',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        text: value,
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
