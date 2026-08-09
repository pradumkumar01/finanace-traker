import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../data/mock_data.dart';
import '../services/analytics_service.dart';
import 'auth_controller.dart';

class FinanceController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<TransactionModel> _transactions = [];
  List<GoalModel> _goals = [];
  bool _darkMode = false;

  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _goalsSubscription;

  List<TransactionModel> get transactions => _transactions;
  List<GoalModel> get goals => _goals;
  bool get isDarkMode => _darkMode;

  @override
  void onInit() {
    super.onInit();
    // Listen to user auth state changes to dynamically load/unload data
    ever(AuthController.to.firebaseUser, _handleUserChange);
  }

  Future<void> _checkAndSeedUser(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists || userDoc.data()?['seeded'] != true) {
        // User document doesn't exist or is not seeded
        final batch = _db.batch();

        // Register that the user is now seeded
        batch.set(_db.collection('users').doc(uid), {
          'uid': uid,
          'seeded': true,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Seed transactions
        for (var t in mockTransactions) {
          final docRef = _db.collection('users').doc(uid).collection('transactions').doc();
          batch.set(docRef, t.toJson());
        }

        // Seed goals
        for (var g in mockGoals) {
          final docRef = _db.collection('users').doc(uid).collection('goals').doc();
          batch.set(docRef, g.toJson());
        }

        await batch.commit();
      }
    } catch (e) {
      debugPrint('Seeding failed: $e');
    }
  }

  void _handleUserChange(User? user) {
    _transactionsSubscription?.cancel();
    _goalsSubscription?.cancel();

    if (user != null) {
      // Check and seed mock data if the collection is new or empty
      _checkAndSeedUser(user.uid);

      // User is logged in, listen to Firestore subcollections
      _transactionsSubscription = _db
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots()
          .listen((snapshot) {
        _transactions = snapshot.docs.map((doc) {
          return TransactionModel.fromJson(doc.data(), doc.id);
        }).toList();
        update();
      });

      _goalsSubscription = _db
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .snapshots()
          .listen((snapshot) {
        _goals = snapshot.docs.map((doc) {
          return GoalModel.fromJson(doc.data(), doc.id);
        }).toList();
        update();
      });
    } else {
      // User logged out, clear local cache
      _transactions = [];
      _goals = [];
      update();
    }
  }

  @override
  void onClose() {
    _transactionsSubscription?.cancel();
    _goalsSubscription?.cancel();
    super.onClose();
  }

  void addTransaction(TransactionModel transaction) {
    final user = AuthController.to.firebaseUser.value;
    if (user != null) {
      _db
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add(transaction.toJson());

      // Analytics
      AnalyticsService.to.logAddTransaction(
        type: transaction.type,
        amount: transaction.amount,
        category: transaction.category,
      );
    }
  }

  void updateTransaction(String id, TransactionModel updatedTransaction) {
    final user = AuthController.to.firebaseUser.value;
    if (user != null) {
      _db
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(id)
          .update(updatedTransaction.toJson());
    }
  }

  void deleteTransaction(String id) {
    final user = AuthController.to.firebaseUser.value;
    if (user != null) {
      // Find transaction type before deleting for analytics
      final tx = _transactions.firstWhereOrNull((t) => t.id == id);
      _db
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(id)
          .delete();

      // Analytics
      if (tx != null) {
        AnalyticsService.to.logDeleteTransaction(type: tx.type);
      }
    }
  }

  void updateGoal(String id, double currentAmount) {
    final user = AuthController.to.firebaseUser.value;
    if (user != null) {
      // Calculate how much was added for analytics
      final goal = _goals.firstWhereOrNull((g) => g.id == id);
      final previous = goal?.currentAmount ?? 0.0;
      final amountAdded = currentAmount - previous;

      _db
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(id)
          .update({'currentAmount': currentAmount});

      // Analytics
      if (amountAdded > 0) {
        AnalyticsService.to.logUpdateGoal(amountAdded: amountAdded);
      }
    }
  }

  void addGoal(GoalModel goal) {
    final user = AuthController.to.firebaseUser.value;
    if (user != null) {
      _db
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .add(goal.toJson());

      // Analytics
      AnalyticsService.to.logAddGoal(targetAmount: goal.targetAmount);
    }
  }

  void deleteGoal(String id) {
    final user = AuthController.to.firebaseUser.value;
    if (user != null) {
      _db
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .doc(id)
          .delete();

      // Analytics
      AnalyticsService.to.logDeleteGoal();
    }
  }

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    update();
    Get.changeThemeMode(_darkMode ? ThemeMode.dark : ThemeMode.light);

    // Analytics
    AnalyticsService.to.logToggleDarkMode(isDarkMode: _darkMode);
  }

  double getTotalIncome() {
    return _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (acc, t) => acc + t.amount);
  }

  double getTotalExpenses() {
    return _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (acc, t) => acc + t.amount);
  }

  double getBalance() {
    return getTotalIncome() - getTotalExpenses();
  }

  // Enhanced calculation methods for better insights

  /// Get spending by category with top 5
  Map<String, double> getExpensesByCategory() {
    final expenses = _transactions
        .where((t) => t.type == 'expense')
        .fold<Map<String, double>>({}, (acc, t) {
          acc[t.category] = (acc[t.category] ?? 0) + t.amount;
          return acc;
        });

    final sorted = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(5));
  }

  /// Get this week's expenses (last 7 days)
  double getThisWeekExpenses() {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));

    return _transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.isAfter(weekAgo) &&
              t.date.isBefore(now.add(Duration(days: 1))),
        )
        .fold(0.0, (acc, t) => acc + t.amount);
  }

  /// Get last week's expenses for comparison
  double getLastWeekExpenses() {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(Duration(days: 14));
    final weekAgo = now.subtract(Duration(days: 7));

    return _transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.isAfter(twoWeeksAgo) &&
              t.date.isBefore(weekAgo.add(Duration(days: 1))),
        )
        .fold(0.0, (acc, t) => acc + t.amount);
  }

  /// Get week-over-week percentage change
  double getWeeklyChangePercentage() {
    final lastWeek = getLastWeekExpenses();
    if (lastWeek == 0) return 0;

    final thisWeek = getThisWeekExpenses();
    return ((thisWeek - lastWeek) / lastWeek) * 100;
  }

  /// Get daily spending for the past 7 days
  Map<String, double> getDailySpendingTrend() {
    final daily = <String, double>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      daily[dayName] = 0;
    }

    _transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.isAfter(now.subtract(Duration(days: 7))),
        )
        .forEach((t) {
          final dayKey = _getDayName(t.date.weekday);
          daily[dayKey] = (daily[dayKey] ?? 0) + t.amount;
        });

    return daily;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Get monthly trend for past 6 months
  Map<String, double> getMonthlyTrend() {
    final monthly = <String, double>{};
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = _getMonthName(date.month);
      monthly[monthKey] = 0;
    }

    _transactions.where((t) => t.type == 'expense').forEach((t) {
      final monthKey = _getMonthName(t.date.month);
      if (monthly.containsKey(monthKey)) {
        monthly[monthKey] = (monthly[monthKey] ?? 0) + t.amount;
      }
    });

    return monthly;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Get top spending category
  String getTopSpendingCategory() {
    final categories = getExpensesByCategory();
    if (categories.isEmpty) return 'None';
    return categories.entries.first.key;
  }

  /// Get total goal progress
  double getTotalGoalProgress() {
    if (_goals.isEmpty) return 0;
    final totalTarget = _goals.fold(0.0, (acc, g) => acc + g.targetAmount);
    final totalCurrent = _goals.fold(0.0, (acc, g) => acc + g.currentAmount);
    return totalTarget == 0 ? 0 : (totalCurrent / totalTarget);
  }

  /// Get average transaction amount
  double getAverageTransactionAmount() {
    if (_transactions.isEmpty) return 0;
    final total = _transactions.fold(0.0, (acc, t) => acc + t.amount);
    return total / _transactions.length;
  }
}
