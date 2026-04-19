import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/trip_provider.dart';

class BudgetStep extends StatelessWidget {
  const BudgetStep({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final draft = tripProvider.draftTrip!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your budget?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Estimate your total spending for the trip.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final budget = double.tryParse(val);
                    tripProvider.updateDraft(draft.copyWith(budgetTotal: budget));
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF6B7280)),
                    hintText: 'Total Budget',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  controller: TextEditingController(text: draft.budgetTotal?.toString() ?? '')..selection = TextSelection.collapsed(offset: (draft.budgetTotal?.toString() ?? '').length),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: draft.currency,
                      isExpanded: true,
                      items: ['USD', 'EUR', 'GBP', 'ILS', 'JPY'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) tripProvider.updateDraft(draft.copyWith(currency: val));
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          if (draft.budgetTotal != null && draft.budgetTotal! > 0)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 32),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ESTIMATED DAILY BUDGET', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        '${draft.currency} ${draft.budgetDaily?.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
