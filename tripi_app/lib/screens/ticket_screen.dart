import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/tripi_colors.dart';
import '../providers/booking_provider.dart';
import '../widgets/tripi_card.dart';

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final flight = booking.selectedFlight;

    if (flight == null) {
      return const Scaffold(body: Center(child: Text('No active ticket')));
    }

    return Scaffold(
      backgroundColor: TripiColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Ticket', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: TripiCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTicketInfo('PASSENGER', 'Amitay'),
                  _buildTicketInfo('CLASS', 'Economy', crossAxisAlignment: CrossAxisAlignment.end),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStation(context, flight.from, 'New York'),
                  const Icon(Icons.flight, color: TripiColors.primary),
                  _buildStation(context, flight.to, 'Paris', crossAxisAlignment: CrossAxisAlignment.end),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTicketInfo('DATE', DateFormat('MMM dd, yyyy').format(flight.departure)),
                  _buildTicketInfo('GATE', 'G24', crossAxisAlignment: CrossAxisAlignment.end),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTicketInfo('SEAT', booking.selectedSeat ?? 'TBA'),
                  _buildTicketInfo('BAGGAGE', '${booking.extraBaggageCount + 1}pc', crossAxisAlignment: CrossAxisAlignment.end),
                ],
              ),
              const SizedBox(height: 48),
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: TripiColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('||||||||||||||||||||||||||||||||||||||||', style: TextStyle(letterSpacing: 4, fontSize: 24)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketInfo(String label, String value, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: TripiColors.onSurfaceVariant, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStation(BuildContext context, String code, String city, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(city, style: const TextStyle(fontSize: 12, color: TripiColors.onSurfaceVariant)),
      ],
    );
  }
}
