import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Centralized analytics service wrapping Firebase Analytics.
/// All tracking calls in the app go through this singleton.
class AnalyticsService extends GetxService {
  static AnalyticsService get to => Get.find();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ──────────────────────────────────────────────────────
  // User identity
  // ──────────────────────────────────────────────────────

  /// Associate all subsequent events with the authenticated user.
  Future<void> setUserId(String uid) async {
    try {
      await _analytics.setUserId(id: uid);
    } catch (e) {
      debugPrint('[Analytics] setUserId error: $e');
    }
  }

  /// Clear user identity on logout.
  Future<void> clearUserId() async {
    try {
      await _analytics.setUserId(id: null);
    } catch (e) {
      debugPrint('[Analytics] clearUserId error: $e');
    }
  }

  // ──────────────────────────────────────────────────────
  // Screen tracking
  // ──────────────────────────────────────────────────────

  /// Log a screen view event.
  /// [screenName] should be a snake_case identifier (e.g. 'home_screen').
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('[Analytics] Screen: $screenName');
    } catch (e) {
      debugPrint('[Analytics] logScreenView error: $e');
    }
  }

  // ──────────────────────────────────────────────────────
  // Auth events (standard Firebase event names)
  // ──────────────────────────────────────────────────────

  /// Log a sign-up event. [method] is 'email' or 'google'.
  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      debugPrint('[Analytics] sign_up method=$method');
    } catch (e) {
      debugPrint('[Analytics] logSignUp error: $e');
    }
  }

  /// Log a login event. [method] is 'email' or 'google'.
  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      debugPrint('[Analytics] login method=$method');
    } catch (e) {
      debugPrint('[Analytics] logLogin error: $e');
    }
  }

  /// Log a logout custom event.
  Future<void> logLogout() async {
    try {
      await _analytics.logEvent(name: 'logout');
      debugPrint('[Analytics] logout');
    } catch (e) {
      debugPrint('[Analytics] logLogout error: $e');
    }
  }

  // ──────────────────────────────────────────────────────
  // Finance events (custom)
  // ──────────────────────────────────────────────────────

  /// Fired when the user adds a new transaction.
  Future<void> logAddTransaction({
    required String type,
    required double amount,
    required String category,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'add_transaction',
        parameters: {
          'type': type,
          'amount': amount,
          'category': category,
        },
      );
      debugPrint('[Analytics] add_transaction type=$type amount=$amount category=$category');
    } catch (e) {
      debugPrint('[Analytics] logAddTransaction error: $e');
    }
  }

  /// Fired when the user deletes a transaction.
  Future<void> logDeleteTransaction({required String type}) async {
    try {
      await _analytics.logEvent(
        name: 'delete_transaction',
        parameters: {'type': type},
      );
      debugPrint('[Analytics] delete_transaction type=$type');
    } catch (e) {
      debugPrint('[Analytics] logDeleteTransaction error: $e');
    }
  }

  /// Fired when the user creates a new savings goal.
  Future<void> logAddGoal({required double targetAmount}) async {
    try {
      await _analytics.logEvent(
        name: 'add_goal',
        parameters: {'target_amount': targetAmount},
      );
      debugPrint('[Analytics] add_goal target_amount=$targetAmount');
    } catch (e) {
      debugPrint('[Analytics] logAddGoal error: $e');
    }
  }

  /// Fired when the user contributes to an existing goal.
  Future<void> logUpdateGoal({required double amountAdded}) async {
    try {
      await _analytics.logEvent(
        name: 'update_goal',
        parameters: {'amount_added': amountAdded},
      );
      debugPrint('[Analytics] update_goal amount_added=$amountAdded');
    } catch (e) {
      debugPrint('[Analytics] logUpdateGoal error: $e');
    }
  }

  /// Fired when the user deletes a goal.
  Future<void> logDeleteGoal() async {
    try {
      await _analytics.logEvent(name: 'delete_goal');
      debugPrint('[Analytics] delete_goal');
    } catch (e) {
      debugPrint('[Analytics] logDeleteGoal error: $e');
    }
  }

  /// Fired when the user toggles the dark/light theme.
  Future<void> logToggleDarkMode({required bool isDarkMode}) async {
    try {
      await _analytics.logEvent(
        name: 'toggle_dark_mode',
        parameters: {'dark_mode_enabled': isDarkMode},
      );
      debugPrint('[Analytics] toggle_dark_mode isDarkMode=$isDarkMode');
    } catch (e) {
      debugPrint('[Analytics] logToggleDarkMode error: $e');
    }
  }
}
