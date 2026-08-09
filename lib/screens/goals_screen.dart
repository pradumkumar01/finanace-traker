import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../controllers/finance_controller.dart';
import '../models/goal_model.dart';
import '../theme/app_theme.dart';
import 'add_goal_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  IconData _getGoalIcon(String iconName) {
    switch (iconName) {
      case 'Shield':
        return LucideIcons.shield;
      case 'Plane':
        return LucideIcons.plane;
      case 'Laptop':
        return LucideIcons.laptop;
      case 'Car':
        return LucideIcons.car;
      case 'Home':
        return LucideIcons.home;
      case 'Shopping':
        return LucideIcons.shoppingBag;
      case 'Gift':
        return LucideIcons.gift;
      case 'Trending':
        return LucideIcons.trendingUp;
      default:
        return LucideIcons.target;
    }
  }

  void _showGoalOptionsDialog(
    BuildContext context,
    FinanceController provider,
    GoalModel goal,
  ) {
    final updateController = TextEditingController(
      text: goal.currentAmount.toStringAsFixed(0),
    );
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Update saved for "${goal.title}"',
            style: theme.textTheme.titleMedium,
          ),
          content: TextField(
            controller: updateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Current Saved Amount',
              prefixText: '₹ ',
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          actions: [
            TextButton(
              onPressed: () {
                provider.deleteGoal(goal.id);
                Navigator.pop(context);
                Get.snackbar(
                  'Deleted',
                  'Goal deleted successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.red[800],
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(updateController.text) ?? 0.0;
                provider.updateGoal(goal.id, amount);
                Navigator.pop(context);
                Get.snackbar(
                  'Updated',
                  'Goal progress updated!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  colorText: Colors.green[800],
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals'), centerTitle: false),
      body: GetBuilder<FinanceController>(
        builder: (provider) {
          final goals = provider.goals;

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.target,
                    size: 64.0,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text('No Goals Yet', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Create a goal to start saving',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          // Calculate overall progress
          final totalTarget = goals.fold(0.0, (acc, g) => acc + g.targetAmount);
          final totalCurrent = goals.fold(
            0.0,
            (acc, g) => acc + g.currentAmount,
          );
          final overallProgress = totalTarget == 0
              ? 0.0
              : (totalCurrent / totalTarget);

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: goals.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Overall progress card
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Overall Progress',
                              style: theme.textTheme.titleMedium,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSm,
                                vertical: AppTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                              ),
                              child: Text(
                                '${(overallProgress * 100).toStringAsFixed(0)}%',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          child: LinearProgressIndicator(
                            value: overallProgress,
                            minHeight: 12,
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currencyFormat.format(totalCurrent),
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              'of ${currencyFormat.format(totalTarget)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              final goalIndex = index - 1;
              final goal = goals[goalIndex];
              final progress = (goal.currentAmount / goal.targetAmount).clamp(
                0.0,
                1.0,
              );

              final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
              final isUrgent = daysLeft < 30 && daysLeft > 0;
              final isExpired = daysLeft < 0;
              final isCompleted = progress >= 1;

              Color progressColor;
              if (isCompleted) {
                progressColor = AppTheme.incomeColor;
              } else if (isExpired) {
                progressColor = const Color(0xFFEF4444);
              } else if (isUrgent) {
                progressColor = const Color(0xFFF59E0B);
              } else {
                progressColor = const Color(0xFF3b82f6);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: InkWell(
                  onTap: () => _showGoalOptionsDialog(context, provider, goal),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: progressColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getGoalIcon(goal.icon),
                                      color: progressColor,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.title,
                                          style: theme.textTheme.headlineSmall,
                                        ),
                                        const SizedBox(
                                          height: AppTheme.spacingXs,
                                        ),
                                        if (isCompleted)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.incomeColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Completed ✓',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: AppTheme.incomeColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          )
                                        else if (isExpired)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFEF4444,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Expired',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: const Color(
                                                      0xFFEF4444,
                                                    ),
                                                  ),
                                            ),
                                          )
                                        else if (isUrgent)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFF59E0B,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Urgent!',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: const Color(
                                                      0xFFF59E0B,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: progressColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: progressColor.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currencyFormat.format(goal.currentAmount),
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  'of ${currencyFormat.format(goal.targetAmount)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isExpired && !isCompleted)
                                  Text(
                                    '${daysLeft.abs()} days',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: progressColor),
                                  )
                                else if (isExpired)
                                  Text(
                                    'Deadline passed',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: const Color(0xFFEF4444),
                                        ),
                                  )
                                else
                                  Text(
                                    'Goal achieved!',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: AppTheme.incomeColor),
                                  ),
                                Text(
                                  'Left: ${currencyFormat.format((goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity))}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddGoalScreen()),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}
