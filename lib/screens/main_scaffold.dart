import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/analytics_service.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import 'goals_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'add_transaction_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  static const List<String> _screenNames = [
    'home_screen',
    'transactions_screen',
    'goals_screen',
    'insights_screen',
    'profile_screen',
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const TransactionsScreen(),
    const GoalsScreen(),
    const InsightsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Log screen view for the selected tab
          AnalyticsService.to.logScreenView(_screenNames[index]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.target),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.pieChart),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }
}
