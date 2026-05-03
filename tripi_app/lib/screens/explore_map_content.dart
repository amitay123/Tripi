import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../theme/tripi_colors.dart';
import '../services/places_service.dart';
import '../services/hotel_service.dart';
import '../providers/trip_provider.dart';
import '../models/models.dart';

class ExploreContent extends StatefulWidget {
  const ExploreContent({super.key});

  @override
  State<ExploreContent> createState() => _ExploreContentState();
}

class _ExploreContentState extends State<ExploreContent> {
  GoogleMapController? _mapController;
  final PlacesService _placesService = PlacesService();
  final HotelService _hotelService = HotelService();
  
  List<Map<String, dynamic>> _places = [];
  Map<String, dynamic>? _selectedPlace;
  bool _isLoading = false;
  
  LatLng _currentCenter = const LatLng(48.8566, 2.3522); // Default Paris
  
  String _selectedCategory = '';
  Trip? _selectedTripFilter;
  double _filterDistance = 5000;
  bool _isSearching = false;
  bool _isDetailsSheetOpen = false;
  bool _isUpdatingMarkers = false; // Add lock for marker updates
  
  final Map<String, BitmapDescriptor> _customMarkerCache = {};
  Set<Marker> _tripMarkers = {};
  List<Trip>? _lastTrips;
  Trip? _lastFilter;
  
