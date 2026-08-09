import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../controllers/finance_controller.dart';
import '../theme/app_theme.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Insights'), centerTitle: false),
      body: GetBuilder<FinanceController>(
        builder: (provider) {
          final expenses = provider.transactions
              .where((t) => t.type == 'expense')
              .toList();

          final categoryExp = <String, double>{};
          for (var t in expenses) {
            categoryExp[t.category] = (categoryExp[t.category] ?? 0) + t.amount;
          }
          final sortedExp = categoryExp.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final thisWeek = provider.getThisWeekExpenses();
          final weekChange = provider.getWeeklyChangePercentage();
          final topCategory = sortedExp.isNotEmpty
              ? sortedExp.first.key
              : 'N/A';

          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            children: [
              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: _buildInsightCard(
                      context,
                      title: 'This Week',
                      value: currencyFormat.format(thisWeek),
                      subtitle: 'Spending',
                      icon: LucideIcons.calendar,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: _buildInsightCard(
                      context,
                      title: 'Week Change',
                      value: '${weekChange.toStringAsFixed(1)}%',
                      subtitle: 'vs Last Week',
                      icon: LucideIcons.trendingDown,
                      color: weekChange > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // Category Breakdown Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category Breakdown',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm,
                      vertical: AppTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      'Top: $topCategory',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.orange),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // Category Bars
              ...sortedExp.map((entry) {
                final percentage =
                    (entry.value /
                        sortedExp.fold(0.0, (prev, e) => prev + e.value)) *
                    100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}% - ${currencyFormat.format(entry.value)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: AppTheme.spacingLg),
              // Total Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expenses',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        currencyFormat.format(
                          sortedExp.fold(0.0, (prev, e) => prev + e.value),
                        ),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
