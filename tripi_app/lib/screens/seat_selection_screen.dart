import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tripi_colors.dart';
import '../providers/booking_provider.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  String? _tempSeat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TripiColors.background,
      appBar: AppBar(
        backgroundColor: TripiColors.background,
        elevation: 0,
        title: Text('Select Seat',
            style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('CABIN FRONT',
                      style: TextStyle(
                          letterSpacing: 2,
                          color: TripiColors.onSurfaceVariant,
                          fontSize: 12)),
                  const SizedBox(height: 40),
                  for (var row in [1, 2, 3, 4, 5, 6, 7, 8])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var col in ['A', 'B', 'C', ' ', 'D', 'E', 'F'])
                            if (col == ' ')
                              const SizedBox(width: 40)
                            else
                              _buildSeat(context, '$row$col'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Selected Seat',
                        style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      _tempSeat ?? 'None',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: TripiColors.primary,
                              fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _tempSeat == null
                      ? null
                      : () {
                          context
                              .read<BookingProvider>()
                              .selectSeat(_tempSeat!);
                          Navigator.pushNamed(context, '/baggage');
                        },
                  child: const Text('Confirm Seat'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeat(BuildContext context, String seatId) {
    final isSelected = _tempSeat == seatId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tempSeat = seatId;
        });
      },
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? TripiColors.primary
              : TripiColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            seatId.substring(seatId.length - 1),
            style: TextStyle(
              color: isSelected ? Colors.white : TripiColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
