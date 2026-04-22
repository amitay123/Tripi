import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/trip_provider.dart';

class DatesTravelersStep extends StatelessWidget {
  const DatesTravelersStep({super.key});

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
            'Dates & Travelers',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          const Text(
            'When are you going and how many people are coming?',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildLabel('TRIP DATES'),
          Row(
            children: [
              Expanded(
                child: _buildDateCard(
                  context,
                  'Departure',
                  draft.startDate,
                  () => _selectDate(
                    context, 
                    draft.startDate, 
                    (d) {
                      tripProvider.updateDraft(draft.copyWith(startDate: d));
                      if (draft.endDate.isBefore(d)) {
                        tripProvider.updateDraft(draft.copyWith(endDate: d));
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateCard(
                  context,
                  'Return',
                  draft.endDate,
                  () => _selectDate(
                    context, 
                    draft.endDate, 
                    (d) => tripProvider.updateDraft(draft.copyWith(endDate: d)),
                    firstDate: draft.startDate, // Prevent selecting earlier date
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${draft.durationDays} days',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildLabel('NUMBER OF TRAVELERS'),
          const SizedBox(height: 8),
          _buildCounterRow(
            'Adults',
            draft.travelersBreakdown['adults'] ?? 1,
            (val) => tripProvider.setAdults(val),
          ),
          const SizedBox(height: 12),
          _buildCounterRow(
            'Children',
            draft.travelersBreakdown['children'] ?? 0,
            (val) => tripProvider.setChildren(val),
            min: 0,
          ),
          const SizedBox(height: 16),
          const Text(
            'Children are travelers under the age of 12.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(BuildContext context, String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF9FAFB),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, Function(int) onChanged, {int min = 1}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF9FAFB),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
          Row(
            children: [
              _buildCounterButton(Icons.remove, () => value > min ? onChanged(value - 1) : null),
              const SizedBox(width: 24),
              Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(width: 24),
              _buildCounterButton(Icons.add, () => onChanged(value + 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: onTap == null ? const Color(0xFFD1D5DB) : const Color(0xFF2563EB), size: 20),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B5563), fontSize: 12, letterSpacing: 0.5),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, DateTime initial, Function(DateTime) onSelected, {DateTime? firstDate}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate ?? today) ? (firstDate ?? today) : initial,
      firstDate: firstDate ?? today,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onSelected(picked);
  }
}
