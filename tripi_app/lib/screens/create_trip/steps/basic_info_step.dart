import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/trip_provider.dart';
import '../../../services/mock_data_service.dart';
import '../../../utils/geo_data.dart';
import '../../../services/places_service.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({super.key});

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final PlacesService _placesService = PlacesService();
  TextEditingController? _internalCountryController;
  TextEditingController? _internalCityController;

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final draft = tripProvider.draftTrip!;

    final String selectedCountryCode = draft.countryCode ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where to next?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Explore over 200 countries and thousands of cities.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildLabel('Trip Name'),
          TextField(
            onChanged: (val) => tripProvider.updateDraft(draft.copyWith(name: val)),
            decoration: _inputDecoration('e.g. My Dream Vacation'),
            controller: TextEditingController(text: draft.name)..selection = TextSelection.collapsed(offset: draft.name.length),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          _buildLabel('Country'),
          
          Autocomplete<Map<String, dynamic>>(
            initialValue: TextEditingValue(text: draft.country),
            displayStringForOption: (option) => option['description'] as String,
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
              return await _placesService.autocompleteCountries(textEditingValue.text);
            },
            onSelected: (selection) async {
              // we just have the description and place_id
              // We could fetch details to get the country_code, but for now we store place_id
              // actually we should fetch details to get the country code so city search can be restricted
              final details = await _placesService.getPlaceDetails(selection['place_id']);
              
              tripProvider.updateDraft(draft.copyWith(
                country: details?['name'] ?? selection['description'],
                countryCode: details?['country_code'] ?? '',
                city: '',
                cityPlaceId: '',
                coverImageUrl: _placesService.getPhotoUrl(details?['photo_reference']),
              ));
              _internalCityController?.text = '';
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              _internalCountryController = controller;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (val) {
                  tripProvider.updateDraft(draft.copyWith(country: val, city: '', countryCode: '', cityPlaceId: ''));
                  _internalCityController?.text = '';
                },
                decoration: _inputDecoration('Search country...'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              );
            },
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.public),
                        title: Text(option['description'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          _buildLabel('City'),
          Opacity(
            opacity: draft.country.isNotEmpty ? 1.0 : 0.5,
            child: AbsorbPointer(
              absorbing: draft.country.isEmpty,
              child: Autocomplete<Map<String, dynamic>>(
                initialValue: TextEditingValue(text: draft.city ?? ''),
                displayStringForOption: (option) => option['description'] as String,
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                  return await _placesService.autocompleteCities(textEditingValue.text, selectedCountryCode);
                },
                onSelected: (selection) async {
                  final details = await _placesService.getPlaceDetails(selection['place_id']);
                  
                  final cityPhoto = _placesService.getPhotoUrl(details?['photo_reference']);
                  final finalPhoto = cityPhoto ?? draft.coverImageUrl;
                  
                  tripProvider.updateDraft(draft.copyWith(
                    city: details?['name'] ?? selection['description'],
                    cityPlaceId: selection['place_id'],
                    coverImageUrl: finalPhoto,
                  ));
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _internalCityController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (val) => tripProvider.updateDraft(draft.copyWith(city: val, cityPlaceId: '')),
                    decoration: _inputDecoration(
                      draft.country.isEmpty ? 'Select country first' : 'Search city...',
                    ),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) => Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8.0,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 48,
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
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
          
          const SizedBox(height: 32),
          _buildPopularCountries(context, tripProvider, draft),
        ],
      ),
    );
  }

  Widget _buildPopularCountries(BuildContext context, TripProvider tripProvider, dynamic draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('POPULAR DESTINATIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MockDataService.popularCountries.map((s) {
            final isSelected = draft.country == s;
            return ActionChip(
              label: Text(s),
              onPressed: () async {
                final results = await _placesService.autocompleteCountries(s);
                if (results.isNotEmpty) {
                  final details = await _placesService.getPlaceDetails(results.first['place_id']);
                  tripProvider.updateDraft(draft.copyWith(
                    country: s,
                    city: '',
                    countryCode: details?['country_code'] ?? '',
                    cityPlaceId: '',
                    coverImageUrl: _placesService.getPhotoUrl(details?['photo_reference']),
                  ));
                } else {
                  tripProvider.updateDraft(draft.copyWith(country: s, city: '', countryCode: '', cityPlaceId: ''));
                }
                _internalCountryController?.text = s;
                _internalCityController?.text = '';
              },
              backgroundColor: isSelected ? const Color(0xFFDBEAFE) : Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF374151),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), 
                side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  Widget _optionsView(BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width - 48,
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
            itemBuilder: (BuildContext context, int index) {
              final String option = options.elementAt(index);
              return ListTile(
                title: Text(option, style: const TextStyle(fontSize: 14)),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B5563), fontSize: 11, letterSpacing: 1),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}



