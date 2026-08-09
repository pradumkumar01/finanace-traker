import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/mock_data.dart';
import '../services/analytics_service.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final Rxn<User> firebaseUser = Rxn<User>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Bind the auth state stream to firebaseUser Rx variable
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  // Sign up with Email, Password and Name
  Future<bool> signUp(String name, String email, String password) async {
    try {
      isLoading.value = true;

      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      User? user = userCredential.user;
      if (user != null) {
        // Update user display name in Firebase Auth
        await user.updateDisplayName(name.trim());
        await user.reload();

        // Save additional user info in Firestore
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name.trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Seed initial transactions in a batch
        final batch = _db.batch();
        for (var t in mockTransactions) {
          final docRef = _db
              .collection('users')
              .doc(user.uid)
              .collection('transactions')
              .doc();
          batch.set(docRef, t.toJson());
        }

        // Seed initial goals in a batch
        for (var g in mockGoals) {
          final docRef = _db
              .collection('users')
              .doc(user.uid)
              .collection('goals')
              .doc();
          batch.set(docRef, g.toJson());
        }

        await batch.commit();
        // Associate user with analytics
        await AnalyticsService.to.setUserId(user.uid);
        await AnalyticsService.to.logSignUp('email');
      }

      Get.snackbar(
        'Success',
        'Account created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green[800],
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Login with Email and Password
  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Associate user with analytics
      final user = _auth.currentUser;
      if (user != null) {
        await AnalyticsService.to.setUserId(user.uid);
        await AnalyticsService.to.logLogin('email');
      }

      Get.snackbar(
        'Success',
        'Logged in successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green[800],
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Invalid email or password.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      }

      Get.snackbar(
        'Login Failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await AnalyticsService.to.logLogout();
      await AnalyticsService.to.clearUserId();
      await _auth.signOut();
      await _googleSignIn.signOut();
      Get.snackbar(
        'Logged Out',
        'You have been logged out successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error Logging Out',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
      );
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      debugPrint('>>> [GoogleSignIn] Starting Google Sign-In...');

      // Trigger Google Auth Flow
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      debugPrint('>>> [GoogleSignIn] User: ${googleUser.email}');

      // Get ID Token
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      debugPrint(
        '>>> [GoogleSignIn] idToken: ${googleAuth.idToken != null ? 'Present' : 'NULL'}',
      );

      if (googleAuth.idToken == null) {
        throw Exception(
          'Google idToken is null. Check SHA-1/SHA-256, Firebase setup, and Web Client ID.',
        );
      }

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('>>> [FirebaseAuth] Signing in...');

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      debugPrint('>>> [FirebaseAuth] User UID: ${user?.uid}');

      if (user != null) {
        final userRef = _db.collection('users').doc(user.uid);
        final userDoc = await userRef.get();

        if (!userDoc.exists || userDoc.data()?['seeded'] != true) {
          final batch = _db.batch();

          batch.set(userRef, {
            'uid': user.uid,
            'name': user.displayName ?? 'Google User',
            'email': user.email ?? '',
            'photoUrl': user.photoURL,
            'seeded': true,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Seed default mock transactions
          for (final t in mockTransactions) {
            final docRef = userRef.collection('transactions').doc();
            batch.set(docRef, t.toJson());
          }

          // Seed default mock goals
          for (final g in mockGoals) {
            final docRef = userRef.collection('goals').doc();
            batch.set(docRef, g.toJson());
          }

          await batch.commit();
        }

        // Associate user with analytics
        await AnalyticsService.to.setUserId(user.uid);
        await AnalyticsService.to.logLogin('google');
      }

      Get.snackbar(
        'Success',
        'Logged in with Google successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green[800],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('Google Sign-In canceled by user.');
        return;
      }

      Get.snackbar(
        'Google Sign In Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Firebase Auth Failed',
        e.message ?? e.code,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
      );
    } catch (e) {
      Get.snackbar(
        'Google Sign In Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
      );
    } finally {
      isLoading.value = false;
    }
  }
}
