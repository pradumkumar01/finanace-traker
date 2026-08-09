import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/finance_controller.dart';
import '../widgets/transaction_card.dart';
import '../theme/app_theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions'), centerTitle: false),
      body: GetBuilder<FinanceController>(
        builder: (provider) {
          final transactions = provider.transactions.where((t) {
            final query = _searchQuery.toLowerCase();
            return t.category.toLowerCase().contains(query) ||
                (t.notes?.toLowerCase().contains(query) ?? false);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                        ),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          return TransactionCard(
                            transaction: transactions[index],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
