import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tripi_colors.dart';
import '../../models/place_result.dart';
import '../../models/models.dart';
import '../../providers/trip_provider.dart';
import '../../services/places_service.dart';

class AddToItinerarySheet extends StatefulWidget {
  final PlaceResult place;
  final TripProvider tripProvider;
  final void Function(String tripName, int dayIndex) onAdded;

  const AddToItinerarySheet({
    super.key,
    required this.place,
    required this.tripProvider,
    required this.onAdded,
  });

  @override
  State<AddToItinerarySheet> createState() => _AddToItinerarySheetState();
}

class _AddToItinerarySheetState extends State<AddToItinerarySheet> {
  Trip? _selectedTrip;

  bool _alreadyAdded(Trip trip, int dayIndex) {
    final dayIdx = trip.days.indexWhere((d) => d.dayIndex == dayIndex);
    if (dayIdx == -1) return false;
    return trip.days[dayIdx].activities
        .any((a) => a.placeId == widget.place.placeId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFDDE5EF), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        if (_selectedTrip == null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Choose a Trip', style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.bold, color: TripiColors.onSurface,
            )),
          ),
          const SizedBox(height: 16),
          Flexible(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            itemCount: widget.tripProvider.trips.length,
            itemBuilder: (_, i) {
              final trip = widget.tripProvider.trips[i];
              return GestureDetector(
                onTap: () => setState(() => _selectedTrip = trip),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDDE5EF)),
                  ),
                  child: Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: TripiColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.luggage_rounded, color: TripiColors.primary, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(trip.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: TripiColors.onSurface)),
                      Text('${trip.days.length} days', style: GoogleFonts.inter(fontSize: 13, color: TripiColors.onSurfaceVariant)),
                    ])),
                    const Icon(Icons.chevron_right_rounded, color: TripiColors.onSurfaceVariant),
                  ]),
                ),
              );
            },
          )),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              GestureDetector(
                onTap: () => setState(() => _selectedTrip = null),
                child: const Icon(Icons.arrow_back_rounded, color: TripiColors.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Choose a Day', style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.bold, color: TripiColors.onSurface,
              ))),
            ]),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_selectedTrip!.name, style: GoogleFonts.inter(
              fontSize: 14, color: TripiColors.onSurfaceVariant,
            )),
          ),
          const SizedBox(height: 16),
          Flexible(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            itemCount: _selectedTrip!.days.length,
            itemBuilder: (_, i) {
              final day = _selectedTrip!.days[i];
              final already = _alreadyAdded(_selectedTrip!, day.dayIndex);
              return GestureDetector(
                onTap: already ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Already added to Day ${day.dayIndex}'),
                  ));
                } : () {
                  final activity = Activity(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: widget.place.name,
                    types: widget.place.types,
                    lat: widget.place.lat,
                    lng: widget.place.lng,
                    placeId: widget.place.placeId,
                    imageUrl: widget.place.photoReferences.isNotEmpty
                        ? PlacesService().getPhotoUrl(widget.place.photoReferences.first)
                        : null,
                    address: widget.place.formattedAddress,
                    rating: widget.place.rating,
                    source: 'api',
                  );
                  widget.tripProvider.addActivity(_selectedTrip!.id, day.dayIndex, activity);
                  Navigator.pop(context);
                  widget.onAdded(_selectedTrip!.name, day.dayIndex);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: already ? const Color(0xFFF0FDF4) : const Color(0xFFF3F6FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: already ? const Color(0xFF86EFAC) : const Color(0xFFDDE5EF),
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: (already ? const Color(0xFF22C55E) : TripiColors.primary).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text('${day.dayIndex}', style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: already ? const Color(0xFF22C55E) : TripiColors.primary,
                      ))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Day ${day.dayIndex}', style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600, color: TripiColors.onSurface,
                      )),
                      Text('${day.activities.length} activities', style: GoogleFonts.inter(
                        fontSize: 13, color: TripiColors.onSurfaceVariant,
                      )),
                    ])),
                    if (already)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('✓ Added', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A),
                        )),
                      )
                    else
                      const Icon(Icons.add_circle_outline_rounded, color: TripiColors.primary),
                  ]),
                ),
              );
            },
          )),
        ],
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ]),
    );
  }
}
