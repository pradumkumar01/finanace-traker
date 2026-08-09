import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../controllers/finance_controller.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: GetBuilder<FinanceController>(
        builder: (provider) {
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Center(
                child: Obx(() {
                  final user = auth.firebaseUser.value;
                  return Column(
                    children: [
                      Text(
                        user?.displayName ?? 'User Profile',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      if (user?.email != null) ...[
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          user!.email!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  );
                }),
              ),
              const SizedBox(height: AppTheme.spacingXl),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: provider.isDarkMode,
                    onChanged: (val) => provider.toggleDarkMode(),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Total Transactions'),
                  trailing: Text(
                    provider.transactions.length.toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Active Goals'),
                  trailing: Text(
                    provider.goals.length.toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Card(
                child: ListTile(
                  leading: const Icon(LucideIcons.logOut, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () => auth.logout(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

