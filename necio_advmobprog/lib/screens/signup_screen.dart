import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

const _navy = Color(0xFF0D47A1);

// ENHANCEMENT 2: Signup screen mapped to DummyJSON user fields.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final age = int.parse(_ageController.text.trim());
    final contactNo = _contactNoController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final service = userService.value;
      final cartService = context.read<CartService>();

      // ENHANCEMENT 2: DummyJSON is optional. Firebase Auth creates the real account.
      Map<String, dynamic> dummyUser = {};
      try {
        dummyUser = await service.registerDummyJsonUser(
          firstName: firstName,
          lastName: lastName,
          age: age,
          contactNo: contactNo,
          username: username,
          email: email,
          password: password,
        );
      } catch (_) {
        dummyUser = {};
      }

      await service.createAccount(email: email, password: password);
      await service.updateUsername(username: username);
      await service.saveFirebaseSession(
        id: dummyUser['id'] is int ? dummyUser['id'] as int : 0,
        firstName: firstName,
        lastName: lastName,
        age: age,
        contactNo: contactNo,
        username: username,
      );
      await cartService.loadUserCart();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
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
            child: ListView(
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/nubdexchange_logo.png',
                      width: 56.w,
                    ),
                    SizedBox(width: 12.w),
                    CustomText(
                      text: 'Sign Up',
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                TextFormField(
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration('First Name'),
                  validator: (value) => _required(value, 'First name'),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _lastNameController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration('Last Name'),
                  validator: (value) => _required(value, 'Last name'),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _ageController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('Age'),
                  validator: (value) {
                    final requiredError = _required(value, 'Age');
                    if (requiredError != null) return requiredError;
                    final age = int.tryParse(value!.trim());
                    if (age == null || age < 1 || age > 120) {
                      return 'Enter a valid age';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _contactNoController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDecoration('Contact No'),
                  validator: (value) {
                    final requiredError = _required(value, 'Contact number');
                    if (requiredError != null) return requiredError;
                    if (!RegExp(r'^[0-9+\-() ]+$').hasMatch(value!.trim())) {
                      return 'Enter a valid contact number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration('Username'),
                  validator: (value) => _required(value, 'Username'),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _emailController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDecoration('Email Address'),
                  validator: (value) {
                    final requiredError = _required(value, 'Email address');
                    if (requiredError != null) return requiredError;
                    if (!value!.trim().contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: _fieldDecoration('Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
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
                            text: 'Sign Up',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                  ),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushReplacementNamed(context, '/signin'),
                  child: CustomText(
                    text: 'Already have an account? Log in',
                    fontSize: 14.sp,
                    color: _navy,
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
