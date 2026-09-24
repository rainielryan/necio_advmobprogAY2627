import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart' as models;

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      data['loginType'] = 'dummyjson';
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// **Save User Data to SharedPreferences**
  /// Save user data from API response based on User model
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = models.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setString(
      'token',
      userData['token'] ?? user.accessToken,
    );
    await prefs.setInt('age', user.age);
    await prefs.setString('phone', user.phone);
    await prefs.setString('loginType', user.loginType);

    if (user.loginType == 'firebase' && user.email.isNotEmpty) {
      await prefs.setString(
        _profileKey(user.email),
        jsonEncode({
          'id': user.id,
          'username': user.username,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'age': user.age,
          'phone': user.phone,
        }),
      );
    }
  }

  String _profileKey(String email) => 'firebase_profile_${email.toLowerCase()}';

  Future<Map<String, dynamic>> _savedFirebaseProfile(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(email));
    if (raw == null || raw.isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Retrieve user data from SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'phone': prefs.getString('phone') ?? '',
      'loginType': prefs.getString('loginType') ?? 'dummyjson',
    };
  }

  Future<String> loginType() async {
    final userData = await getUserData();
    return userData['loginType'] as String? ?? 'dummyjson';
  }

  /// Retrieve User model from SharedPreferences
  Future<models.User> getUser() async {
    final userData = await getUserData();
    return models.User.fromJson(userData);
  }

  /// **Check if User is Logged In**
  Future<bool> isLoggedIn() async {
    if (currentUser != null) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    final token = prefs.getString('token') ?? '';
    return accessToken.isNotEmpty || token.isNotEmpty;
  }

  Future<Map<String, dynamic>> registerDummyJsonUser({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$host/users/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'phone': contactNo,
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(response.body);
    }
  }

  Future<void> saveFirebaseSession({
    String? firstName,
    String? lastName,
    int? age,
    String? contactNo,
    String? username,
    int? id,
  }) async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) {
      throw Exception('No Firebase user');
    }

    final token = await firebaseUser.getIdToken(true);
    final existing = await getUserData();
    final saved = await _savedFirebaseProfile(firebaseUser.email ?? '');
    final displayName = firebaseUser.displayName ?? '';
    final displayParts =
        displayName.split(' ').where((part) => part.isNotEmpty).toList();

    await saveUserData({
      'id': id ?? existing['id'] ?? saved['id'] ?? 0,
      'username': username ??
          (existing['username'] != ''
              ? existing['username']
              : (saved['username'] ?? displayName)),
      'email': firebaseUser.email ?? existing['email'] ?? '',
      'firstName': firstName ??
          (existing['firstName'] != ''
              ? existing['firstName']
              : (saved['firstName'] ??
                  (displayParts.isNotEmpty ? displayParts.first : ''))),
      'lastName': lastName ??
          (existing['lastName'] != ''
              ? existing['lastName']
              : (saved['lastName'] ??
                  (displayParts.length > 1
                      ? displayParts.sublist(1).join(' ')
                      : ''))),
      'age': age ??
          ((existing['age'] is int && existing['age'] != 0)
              ? existing['age']
              : (saved['age'] ?? 0)),
      'phone': contactNo ??
          (existing['phone'] != ''
              ? existing['phone']
              : (saved['phone'] ?? '')),
      'gender': existing['gender'] ?? '',
      'image': firebaseUser.photoURL ?? existing['image'] ?? '',
      'accessToken': token ?? '',
      'refreshToken': firebaseUser.refreshToken ?? '',
      'loginType': 'firebase',
    });
  }

  // ENHANCEMENT 1: Logout clears the DummyJSON session/token and Firebase auth.
  Future<void> logout() async {
    try {
      if (currentUser != null) {
        await signOut();
      }
      final prefs = await SharedPreferences.getInstance();
      final keptProfiles = <String, String>{};
      for (final key in prefs.getKeys()) {
        if (key.startsWith('firebase_profile_')) {
          keptProfiles[key] = prefs.getString(key) ?? '';
        }
      }
      await prefs.clear();
      for (final entry in keptProfiles.entries) {
        await prefs.setString(entry.key, entry.value);
      }
    } catch (e) {
      throw Exception('Failed to logout');
    }
  }

  // ENHANCEMENT 1: Firebase Auth UserService functions.
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // ENHANCEMENT 1: Sign in with Firebase email and password.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ENHANCEMENT 1: Create a Firebase account with email and password.
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ENHANCEMENT 1: Sign out of the current Firebase session.
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  // ENHANCEMENT 1: Update the Firebase display name.
  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  // ENHANCEMENT 1: Re-authenticate, then delete the Firebase account.
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  // ENHANCEMENT 1: Re-authenticate, then change the Firebase password.
  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}
