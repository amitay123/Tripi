import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/models.dart';
import '../../providers/trip_provider.dart';
import '../../theme/tripi_colors.dart';
import '../../services/places_service.dart';

class EditPreferencesModal extends StatefulWidget {
  final Trip trip;

  const EditPreferencesModal({super.key, required this.trip});

  static void show(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      builder: (context) => EditPreferencesModal(trip: trip),
    );
  }

  @override
  State<EditPreferencesModal> createState() => _EditPreferencesModalState();
}

class _EditPreferencesModalState extends State<EditPreferencesModal> {
  late TripType _selectedType;
  late TripPace _selectedPace;
  late List<String> _selectedPreferences;

  final List<String> _allPreferences = [
    'Nature', 'Culture', 'Food', 'Adventure', 'Relaxation', 
    'Shopping', 'Nightlife', 'History', 'Art', 'Beach'
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.trip.tripType;
    _selectedPace = widget.trip.pace;
    _selectedPreferences = List.from(widget.trip.preferences);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: TripiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trip Preferences',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: TripiColors.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Trip Type'),
              const SizedBox(height: 12),
              _buildTypeGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle('Travel Pace'),
              const SizedBox(height: 12),
              _buildPaceGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle('Interests'),
              const SizedBox(height: 12),
              _buildInterestsWrap(),
              const SizedBox(height: 40),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: TripiColors.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTypeGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: TripType.values.map((type) {
        final isSelected = _selectedType == type;
        return _buildChoiceChip(
          label: type.name[0].toUpperCase() + type.name.substring(1),
          selected: isSelected,
          onSelected: (selected) => setState(() => _selectedType = type),
        );
      }).toList(),
    );
  }

  Widget _buildPaceGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: TripPace.values.map((pace) {
        final isSelected = _selectedPace == pace;
        return _buildChoiceChip(
          label: pace.name[0].toUpperCase() + pace.name.substring(1),
          selected: isSelected,
          onSelected: (selected) => setState(() => _selectedPace = pace),
        );
      }).toList(),
    );
  }

  Widget _buildInterestsWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allPreferences.map((pref) {
        final isSelected = _selectedPreferences.contains(pref);
        return _buildFilterChip(
          label: pref,
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedPreferences.add(pref);
              } else {
                _selectedPreferences.remove(pref);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildChoiceChip({required String label, required bool selected, required Function(bool) onSelected}) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: TripiColors.surfaceContainerHigh,
      selectedColor: TripiColors.primary,
      labelStyle: GoogleFonts.inter(
        color: selected ? Colors.white : TripiColors.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }

  Widget _buildFilterChip({required String label, required bool selected, required Function(bool) onSelected}) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: TripiColors.surfaceContainerHigh,
      selectedColor: TripiColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: GoogleFonts.inter(
        color: selected ? Colors.white : TripiColors.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide.none,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: TripiColors.onSurfaceVariant,
            ),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final updatedTrip = widget.trip.copyWith(
                tripType: _selectedType,
                pace: _selectedPace,
                preferences: _selectedPreferences,
              );
              final provider = context.read<TripProvider>();
              provider.resumeTrip(updatedTrip);
              final success = await provider.saveTrip(isCompleted: widget.trip.isCompleted);
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TripiColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text('Update', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class EditTravelersModal extends StatefulWidget {
  final Trip trip;

  const EditTravelersModal({super.key, required this.trip});

  static void show(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      builder: (context) => EditTravelersModal(trip: trip),
    );
  }

  @override
  State<EditTravelersModal> createState() => _EditTravelersModalState();
}

class _EditTravelersModalState extends State<EditTravelersModal> {
  late int _adults;
  late int _children;
  late int _infants;

  @override
  void initState() {
    super.initState();
    _adults = widget.trip.travelersBreakdown['adults'] ?? 1;
    _children = widget.trip.travelersBreakdown['children'] ?? 0;
    _infants = widget.trip.travelersBreakdown['infants'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: TripiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Travelers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: TripiColors.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              _buildCounterRow('Adults', '12+ years', _adults, (val) => setState(() => _adults = val), min: 1),
              const SizedBox(height: 24),
              _buildCounterRow('Children', '2-12 years', _children, (val) => setState(() => _children = val)),
              const SizedBox(height: 24),
              _buildCounterRow('Infants', 'Under 2 years', _infants, (val) => setState(() => _infants = val)),
              const SizedBox(height: 48),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterRow(String title, String subtitle, int value, Function(int) onChanged, {int min = 0}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TripiColors.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: TripiColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: TripiColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: [
              _buildCircularButton(
                icon: Icons.remove,
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: TripiColors.onSurface,
                  ),
                ),
              ),
              _buildCircularButton(
                icon: Icons.add,
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularButton({required IconData icon, VoidCallback? onPressed}) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      color: TripiColors.primary,
      disabledColor: TripiColors.onSurfaceVariant.withValues(alpha: 0.3),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: TripiColors.onSurfaceVariant,
            ),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final updatedTrip = widget.trip.copyWith(
                travelersCount: _adults + _children,
                travelersBreakdown: {
                  'adults': _adults,
                  'children': _children,
                  'infants': _infants,
                },
              );
              final provider = context.read<TripProvider>();
              provider.resumeTrip(updatedTrip);
              final success = await provider.saveTrip(isCompleted: widget.trip.isCompleted);
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TripiColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text('Update', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class EditDetailsModal extends StatefulWidget {
  final Trip trip;

  const EditDetailsModal({super.key, required this.trip});

  static void show(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      builder: (context) => EditDetailsModal(trip: trip),
    );
  }

  @override
  State<EditDetailsModal> createState() => _EditDetailsModalState();
}

class _EditDetailsModalState extends State<EditDetailsModal> {
  final PlacesService _placesService = PlacesService();
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  
  // Track IDs and codes just like in wizard
  String? _selectedCountryCode;
  String? _selectedCityPlaceId;
  String? _selectedCoverImageUrl;

  late DateTime _startDate;
  late DateTime _endDate;

  Timer? _countryDebounce;
  Timer? _cityDebounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.name);
    _cityController = TextEditingController(text: widget.trip.city ?? '');
    _countryController = TextEditingController(text: widget.trip.country);
    _selectedCountryCode = widget.trip.countryCode;
    _selectedCityPlaceId = widget.trip.cityPlaceId;
    _selectedCoverImageUrl = widget.trip.coverImageUrl;
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _countryDebounce?.cancel();
    _cityDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: TripiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: TripiColors.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _nameController,
                label: 'Trip Name',
                icon: Icons.title,
              ),
              const SizedBox(height: 20),
              _buildAutocompleteField(
                controller: _countryController,
                label: 'Country',
                hint: 'Search country...',
                icon: Icons.public,
                isCountry: true,
              ),
              const SizedBox(height: 20),
              _buildAutocompleteField(
                key: ValueKey(_selectedCountryCode),
                controller: _cityController,
                label: 'City',
                hint: _selectedCountryCode?.isEmpty == true ? 'Select country first' : 'Search city...',
                icon: Icons.location_city,
                isCountry: false,
                enabled: _selectedCountryCode?.isNotEmpty == true,
              ),
              const SizedBox(height: 24),
              _buildDateSection(),
              const SizedBox(height: 16),
              _buildDurationBadge(),
              const SizedBox(height: 48),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutocompleteField({
    Key? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isCountry,
    bool enabled = true,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: TripiColors.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: AbsorbPointer(
            absorbing: !enabled,
            child: Autocomplete<Map<String, dynamic>>(
              initialValue: TextEditingValue(text: controller.text),
              displayStringForOption: (option) => option['description'] as String,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Map<String, dynamic>>.empty();
                }

                if (isCountry) {
                  if (_countryDebounce?.isActive ?? false) _countryDebounce!.cancel();
                  final completer = Completer<Iterable<Map<String, dynamic>>>();
                  _countryDebounce = Timer(const Duration(milliseconds: 500), () async {
                    final results = await _placesService.autocompleteCountries(textEditingValue.text);
                    completer.complete(results);
                  });
                  return completer.future;
                } else {
                  if (_cityDebounce?.isActive ?? false) _cityDebounce!.cancel();
                  final completer = Completer<Iterable<Map<String, dynamic>>>();
                  _cityDebounce = Timer(const Duration(milliseconds: 500), () async {
                    final results = await _placesService.autocompleteCities(
                      textEditingValue.text, _selectedCountryCode ?? '');
                    completer.complete(results);
                  });
                  return completer.future;
                }
              },
              onSelected: (selection) async {
                final details = await _placesService.getPlaceDetails(selection['place_id']);
                setState(() {
                  if (isCountry) {
                    _countryController.text = details?['name'] ?? selection['description'];
                    _selectedCountryCode = details?['country_code'] ?? '';
                    // Reset city if country changed
                    _cityController.text = '';
                    _selectedCityPlaceId = '';
                    _selectedCoverImageUrl = _placesService.getPhotoUrl(details?['photo_reference']);
                  } else {
                    _cityController.text = details?['name'] ?? selection['description'];
                    _selectedCityPlaceId = selection['place_id'];
                    final cityPhoto = _placesService.getPhotoUrl(details?['photo_reference']);
                    if (cityPhoto != null) _selectedCoverImageUrl = cityPhoto;
                  }
                });
              },
              fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
                // Keep controllers in sync
                if (fieldController.text != controller.text) {
                   fieldController.text = controller.text;
                }
                return TextField(
                  controller: fieldController,
                  focusNode: focusNode,
                  style: GoogleFonts.inter(color: TripiColors.onSurface),
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: true,
                    fillColor: TripiColors.surfaceContainerHigh,
                    prefixIcon: Icon(icon, color: TripiColors.primary, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8.0,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 300, // Fixed width for popover
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TripiColors.surfaceContainerHigh),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: TripiColors.surfaceContainerHigh),
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option['description'] as String, style: const TextStyle(fontSize: 14)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: TripiColors.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(color: TripiColors.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: TripiColors.surfaceContainerHigh,
            prefixIcon: Icon(icon, color: TripiColors.primary, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATES',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: TripiColors.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildDateTile('Departure', _startDate, true)),
            const SizedBox(width: 12),
            Expanded(child: _buildDateTile('Return', _endDate, false)),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationBadge() {
    final duration = _endDate.difference(_startDate).inDays + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: TripiColors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 16, color: TripiColors.primary),
          const SizedBox(width: 8),
          Text(
            'Duration: $duration ${duration == 1 ? 'day' : 'days'}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: TripiColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime date, bool isStart) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final picked = await showDatePicker(
          context: context,
          initialDate: isStart 
              ? (_startDate.isBefore(today) ? today : _startDate)
              : (_endDate.isBefore(_startDate) ? _startDate : _endDate),
          firstDate: isStart ? today : _startDate,
          lastDate: DateTime.now().add(const Duration(days: 3650)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: TripiColors.primary,
                  onPrimary: Colors.white,
                  onSurface: TripiColors.onSurface,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              _startDate = picked;
              if (_endDate.isBefore(_startDate)) {
                _endDate = _startDate;
              }
            } else {
              _endDate = picked;
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TripiColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TripiColors.outlineVariant.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: TripiColors.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: TripiColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: TripiColors.onSurfaceVariant,
            ),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final updatedTrip = widget.trip.copyWith(
                name: _nameController.text,
                city: _cityController.text,
                country: _countryController.text,
                countryCode: _selectedCountryCode,
                cityPlaceId: _selectedCityPlaceId,
                coverImageUrl: _selectedCoverImageUrl,
                startDate: _startDate,
                endDate: _endDate,
              );
              final provider = context.read<TripProvider>();
              provider.resumeTrip(updatedTrip);
              final success = await provider.saveTrip(isCompleted: widget.trip.isCompleted);
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TripiColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text('Update', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
