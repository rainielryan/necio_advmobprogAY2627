import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

const _navy = Color(0xFF0D47A1);

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ENHANCEMENT 2: Login through UserService and persist the session.
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userService = UserService();
      final cartService = context.read<CartService>();
      final response = await userService.loginUser(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      // Save user data to SharedPreferences
      await userService.saveUserData(response);
      await cartService.loadUserCart();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: _navy, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/nubdexchange_logo.png',
                      width: 56.w,
                    ),
                    SizedBox(width: 12.w),
                    CustomText(
                      text: 'Welcome',
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                SizedBox(height: 48.h),
                TextFormField(
                  controller: _usernameController,
                  decoration: _fieldDecoration('Username'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _fieldDecoration('Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : CustomText(
                            text: 'Log In',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
}