  static const List<Color> _routeColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFFEF4444), // Red
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Orange
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Deep Orange
    Color(0xFF84CC16), // Lime
    Color(0xFF6366F1), // Indigo
  ];
  
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  
  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().fetchTrips();
    });
    // All filters off by default on startup
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        setState(() => _searchResults = []);
        return;
      }
      final results = await _placesService.autocompletePlaces(
        query, 
        lat: _currentCenter.latitude, 
        lng: _currentCenter.longitude
      );
      setState(() => _searchResults = results);
    });
  }

  void _onSearchItemSelected(Map<String, dynamic> place) async {
    setState(() => _searchResults = []);
    _searchController.clear();
    FocusScope.of(context).unfocus();
    final details = await _placesService.getPlaceDetails(place['place_id']);
    if (details != null && details['lat'] != null) {
      final latlng = LatLng(details['lat'], details['lng']);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latlng, 14));
      setState(() {
        _currentCenter = latlng;
        // Optionally add the searched place to the map as selected
        _selectedPlace = details;
      });
      _showPlaceDetailsSheet(details);
      _searchNearbyPlaces();
    }
  }

  Future<void> _searchNearbyPlaces() async {
    if (_isSearching) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    _isSearching = true;
    
    // Determine search center
    LatLng searchCenter = _currentCenter;
    if (_selectedTripFilter != null) {
      bool foundActivity = false;
      if (_selectedTripFilter!.days.isNotEmpty) {
        // Find nearest activity in the selected trip to the current map center
        Activity? nearestActivity;
        double minDistance = double.infinity;
        for (var day in _selectedTripFilter!.days) {
          for (var activity in day.activities) {
            if (activity.lat != null && activity.lng != null) {
              double dist = _calculateDistance(
                _currentCenter.latitude, _currentCenter.longitude,
                activity.lat!, activity.lng!
              );
              if (dist < minDistance) {
                minDistance = dist;
                nearestActivity = activity;
              }
            }
          }
        }
        if (nearestActivity != null) {
          searchCenter = LatLng(nearestActivity.lat!, nearestActivity.lng!);
          foundActivity = true;
        }
      }

      // If no activities, try to center on the trip destination name
      if (!foundActivity && (_selectedTripFilter!.city?.isNotEmpty == true || _selectedTripFilter!.country.isNotEmpty)) {
        final destName = _selectedTripFilter!.city?.isNotEmpty == true 
          ? '${_selectedTripFilter!.city}, ${_selectedTripFilter!.country}' 
          : _selectedTripFilter!.country;
        
        try {
          final results = await _placesService.searchPlaces(
            lat: _currentCenter.latitude,
            lng: _currentCenter.longitude,
            type: '',
            radius: 50000,
            keyword: destName,
          );
          
          if (results.isNotEmpty) {
            final first = results.first;
            searchCenter = LatLng(
              first['geometry']['location']['lat'],
              first['geometry']['location']['lng']
            );
            // Animate to this center once
            _mapController?.animateCamera(CameraUpdate.newLatLngZoom(searchCenter, 12));
          }
        } catch (e) {
          debugPrint('Error searching for trip destination: $e');
        }
      }
    }

    try {
      if (_selectedCategory.isEmpty) {
        if (mounted) {
          setState(() {
            _places = _selectedPlace != null ? [_selectedPlace!] : [];
            _isLoading = false;
            _isSearching = false;
          });
        }
        return;
      }

      final places = await _placesService.searchPlaces(
        lat: searchCenter.latitude,
        lng: searchCenter.longitude,
        type: _getCategoryType(_selectedCategory),
        radius: _filterDistance.toInt(),
      );
      
      // Sort by rating and reviews for popularity
      places.sort((a, b) {
        double ratingA = (a['rating'] ?? 0).toDouble();
        double ratingB = (b['rating'] ?? 0).toDouble();
        int reviewsA = a['user_ratings_total'] ?? 0;
        int reviewsB = b['user_ratings_total'] ?? 0;
        
        // Simple popularity score
        double scoreA = ratingA * math.log(reviewsA + 1);
        double scoreB = ratingB * math.log(reviewsB + 1);
        return scoreB.compareTo(scoreA);
      });

      if (!mounted) return;

      setState(() {
        _places = places;
        if (_selectedPlace != null && !_places.any((p) => p['place_id'] == _selectedPlace!['place_id'])) {
          _places.add(_selectedPlace!);
        }
        _isLoading = false;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error in _searchNearbyPlaces: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSearching = false;
        });
      }
    }
  }

  String _getCategoryType(String category) {
    switch (category) {
      case 'hotel': return 'lodging';
      case 'restaurant': return 'restaurant';
      case 'museum': return 'museum';
      case 'park': return 'park';
      case 'cafe': return 'cafe';
      case 'bar': return 'bar';
      case 'shopping': return 'shopping_mall';
      default: return 'point_of_interest';
    }
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
          math.cos(lat1 * p) * math.cos(lat2 * p) * 
          (1 - math.cos((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  void _showPlaceDetailsSheet(Map<String, dynamic> place) {
    setState(() => _isDetailsSheetOpen = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPlaceDetailsSheet(place),
    ).then((_) {
      if (mounted) {
        setState(() => _isDetailsSheetOpen = false);
      }
    });
  }

  Widget _buildPlaceDetailsSheet(Map<String, dynamic> place) {
    final photoRef = (place['photos'] != null && (place['photos'] as List).isNotEmpty) 
        ? place['photos'][0]['photo_reference'] 
        : null;
    final photoUrl = _placesService.getPhotoUrl(photoRef);
    
    return Container(
      width: double.infinity,
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minHeight: MediaQuery.of(context).size.height * 0.5,
          maxWidth: 600, // Keep it proportional on larger screens
        ),
        decoration: const BoxDecoration(
          color: TripiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (photoUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: TripiColors.surfaceContainerLow,
                          child: const Icon(Icons.image, size: 48, color: TripiColors.outlineVariant),
                        ),
                      ),
                    ),
                  )
                else
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: TripiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: const Icon(Icons.image, size: 48, color: TripiColors.outlineVariant),
                    ),
                  ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['name'] ?? 'Unknown Place',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: TripiColors.primary, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${place['rating'] ?? 'N/A'} (${place['user_ratings_total'] ?? 0} reviews)',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              (place['types'] as List?)?.first?.toString().replaceAll('_', ' ').toUpperCase() ?? 'PLACE',
                              style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_selectedCategory == 'hotel' || (place['types'] as List?)?.contains('lodging') == true) ...[
                          _buildHotelComparison(place),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: TripiColors.onSurfaceVariant, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                place['vicinity'] ?? 'No address available',
                                style: const TextStyle(color: TripiColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: TripiColors.outlineVariant),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: const Text('Cancel', style: TextStyle(color: TripiColors.primary)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showAddToTripSheet(place);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TripiColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  elevation: 0,
                                ),
                                child: const Text('Add to Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Close button (X) in a circle
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToTripSheet(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TripiColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final trips = context.read<TripProvider>().trips;
        if (trips.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No Trips Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Create a trip first to add places to it.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                )
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          itemCount: trips.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text('Select Trip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              );
            }
            final trip = trips[index - 1];
            return ListTile(
              title: Text(trip.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${trip.startDate.toString().split(' ')[0]} - ${trip.endDate.toString().split(' ')[0]}'),
              onTap: () {
                Navigator.pop(context);
                _showSelectDaySheet(trip, place);
              },
            );
          },
        );
      },
    );
  }

  void _showSelectDaySheet(Trip trip, Map<String, dynamic> place) {
    final photoRef = (place['photos'] != null && (place['photos'] as List).isNotEmpty) 
        ? place['photos'][0]['photo_reference'] 
        : null;
    final photoUrl = _placesService.getPhotoUrl(photoRef);

    showModalBottomSheet(
      context: context,
      backgroundColor: TripiColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        int durationDays = trip.durationDays;
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          itemCount: durationDays + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text('Select Day in ${trip.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              );
            }
            final dayIndex = index;
            final date = trip.startDate.add(Duration(days: dayIndex - 1));
            return ListTile(
              title: Text('Day $dayIndex', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(date.toString().split(' ')[0]),
              onTap: () {
                Navigator.pop(context);
                // Add activity to provider
                final activity = Activity(
                  id: 'a_${DateTime.now().millisecondsSinceEpoch}',
                  title: place['name'],
                  lat: place['geometry']['location']['lat'],
                  lng: place['geometry']['location']['lng'],
                  address: place['vicinity'],
                  placeId: place['place_id'],
                  source: 'api',
                  imageUrl: photoUrl,
                );
                  context.read<TripProvider>().addActivity(trip.id, dayIndex, activity);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${place['name']} added to ${trip.name} Day $dayIndex'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: TripiColors.primary,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _onCategoryTapped(String categoryValue, bool isSelected) {
    if (_isSearching) return;
    setState(() {
      if (isSelected) {
        _selectedCategory = ''; // Unselect
      } else {
        _selectedCategory = categoryValue;
      }
    });
    _searchNearbyPlaces();
  }

  Widget _buildChip(String label, IconData icon, String categoryValue) {
    final isSelected = _selectedCategory == categoryValue;
    return GestureDetector(
      onTap: () => _onCategoryTapped(categoryValue, isSelected),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? TripiColors.primary : TripiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? TripiColors.primary : TripiColors.outlineVariant.withOpacity(0.15), 
            width: 1
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : TripiColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.white : TripiColors.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            )),
          ],
        ),
      ),
    );
  }

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(48.8566, 2.3522),
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<TripProvider>().trips;
    
    // Ensure the selected trip filter is always the latest version from the provider
    Trip? currentTripFilter;
    if (_selectedTripFilter != null) {
      try {
        currentTripFilter = trips.firstWhere((t) => t.id == _selectedTripFilter!.id);
      } catch (_) {
        // Trip might have been deleted
        currentTripFilter = null;
      }
    }

    // Trigger marker update if trips or filter changed
    if (_lastTrips != trips || _lastFilter != currentTripFilter) {
      _lastTrips = trips;
      _lastFilter = currentTripFilter;
      Future.microtask(() => _updateTripMarkers(trips, currentTripFilter));
    }
    
    // Create markers from places
    Set<Marker> markers = _places.map((place) {
      final lat = place['geometry']['location']['lat'];
      final lng = place['geometry']['location']['lng'];
      final isSelected = _selectedPlace != null && _selectedPlace!['place_id'] == place['place_id'];
      
      // Check if added to any trip
      bool addedToTrip = false;
      for (var trip in trips) {
        for (var day in trip.days) {
          if (day.activities.any((a) => a.placeId == place['place_id'])) {
            addedToTrip = true;
            break;
          }
        }
      }

      // Check if popular (top 5 by our score)
      bool isPopular = false;
      for (int i = 0; i < math.min(5, _places.length); i++) {
        if (_places[i]['place_id'] == place['place_id']) {
          isPopular = true;
          break;
        }
      }

      return Marker(
        markerId: MarkerId(place['place_id']),
        position: LatLng(lat, lng),
        // Disabling default InfoWindow to prevent 'bulm' (bubble) on top
        // and allow the bottom sheet to be the primary interaction.
        infoWindow: InfoWindow.noText,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          addedToTrip ? BitmapDescriptor.hueGreen : 
          (isSelected ? BitmapDescriptor.hueBlue : 
           (isPopular ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed))
        ),
        onTap: () {
          setState(() => _selectedPlace = place);
          _showPlaceDetailsSheet(place);
        },
      );
    }).toSet();

    // Add cached trip markers
    markers.addAll(_tripMarkers);

    Set<Polyline> polylines = {};
    
    if (currentTripFilter != null) {
      // Logic for single trip: color per day
      for (int i = 0; i < currentTripFilter.days.length; i++) {
        final day = currentTripFilter.days[i];
        final points = day.activities
            .where((a) => a.lat != null && a.lng != null)
            .map((a) => LatLng(a.lat!, a.lng!))
            .toList();
        
        final dayColor = _routeColors[i % _routeColors.length];
        
        if (points.length >= 2) {
          polylines.add(
            Polyline(
              polylineId: PolylineId('route_${currentTripFilter.id}_day_${day.dayIndex}'),
              points: points,
              color: dayColor,
              width: 5,
              geodesic: true,
            ),
          );
        }
      }
    } else {
      // Logic for all trips: color per trip
      for (int i = 0; i < trips.length; i++) {
        final trip = trips[i];
        final tripColor = _routeColors[i % _routeColors.length];
        
        for (var day in trip.days) {
          final dayPoints = day.activities
              .where((a) => a.lat != null && a.lng != null)
              .map((a) => LatLng(a.lat!, a.lng!))
              .toList();
          
          if (dayPoints.length >= 2) {
            polylines.add(
              Polyline(
                polylineId: PolylineId('route_all_trip_${trip.id}_day_${day.dayIndex}'),
                points: dayPoints,
                color: tripColor,
                width: 4,
                geodesic: true,
              ),
            );
          }
        }
      }
    }

    return Stack(
      children: [
        // Map
        GoogleMap(
          initialCameraPosition: _initialPosition,
          markers: markers,
          polylines: polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          scrollGesturesEnabled: !_isDetailsSheetOpen,
          zoomGesturesEnabled: !_isDetailsSheetOpen,
          rotateGesturesEnabled: !_isDetailsSheetOpen,
          tiltGesturesEnabled: !_isDetailsSheetOpen,
          onMapCreated: (controller) => _mapController = controller,
        ),
        
        // Blocking Dimmer Overlay
        if (_isSearchFocused || _searchResults.isNotEmpty)
          Positioned.fill(
            child: PointerInterceptor(
              child: GestureDetector(
                onTap: () {
                  _searchFocusNode.unfocus();
                  setState(() {
                    _searchResults = [];
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ),
        // Top overlay: Search bar and Filters
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                // Search Area without floating dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: PointerInterceptor(
                    child: Container(
                      decoration: BoxDecoration(
                        color: TripiColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: TripiColors.outlineVariant.withOpacity(0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D3335).withOpacity(0.06),
                            blurRadius: 32,
                            offset: const Offset(0, -12),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search destinations, hotels...',
                          hintStyle: const TextStyle(color: TripiColors.onSurfaceVariant),
                          prefixIcon: const Icon(Icons.search, color: TripiColors.onSurfaceVariant),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.tune, color: TripiColors.primary),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: TripiColors.surfaceContainerLowest,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setModalState) {
                                      return Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Advanced Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 24),
                                            Text('Distance Radius: ${(_filterDistance / 1000).toStringAsFixed(1)} km', 
                                              style: const TextStyle(fontWeight: FontWeight.w600)
                                            ),
                                            Slider(
                                              value: _filterDistance,
                                              min: 1000,
                                              max: 50000,
                                              divisions: 49,
                                              activeColor: TripiColors.primary,
                                              label: '${(_filterDistance / 1000).toStringAsFixed(1)} km',
                                              onChanged: (value) {
                                                setModalState(() => _filterDistance = value);
                                                setState(() => _filterDistance = value);
                                              },
                                            ),
                                            const SizedBox(height: 24),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _searchNearbyPlaces();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: TripiColors.primary,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                                ),
                                                child: const Text('Apply'),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                  
                // Gap between search area and filters
                const SizedBox(height: 24),
                  
                  // Filter Row: Trip Filter followed by Category Chips
                  IgnorePointer(
                    ignoring: _isSearchFocused || _searchResults.isNotEmpty,
                    child: Opacity(
                      opacity: (_isSearchFocused || _searchResults.isNotEmpty) ? 0.5 : 1.0,
                      child: PointerInterceptor(
                        child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Trip Filter Dropdown
                          if (trips.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: TripiColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: TripiColors.outlineVariant.withOpacity(0.15)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Trip?>(
                                  value: currentTripFilter,
                                  hint: const Text('All Trips', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  isDense: true,
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('All Trips')),
                                    ...trips.map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                                  ],
                                  onChanged: (trip) {
                                    setState(() => _selectedTripFilter = trip);
                                    if (trip != null) {
                                      if (trip.days.isNotEmpty && trip.days.first.activities.isNotEmpty) {
                                        final act = trip.days.first.activities.first;
                                        if (act.lat != null && act.lng != null) {
                                          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(act.lat!, act.lng!), 12));
                                        }
                                      }
                                    }
                                    _searchNearbyPlaces();
                                  },
                                ),
                              ),
                            ),
                          
                          // Category Chips
                          _buildChip('Hotels', Icons.hotel, 'hotel'),
                          _buildChip('Dining', Icons.restaurant, 'restaurant'),
                          _buildChip('Museums', Icons.museum, 'museum'),
                          _buildChip('Parks', Icons.park, 'park'),
                          _buildChip('Cafes', Icons.local_cafe, 'cafe'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        
        // Loading Indicator
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
          
        // Autocomplete Dropdown (Floating in the outermost Stack)
        if (_searchResults.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 80, left: 16, right: 16), // Below search bar
                child: PointerInterceptor(
                  child: Container(
                    decoration: BoxDecoration(
                      color: TripiColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: TripiColors.onSurfaceVariant),
                          title: Text(result['structured_formatting']?['main_text'] ?? result['description']),
                          subtitle: Text(result['structured_formatting']?['secondary_text'] ?? ''),
                          onTap: () => _onSearchItemSelected(result),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          
        // Floating Info Card is now handled by Bottom Sheet on tap, but we can also show a small persistent card.
        // As per the HTML, the card floats above the nav bar. We used a bottom sheet instead for better interaction,
        // but if desired we could place a card here.
      ],
    );
  }

  Widget _buildHotelComparison(Map<String, dynamic> place) {
    final pricing = _hotelService.getSimulatedPricing(place['name']);
    final city = place['vicinity']?.split(',').last.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TripiColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TripiColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Comparison',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: TripiColors.primary),
          ),
          const SizedBox(height: 12),
          _buildProviderRow(
            'Booking.com',
            'Booking',
            pricing['booking']['price'],
            () => _hotelService.launchBooking(place['name'], city),
          ),
          const Divider(height: 24, color: TripiColors.outlineVariant),
          _buildProviderRow(
            'Agoda',
            'Agoda',
            pricing['agoda']['price'],
            () => _hotelService.launchAgoda(place['name'], city),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderRow(String name, String label, double price, VoidCallback onTap) {
    final bool isBooking = name.contains('Booking');
    final Color brandColor = isBooking ? const Color(0xFF003580) : const Color(0xFFEE2A24);
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: brandColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isBooking ? Icons.hotel_rounded : Icons.apartment_rounded,
                color: brandColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    isBooking ? 'Free cancellation' : 'Best price guarantee',
                    style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'USD ${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: brandColor,
                  ),
                ),
                const Text(
                  'per night',
                  style: TextStyle(fontSize: 10, color: TripiColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: TripiColors.outlineVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTripMarkers(List<Trip> trips, Trip? filter) async {
    if (!mounted) return;
    if (_isUpdatingMarkers) return;
    _isUpdatingMarkers = true;

    try {
      final List<Marker> newMarkers = [];
      final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
      
      if (filter != null) {
        // Single trip scope: number per day
        for (int i = 0; i < filter.days.length; i++) {
          final day = filter.days[i];
          final dayColor = _routeColors[i % _routeColors.length];
          
          for (int j = 0; j < day.activities.length; j++) {
            final activity = day.activities[j];
            if (activity.lat != null && activity.lng != null) {
              ui.Image? placeImage;
              if (activity.imageUrl != null) {
                placeImage = await _loadImage(activity.imageUrl!);
              }
              final icon = await _createNumberedMarkerIcon(j + 1, dayColor, pixelRatio, placeImage, activity.imageUrl);
              newMarkers.add(
                Marker(
                  markerId: MarkerId('trip_activity_${activity.id}'),
                  position: LatLng(activity.lat!, activity.lng!),
                  icon: icon,
                  infoWindow: InfoWindow(
                    title: activity.title, // Restore "bulb" (bubble) with activity title
                  ),
                  zIndex: 20,
                  onTap: () {
                    // Activity details are now in the bulb
                  },
                ),
              );
            }
          }
        }
      } else {
        // All trips scope: show all markers with color per trip
        for (int i = 0; i < trips.length; i++) {
          final trip = trips[i];
          final tripColor = _routeColors[i % _routeColors.length];
          
          int activityCounter = 1;
          for (var day in trip.days) {
            for (var activity in day.activities) {
              if (activity.lat != null && activity.lng != null) {
                ui.Image? placeImage;
                if (activity.imageUrl != null) {
                  placeImage = await _loadImage(activity.imageUrl!);
                }
                final icon = await _createNumberedMarkerIcon(activityCounter++, tripColor, pixelRatio, placeImage, activity.imageUrl);
                newMarkers.add(
                  Marker(
                    markerId: MarkerId('trip_activity_${activity.id}'),
                    position: LatLng(activity.lat!, activity.lng!),
                    icon: icon,
                    infoWindow: InfoWindow(
                      title: '${trip.name}: ${activity.title}', // Detailed bulb title
                    ),
                    zIndex: 20,
                  ),
                );
              }
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _tripMarkers = newMarkers.toSet();
        _isUpdatingMarkers = false;
      });
    } catch (e) {
      debugPrint('Error updating trip markers: $e');
      if (mounted) {
        setState(() => _isUpdatingMarkers = false);
      }
    }
  }

  Future<ui.Image?> _loadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final codec = await ui.instantiateImageCodec(response.bodyBytes, targetWidth: 60, targetHeight: 60);
        final frame = await codec.getNextFrame();
        return frame.image;
      }
    } catch (e) {
      debugPrint('Error loading image for marker: $e');
    }
    return null;
  }

  Future<BitmapDescriptor> _createNumberedMarkerIcon(int number, Color color, double pixelRatio, [ui.Image? image, String? imageUrl]) async {
    final String cacheKey = '${number}_${color.toARGB32()}_${pixelRatio}_${imageUrl ?? ""}';
    if (_customMarkerCache.containsKey(cacheKey)) {
      return _customMarkerCache[cacheKey]!;
    }

    // Reduced Google Map Pin proportions to feel standard: 24x38 logical pixels
    const double width = 24.0;
    const double height = 38.0;
    const double radius = width / 2;
    
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Draw pin path with a precise teardrop shape matching Google standard
    Path path = Path();
    path.moveTo(radius, height); // Tip
    // Curve from tip to left side of the circle
    path.quadraticBezierTo(0, height * 0.6, 0, radius);
    // Top circle arc
    path.arcTo(Rect.fromLTWH(0, 0, width, width), math.pi, math.pi, false);
    // Curve back to tip
    path.quadraticBezierTo(width, height * 0.6, radius, height);
    path.close();
    
    // Draw main colored teardrop
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
 
    // Draw inner white circle for the number
    final Paint innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(radius, radius), (radius * 0.7), innerCirclePaint);
 
    if (image != null) {
      canvas.save();
      Path clipPath = Path()..addOval(Rect.fromCircle(center: Offset(radius, radius), radius: radius * 0.7));
      canvas.clipPath(clipPath);
      final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      
      double imgRatio = image.width / image.height;
      double targetSize = radius * 1.4;
      double dstW = targetSize;
      double dstH = targetSize;
      if (imgRatio > 1.0) {
        dstW = targetSize * imgRatio;
      } else {
        dstH = targetSize / imgRatio;
      }
      final dst = Rect.fromCenter(center: Offset(radius, radius), width: dstW, height: dstH);
      
      canvas.drawImageRect(image, src, dst, Paint()..isAntiAlias = true);
      canvas.restore();
    } else {
      // Draw text (number)
      final TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: number.toString(),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(radius - (painter.width / 2), radius - (painter.height / 2)),
      );
    }
 
    final img = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
    
    _customMarkerCache[cacheKey] = icon;
    return icon;
  }
}
