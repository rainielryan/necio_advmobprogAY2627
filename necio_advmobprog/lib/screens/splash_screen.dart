import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// ENHANCEMENT 1: Custom splash UI with persistent authentication.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // ENHANCEMENT 1: Persistent auth — stay logged in or go to sign in.
  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final loggedIn = await _userService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      final userData = await _userService.getUserData();
      if (mounted) {
        await context.read<CartService>().loadUserCart();
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: userData,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/nubdexchange_logo.png',
                width: 180.w,
              ),
              SizedBox(height: 16.h),
              CustomText(
                text: 'NUBD Exchange',
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: 40.h),
                child: SizedBox(
                  width: 28.w,
                  height: 28.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFFFD54F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
