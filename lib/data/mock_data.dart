import 'package:finance/models/goal_model.dart';
import 'package:finance/models/transaction_model.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const Map<String, List<String>> categories = {
  'income': ['Salary', 'Freelance', 'Investment', 'Gift', 'Other'],
  'expense': [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Health',
    'Education',
    'Other',
  ],
};

const Map<String, IconData> categoryIcons = {
  // Income
  'Salary': LucideIcons.briefcase,
  'Freelance': LucideIcons.laptop,
  'Investment': LucideIcons.trendingUp,
  'Gift': LucideIcons.gift,

  // Expense
  'Food': LucideIcons.utensilsCrossed,
  'Transport': LucideIcons.car,
  'Shopping': LucideIcons.shoppingBag,
  'Entertainment': LucideIcons.film,
  'Bills': LucideIcons.receipt,
  'Health': LucideIcons.heart,
  'Education': LucideIcons.graduationCap,
  'Other': LucideIcons.moreHorizontal,
};

final List<TransactionModel> mockTransactions = [
  TransactionModel(
    id: '1',
    amount: 5000,
    type: 'income',
    category: 'Salary',
    date: DateTime.parse('2026-04-01'),
    notes: 'Monthly salary',
  ),
  TransactionModel(
    id: '2',
    amount: 45,
    type: 'expense',
    category: 'Food',
    date: DateTime.parse('2026-04-04'),
    notes: 'Lunch at cafe',
  ),
  TransactionModel(
    id: '3',
    amount: 120,
    type: 'expense',
    category: 'Shopping',
    date: DateTime.parse('2026-04-03'),
    notes: 'New shoes',
  ),
  TransactionModel(
    id: '4',
    amount: 30,
    type: 'expense',
    category: 'Transport',
    date: DateTime.parse('2026-04-03'),
    notes: 'Uber to work',
  ),
  TransactionModel(
    id: '5',
    amount: 800,
    type: 'income',
    category: 'Freelance',
    date: DateTime.parse('2026-04-02'),
    notes: 'Website project',
  ),
  TransactionModel(
    id: '6',
    amount: 85,
    type: 'expense',
    category: 'Bills',
    date: DateTime.parse('2026-04-01'),
    notes: 'Internet bill',
  ),
  TransactionModel(
    id: '7',
    amount: 50,
    type: 'expense',
    category: 'Entertainment',
    date: DateTime.parse('2026-03-30'),
    notes: 'Movie tickets',
  ),
  TransactionModel(
    id: '8',
    amount: 200,
    type: 'expense',
    category: 'Health',
    date: DateTime.parse('2026-03-28'),
    notes: 'Gym membership',
  ),
  TransactionModel(
    id: '9',
    amount: 35,
    type: 'expense',
    category: 'Food',
    date: DateTime.parse('2026-03-27'),
    notes: 'Groceries',
  ),
  TransactionModel(
    id: '10',
    amount: 500,
    type: 'income',
    category: 'Investment',
    date: DateTime.parse('2026-03-25'),
    notes: 'Stock dividend',
  ),
];

final List<GoalModel> mockGoals = [
  GoalModel(
    id: '1',
    title: 'Emergency Fund',
    targetAmount: 10000,
    currentAmount: 6500,
    deadline: DateTime.parse('2026-12-31'),
    icon: 'Shield',
  ),
  GoalModel(
    id: '2',
    title: 'Vacation to Japan',
    targetAmount: 3000,
    currentAmount: 1200,
    deadline: DateTime.parse('2026-08-01'),
    icon: 'Plane',
  ),
  GoalModel(
    id: '3',
    title: 'New Laptop',
    targetAmount: 2000,
    currentAmount: 1600,
    deadline: DateTime.parse('2026-06-30'),
    icon: 'Laptop',
  ),
];
