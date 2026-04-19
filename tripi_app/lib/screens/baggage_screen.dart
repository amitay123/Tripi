import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tripi_colors.dart';
import '../providers/booking_provider.dart';
import '../widgets/tripi_card.dart';

class BaggageScreen extends StatefulWidget {
  const BaggageScreen({super.key});

  @override
  State<BaggageScreen> createState() => _BaggageScreenState();
}

class _BaggageScreenState extends State<BaggageScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TripiColors.background,
      appBar: AppBar(
        backgroundColor: TripiColors.background,
        elevation: 0,
        title: Text('Add Baggage', style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Extra Baggage',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add more space for your memories.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TripiColors.onSurfaceVariant),
            ),
            const SizedBox(height: 48),
            TripiCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.luggage, size: 48, color: TripiColors.primary),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Checked Bag', style: Theme.of(context).textTheme.titleLarge),
                        Text('Up to 23kg', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildCounterButton(Icons.remove, () {
                        if (_count > 0) setState(() => _count--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('$_count', style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      _buildCounterButton(Icons.add, () {
                        setState(() => _count++);
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              'Total: \$${_count * 50}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<BookingProvider>().updateBaggage(_count);
                Navigator.pushNamed(context, '/confirmation');
              },
              child: const Text('Review & Pay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: TripiColors.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: TripiColors.onSurface),
      ),
    );
  }
}
