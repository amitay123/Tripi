import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/trip_provider.dart';
import '../../theme/tripi_colors.dart';
import '../../widgets/tripi_card.dart';
import '../../services/places_service.dart';

class AddActivityScreen extends StatefulWidget {
  final String tripId;
  final int dayIndex;

  const AddActivityScreen({super.key, required this.tripId, required this.dayIndex});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  TimeOfDay? _selectedTime;
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final PlacesService _placesService = PlacesService();
  double? _destLat;
  double? _destLng;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDestinationCoordinates();
  }

  Future<void> _loadDestinationCoordinates() async {
    final tripProvider = context.read<TripProvider>();
    final trip = tripProvider.trips.firstWhere(
      (t) => t.id == widget.tripId,
      orElse: () => tripProvider.draftTrip ?? tripProvider.trips.first,
    );

    String? placeId = trip.cityPlaceId;
    
    // If no city, we could search for the country's center, but for now 
    // we'll prioritize city if available.
    if (placeId != null && placeId.isNotEmpty) {
      final details = await _placesService.getPlaceDetails(placeId);
      if (details != null) {
        setState(() {
          _destLat = details['lat'];
          _destLng = details['lng'];
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    
    // Pass countryCode if available in draft
    final tripProvider = context.read<TripProvider>();
    final draft = tripProvider.trips.firstWhere((t) => t.id == widget.tripId, orElse: () => tripProvider.draftTrip ?? tripProvider.trips.first);
    
    final places = await _placesService.autocompletePlaces(
      query, 
      countryCode: draft.countryCode,
      lat: _destLat,
      lng: _destLng,
    );
    
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _searchResults = places.map((p) {
        final struct = p['structured_formatting'] ?? {};
        return {
          'name': struct['main_text'] ?? p['description'],
          'address': struct['secondary_text'] ?? p['description'],
          'place_id': p['place_id'],
        };
      }).toList();
    });
  }

  void _submitManual() {
    if (_titleController.text.isEmpty) return;
    
    final activity = Activity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text,
      notes: _notesController.text,
      startTime: _selectedTime != null ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}' : null,
      source: 'manual',
    );

    context.read<TripProvider>().addActivity(widget.tripId, widget.dayIndex, activity);
    Navigator.pop(context);
  }

  void _addFromSearch(Map<String, dynamic> place) async {
    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch place details for lat/lng and photo
    final details = await _placesService.getPlaceDetails(place['place_id']);
    
    if (mounted) {
      Navigator.pop(context); // hide loading
    }

    final activity = Activity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      title: details?['name'] ?? place['name'],
      address: details?['formatted_address'] ?? place['address'],
      lat: details?['lat'],
      lng: details?['lng'],
      types: details?['types'] != null ? List<String>.from(details!['types']) : null,
      imageUrl: _placesService.getPhotoUrl(details?['photo_reference']),
      placeId: place['place_id'],
      source: 'api',
    );

    if (mounted) {
      context.read<TripProvider>().addActivity(widget.tripId, widget.dayIndex, activity);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add Activity', style: TextStyle(color: Color(0xFF1E293B))),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: TripiColors.primary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: TripiColors.primary,
          tabs: const [
            Tab(text: 'Search Places'),
            Tab(text: 'Manual Entry'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildManualTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: TextField(
            controller: _searchController,
            onChanged: _searchPlaces,
            decoration: InputDecoration(
              hintText: 'Search attractions, restaurants...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemBuilder: (context, index) {
              final place = _searchResults[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TripiCard(
                  onTap: () => _addFromSearch(place),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.place, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              place['address'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_circle_outline, color: TripiColors.primary),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Activity Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'e.g. Dinner with view',
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Start Time (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (time != null) setState(() => _selectedTime = time);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF64748B)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime != null 
                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                        : 'Select time',
                    style: TextStyle(color: _selectedTime != null ? Colors.black : const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any special notes...',
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _submitManual,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: TripiColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Add to Itinerary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
