import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/tripi_colors.dart';
import '../services/mock_data_service.dart';
import '../widgets/tripi_card.dart';
import '../providers/booking_provider.dart';

class FlightSearchScreen extends StatelessWidget {
  const FlightSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TripiColors.background,
      appBar: AppBar(
        backgroundColor: TripiColors.background,
        elevation: 0,
        title: Text(
          'Available Flights',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TripiColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24.0),
        itemCount: MockDataService.flights.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final flight = MockDataService.flights[index];
          return TripiCard(
            onTap: () {
              context.read<BookingProvider>().selectFlight(flight);
              Navigator.pushNamed(context, '/seat-selection');
            },
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStation(context, flight.from, 'New York'),
                    const Icon(Icons.flight_takeoff, color: TripiColors.primary),
                    _buildStation(context, flight.to, 'Paris', crossAxisAlignment: CrossAxisAlignment.end),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: TripiColors.surfaceContainerLow),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flight.airline,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          DateFormat('MMM dd, HH:mm').format(flight.departure),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: TripiColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${flight.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: TripiColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStation(BuildContext context, String code, String city, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          code,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: TripiColors.onSurface,
              ),
        ),
        Text(
          city,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TripiColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
