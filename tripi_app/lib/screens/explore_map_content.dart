import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
import '../models/place_result.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../widgets/place_details/add_to_itinerary_sheet.dart';

class ExploreContent extends StatefulWidget {
  const ExploreContent({super.key});

  @override
  State<ExploreContent> createState() => _ExploreContentState();
}

class _ExploreContentState extends State<ExploreContent> {
  GoogleMapController? _mapController;
  final PlacesService _placesService = PlacesService();
  final HotelService _hotelService = HotelService();
  
  List<PlaceResult> _places = [];
  PlaceResult? _selectedPlace;
  String? _searchResultPlaceId; // Track the place selected via search bar
  LatLng _currentCenter = const LatLng(48.8566, 2.3522); // Default Paris
  bool _isLoading = false;
  bool _isSearchFocused = false;
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  final List<String> _selectedCategories = [];
  Trip? _selectedTripFilter;
  double _filterDistance = 3.0; // Default to 3km
  bool _isSearching = false;
  bool _isDetailsSheetOpen = false;
  bool _isRadiusPopupOpen = false;
  bool _addSuccess = false;
  int _markerUpdateId = 0; // Track latest marker update request
  
  Activity? _selectedActivity;
  Trip? _selectedActivityTrip;
  int? _selectedActivityDay;
  Offset? _selectedActivityScreenPos;
  
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
  
  Timer? _debounce;
  
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
      // Start initial discovery if map is ready
      _searchNearbyPlaces();
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
    _searchFocusNode.unfocus();
    
    final result = await _placesService.getPlaceDetails(place['place_id']);
    if (result != null) {
      final latlng = LatLng(result.lat, result.lng);
      
      // Focus camera on selected place
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latlng, 16));
      
      setState(() {
        _currentCenter = latlng;
        _selectedPlace = result;
        _searchResultPlaceId = result.placeId; // Mark as the search result
      });
      
      // Trigger discovery around the selected place if categories are selected
      if (_selectedCategories.isNotEmpty) {
        // Set current center to the selected place so discovery happens around it
        setState(() {
          _currentCenter = latlng;
        });
        _searchNearbyPlaces();
      } else {
        // Just show the selected place marker
        setState(() {
          _places = [_selectedPlace!];
          _isLoading = false;
          _isSearching = false;
        });
      }
    }
  }

  bool _matchesAnyCategory(PlaceResult place, List<String> categories) {
    if (categories.isEmpty) return true;
    for (final cat in categories) {
      final categoryData = _getCategoryData(cat);
      final types = categoryData['types'] as List<String>;
      // Check if place has at least one of the category types
      if (place.types.any((t) => types.contains(t))) return true;
    }
    return false;
  }

  Future<void> _searchNearbyPlaces() async {
    if (_isSearching) return;
    if (_selectedCategories.isEmpty) {
      setState(() {
        _places = [];
        _isLoading = false;
        _isSearching = false;
      });
      return;
    }
    if (!mounted) return;

    if (_selectedCategories.isEmpty) {
      setState(() {
        _places = _selectedPlace != null ? [_selectedPlace!] : [];
        _isLoading = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _isSearching = true;
    
    try {
      final List<LatLng> anchorPoints = [];
      
      // 1. Determine Anchor Points
      if (_selectedTripFilter != null) {
        final List<LatLng> tripPath = [];
        for (var day in _selectedTripFilter!.days) {
          // Sort activities by positionIndex if available
          final activities = List<Activity>.from(day.activities)
            ..sort((a, b) => (a.positionIndex ?? 0).compareTo(b.positionIndex ?? 0));
            
          for (var activity in activities) {
            if (activity.lat != null && activity.lng != null) {
              tripPath.add(LatLng(activity.lat!, activity.lng!));
            }
          }
        }

        if (tripPath.isEmpty) {
          // Fallback Case: Trip exists but no activities, use map center
          anchorPoints.add(_currentCenter);
        } else if (tripPath.length == 1) {
          anchorPoints.add(tripPath.first);
        } else {
          // Optimized sampling: every 5km to reduce API load and improve performance
          anchorPoints.add(tripPath.first);
          double accumulatedDist = 0;
          for (int i = 0; i < tripPath.length - 1; i++) {
            final d = _calculateDistance(
              tripPath[i].latitude, tripPath[i].longitude,
              tripPath[i+1].latitude, tripPath[i+1].longitude
            );
            accumulatedDist += d;
            if (accumulatedDist >= 5.0) { 
              anchorPoints.add(tripPath[i+1]);
              accumulatedDist = 0;
            }
          }
          if (anchorPoints.last != tripPath.last) {
            anchorPoints.add(tripPath.last);
          }
          
          // Limit total anchor points to 10 for performance
          if (anchorPoints.length > 10) {
            final List<LatLng> limitedAnchors = [];
            final step = anchorPoints.length / 10;
            for (int i = 0; i < 10; i++) {
              limitedAnchors.add(anchorPoints[(i * step).toInt()]);
            }
            anchorPoints.clear();
            anchorPoints.addAll(limitedAnchors);
          }
        }
      } else {
        // Fallback: No trip selected, use map center
        anchorPoints.add(_currentCenter);
      }

      // 2. Build Batch Search Points
      final List<Map<String, dynamic>> searchQueries = [];
      for (final anchor in anchorPoints) {
        for (final cat in _selectedCategories) {
          final categoryData = _getCategoryData(cat);
          final types = categoryData['types'] as List<String>;
          final keyword = categoryData['keyword'] as String?;
          
          for (final type in types) {
            searchQueries.add({
              'lat': anchor.latitude,
              'lng': anchor.longitude,
              'type': type,
              'keyword': keyword,
              'radius': (_filterDistance * 1000).toInt(),
              'anchor': anchor, // Save anchor for scoring later
            });
          }
        }
      }

      // 3. Execute Batch Search (via PlacesService with rate limiting)
      final List<PlaceResult> discoveredPlaces = await _placesService.searchBatch(searchQueries);
      
      // 4. Rank and Filter Results
      final List<PlaceResult> scoredPlaces = discoveredPlaces.map((p) {
        // Find nearest anchor for this place to calculate proximity score
        LatLng nearestAnchor = anchorPoints.first;
        double minDist = double.infinity;
        for (final anchor in anchorPoints) {
          final d = _calculateDistance(p.lat, p.lng, anchor.latitude, anchor.longitude);
          if (d < minDist) {
            minDist = d;
            nearestAnchor = anchor;
          }
        }
        
        final score = _calculatePlaceScore(p, nearestAnchor);
        return p.copyWith(distance: minDist, score: score);
      }).toList();

      // Sort by score descending
      scoredPlaces.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

      // 5. Strict Category Filter & Global Slicing
      final filteredResults = scoredPlaces.where((p) => _matchesAnyCategory(p, _selectedCategories)).toList();
      final finalResults = filteredResults.take(50).toList();

      if (mounted) {
        setState(() {
          _places = finalResults;
          // If we had a search result, keep it visible
          if (_selectedPlace != null && !finalResults.any((p) => p.placeId == _selectedPlace!.placeId)) {
            _places.insert(0, _selectedPlace!);
          }
          _isLoading = false;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Discovery Engine Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSearching = false;
        });
      }
    }
  }


  Map<String, dynamic> _getCategoryData(String category) {
    switch (category) {
      case 'hotel': 
        return {'types': ['lodging'], 'keyword': 'hotel'};
      case 'restaurant': 
        return {'types': ['restaurant'], 'keyword': 'restaurant'};
      case 'museum': 
        return {'types': ['museum'], 'keyword': 'museum'};
      case 'park': 
        return {'types': ['park', 'tourist_attraction'], 'keyword': 'park'};
      case 'cafe': 
        return {'types': ['cafe'], 'keyword': 'coffee'};
      case 'bar': 
        return {'types': ['bar'], 'keyword': 'bar'};
      case 'shopping': 
        return {'types': ['shopping_mall'], 'keyword': 'shopping'};
      default: 
        return {'types': ['point_of_interest', 'tourist_attraction'], 'keyword': null};
    }
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
          math.cos(lat1 * p) * math.cos(lat2 * p) * 
          (1 - math.cos((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  Future<void> _showPlaceDetailsSheet(PlaceResult place) async {
    setState(() => _isDetailsSheetOpen = true);
    
    // Fetch full details if missing (opening hours, website, description)
    if (place.website == null || place.openingHours == null || place.description == null) {
      try {
        final details = await _placesService.getPlaceDetails(place.placeId);
        if (details != null && mounted) {
          setState(() {
            // Update the place in our list and selected place
            final index = _places.indexWhere((p) => p.placeId == place.placeId);
            final updatedPlace = place.copyWith(
              website: details.website,
              openingHours: details.openingHours,
              description: details.description,
              photoReferences: details.photoReferences,
              // Keep original image URL if we already had one, or use new one
              imageUrl: place.imageUrl ?? (details.photoReferences.isNotEmpty ? _placesService.getPhotoUrl(details.photoReferences[0]) : null),
            );
            
            if (index != -1) {
              _places[index] = updatedPlace;
            }
            if (_selectedPlace?.placeId == place.placeId) {
              _selectedPlace = updatedPlace;
            }
          });
          place = _selectedPlace!; // Use updated place for the sheet
        }
      } catch (e) {
        debugPrint('Error fetching lazy details: $e');
      }
    }

    if (!mounted) return;

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

  Widget _buildPlaceDetailsSheet(PlaceResult place) {
    final photoUrl = place.imageUrl;
    
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
                          place.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: TripiColors.onSurfaceVariant, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address ?? 'No address available',
                                style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star, color: TripiColors.primary, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${place.rating ?? 'N/A'} (${place.userRatingsTotal ?? 0} reviews)',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 16),
                            if (place.priceLevel != null) ...[
                              Text(
                                place.priceLevelString,
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: Text(
                                place.types.firstOrNull?.toString().replaceAll('_', ' ').toUpperCase() ?? 'PLACE',
                                style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (place.todayHours != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: TripiColors.onSurfaceVariant, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Today: ${place.todayHours}',
                                style: const TextStyle(color: TripiColors.onSurfaceVariant, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (place.website != null && place.website!.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse(place.website!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.language, color: TripiColors.primary, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Visit Website',
                                  style: TextStyle(color: TripiColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (place.description != null && place.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            place.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: TripiColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 16),
                        if (_selectedCategories.contains('hotel') || place.types.contains('lodging')) ...[
                          _buildHotelComparison(place),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 24),
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
                                onPressed: _addSuccess ? null : () {
                                  Navigator.pop(context);
                                  _showAddToItinerary(place);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _addSuccess ? Colors.green : TripiColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _addSuccess ? '✓ Added' : 'Add to Trip', 
                                  style: const TextStyle(fontWeight: FontWeight.bold)
                                ),
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
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToItinerary(PlaceResult place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToItinerarySheet(
        place: place,
        tripProvider: context.read<TripProvider>(),
        onAdded: (tripName, dayIndex) {
          if (mounted) setState(() => _addSuccess = true);
          HapticFeedback.lightImpact();
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) setState(() => _addSuccess = false);
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Added to $tripName — Day $dayIndex'),
            backgroundColor: TripiColors.primary,
            behavior: SnackBarBehavior.floating,
          ));
        },
      ),
    );
  }

  void _onCategoryTapped(String categoryValue, bool isSelected) {
    if (_isSearching) return;
    setState(() {
      if (isSelected) {
        _selectedCategories.remove(categoryValue);
      } else {
        _selectedCategories.add(categoryValue);
      }
    });
    _searchNearbyPlaces();
  }

  Widget _buildChip(String label, IconData icon, String categoryValue) {
    final isSelected = _selectedCategories.contains(categoryValue);
    return GestureDetector(
      onTap: () => _onCategoryTapped(categoryValue, isSelected),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? TripiColors.primary : TripiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? TripiColors.primary : TripiColors.outlineVariant.withValues(alpha: 0.15), 
            width: 1
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : TripiColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.white : TripiColors.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            )),
          ],
        ),
      ),
    );
  }

  void _showRadiusSliderPopup() async {
    setState(() => _isRadiusPopupOpen = true);
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Search Radius', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_filterDistance.toInt()} km', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TripiColors.primary)),
              const SizedBox(height: 16),
              Slider(
                value: _filterDistance,
                min: 1,
                max: 20,
                divisions: 19,
                activeColor: TripiColors.primary,
                onChanged: (value) {
                  setDialogState(() {
                    _filterDistance = value;
                  });
                  setState(() {
                    _filterDistance = value;
                  });
                },
              ),
              const Text('Adjust distance for discovery', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _searchNearbyPlaces();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (mounted) {
      setState(() => _isRadiusPopupOpen = false);
    }
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
      // Find the latest version of the selected trip by ID
      final matchingTrips = trips.where((t) => t.id == _selectedTripFilter!.id).toList();
      if (matchingTrips.isNotEmpty) {
        currentTripFilter = matchingTrips.first;
      } else {
        // Fallback: If trip not found in list (e.g. just updated), keep the one we have
        // unless it's clearly gone.
        currentTripFilter = _selectedTripFilter;
      }
    }

    // Trigger marker update if trips or filter changed
    final bool tripsChanged = !listEquals(_lastTrips, trips);
    final bool filterChanged = _lastFilter?.id != currentTripFilter?.id;
    
    if (tripsChanged || filterChanged) {
      _lastTrips = trips;
      _lastFilter = currentTripFilter;
      // Use microtask to avoid calling setState during build if _updateTripMarkers completes synchronously
      Future.microtask(() => _updateTripMarkers(trips, currentTripFilter));
    }
    
    // Create markers from places
    final List<PlaceResult> allMapPlaces = List<PlaceResult>.from(_places);
    if (_selectedPlace != null && !allMapPlaces.any((p) => p.placeId == _selectedPlace!.placeId)) {
      allMapPlaces.add(_selectedPlace!);
    }

    Set<Marker> markers = allMapPlaces.map((place) {
      final lat = place.lat;
      final lng = place.lng;
      final isSelected = _selectedPlace != null && _selectedPlace!.placeId == place.placeId;
      
      // Check if added to any trip
      bool addedToTrip = false;
      for (var trip in trips) {
        for (var day in trip.days) {
          if (day.activities.any((a) => a.placeId == place.placeId)) {
            addedToTrip = true;
            break;
          }
        }
      }

      // Check if popular (top 5 by our score)
      bool isPopular = false;
      for (int i = 0; i < math.min(5, _places.length); i++) {
        if (_places[i].placeId == place.placeId) {
          isPopular = true;
          break;
        }
      }

      final isSearchResult = _searchResultPlaceId != null && _searchResultPlaceId == place.placeId;
      
      return Marker(
        markerId: MarkerId(place.placeId),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow.noText,
        zIndexInt: isSearchResult ? 300 : (isSelected ? 200 : 100),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSearchResult ? 300.0 : ( // hueMagenta
            addedToTrip ? BitmapDescriptor.hueGreen : 
            (isSelected ? BitmapDescriptor.hueAzure : 
            (isPopular ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed))
          )
        ),
        onTap: () {
          if (_isDetailsSheetOpen || _isRadiusPopupOpen) return;
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
        // 1. Map
        GoogleMap(
          initialCameraPosition: _initialPosition,
          markers: markers,
          polylines: polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          scrollGesturesEnabled: !_isDetailsSheetOpen && !_isRadiusPopupOpen,
          zoomGesturesEnabled: !_isDetailsSheetOpen && !_isRadiusPopupOpen,
          rotateGesturesEnabled: !_isDetailsSheetOpen && !_isRadiusPopupOpen,
          tiltGesturesEnabled: !_isDetailsSheetOpen && !_isRadiusPopupOpen,
          onMapCreated: (controller) => _mapController = controller,
          onTap: (_) {
            setState(() {
              _selectedActivity = null;
              _selectedActivityTrip = null;
              _selectedActivityDay = null;
              _selectedActivityScreenPos = null;
            });
          },
          onCameraMove: (position) {
            _updateBubblePosition();
          },
        ),

        // 2. Floating Info Card for selected numbered pins
        // Placed before filters in stack so filters stay on top
        if (_selectedActivity != null && _selectedActivityTrip != null && _selectedActivityScreenPos != null)
          Positioned(
            // Positioned relative to the pin's screen coordinates.
            // Horizontal clamping is removed to keep the bubble perfectly anchored during panning.
            left: _selectedActivityScreenPos!.dx - 140,
            // Vertical clamping is also removed as the Stack order handles filter overlap.
            top: _selectedActivityScreenPos!.dy - 110,
            child: PointerInterceptor(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TripiColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: TripiColors.surfaceContainerHigh,
                                  gradient: LinearGradient(
                                    colors: [
                                      TripiColors.surfaceContainerHigh,
                                      TripiColors.surfaceContainerLow,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: (_selectedActivity!.imageUrl != null && _selectedActivity!.imageUrl!.isNotEmpty)
                                  ? Image.network(
                                      _selectedActivity!.imageUrl!.startsWith('http') 
                                          ? _selectedActivity!.imageUrl! 
                                          : (_placesService.getPhotoUrl(_selectedActivity!.imageUrl!) ?? _selectedActivity!.imageUrl!), 
                                      width: 60, 
                                      height: 60, 
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, color: TripiColors.onSurfaceVariant, size: 24),
                                    )
                                  : const Icon(Icons.place_outlined, color: TripiColors.onSurfaceVariant, size: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedActivityTrip!.name,
                                          style: const TextStyle(
                                            color: TripiColors.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_selectedActivityDay != null)
                                        Container(
                                          margin: const EdgeInsets.only(left: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: TripiColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Day $_selectedActivityDay',
                                            style: const TextStyle(
                                              color: TripiColors.primary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedActivity!.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_selectedActivity!.address != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedActivity!.address!,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (_selectedActivity!.rating != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_selectedActivity!.rating}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        if (_selectedActivity!.userRatingsTotal != null)
                                          Text(
                                            ' (${_selectedActivity!.userRatingsTotal})',
                                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedActivity = null;
                              _selectedActivityTrip = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close, size: 18, color: TripiColors.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pointer/Tail
                  CustomPaint(
                    size: const Size(20, 10),
                    painter: BubblePointerPainter(),
                  ),
                ],
              ),
            ),
          ),
        
        // 3. Blocking Dimmer Overlay
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
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),

        // 4. Search Bar and Filters
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: PointerInterceptor(
            child: SafeArea(
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: TripiColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _onSearchChanged,
                              style: const TextStyle(color: TripiColors.onSurface),
                              decoration: InputDecoration(
                                hintText: 'Search for places...',
                                hintStyle: const TextStyle(color: TripiColors.onSurfaceVariant),
                                prefixIcon: const Icon(Icons.search, color: TripiColors.primary),
                                suffixIcon: _searchController.text.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20, color: TripiColors.onSurfaceVariant),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.tune, color: TripiColors.primary),
                            onPressed: _showRadiusSliderPopup,
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                  
                  // Filter Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Trip Filter Dropdown
                            if (trips.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: TripiColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: TripiColors.outlineVariant.withValues(alpha: 0.15)),
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    hoverColor: Colors.transparent,
                                  ),
                                  child: PopupMenuButton<String>(
                                    initialValue: currentTripFilter?.id ?? 'all',
                                    tooltip: 'Filter by Trip',
                                    offset: const Offset(0, 45),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    color: TripiColors.surfaceContainerLowest,
                                    elevation: 8,
                                    onSelected: (tripId) {
                                      setState(() {
                                        if (tripId == 'all') {
                                          _selectedTripFilter = null;
                                        } else {
                                          _selectedTripFilter = trips.firstWhere((t) => t.id == tripId);
                                        }
                                        
                                        _searchResultPlaceId = null; // Clear search highlight
                                        _selectedActivity = null; // Clear activity bubble
                                        _selectedActivityTrip = null;
                                        _isDetailsSheetOpen = false;
                                        _selectedPlace = null; // Clear selected place
                                        _searchResults = [];
                                        _searchController.clear();
                                      });
                                      _searchFocusNode.unfocus();
                                      
                                      if (_selectedTripFilter != null) {
                                        _fitTripBounds(_selectedTripFilter!);
                                      } else if (trips.isNotEmpty) {
                                        _fitAllTripsBounds(trips);
                                      }
                                      
                                      // Trigger discovery refresh when trip filter changes if categories are active
                                      if (_selectedCategories.isNotEmpty) {
                                        _searchNearbyPlaces();
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem<String>(
                                        value: 'all', 
                                        child: Text('All Trips', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TripiColors.onSurface)),
                                      ),
                                      ...trips.map((t) => PopupMenuItem<String>(
                                        value: t.id, 
                                        child: Text(t.name, style: const TextStyle(fontSize: 14, color: TripiColors.onSurface)),
                                      ))
                                    ],
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            currentTripFilter?.name ?? 'All Trips',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: TripiColors.onSurface),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: TripiColors.primary),
                                        ],
                                      ),
                                    ),
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
                    ],
                  ),
            ),
          ),
        ),

        // 5. Loading Indicator
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
          
        // 6. Autocomplete Results
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
                          color: Colors.black.withValues(alpha: 0.1),
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
        ],
      );
    }

  Widget _buildHotelComparison(PlaceResult place) {
    final pricing = _hotelService.getSimulatedPricing(place.name);
    final city = place.address?.split(',').last.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TripiColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TripiColors.primary.withValues(alpha: 0.1)),
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
            () => _hotelService.launchBooking(place.name, city),
          ),
          const Divider(height: 24, color: TripiColors.outlineVariant),
          _buildProviderRow(
            'Agoda',
            'Agoda',
            pricing['agoda']['price'],
            () => _hotelService.launchAgoda(place.name, city),
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
                color: brandColor.withValues(alpha: 0.1),
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
    
    final int requestId = ++_markerUpdateId;


    try {
      final List<Marker> newMarkers = [];
      final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
      
      // Optimization: Only load images when a specific trip is selected.
      // Loading images for ALL trips is too heavy and causes significant lag.
      final bool shouldLoadImages = filter != null;
      
      if (filter != null) {
        // Single trip scope: number per day
        for (int i = 0; i < filter.days.length; i++) {
          final day = filter.days[i];
          final dayColor = _routeColors[i % _routeColors.length];
          
          for (int j = 0; j < day.activities.length; j++) {
            final activity = day.activities[j];
            if (activity.lat != null && activity.lng != null) {
              ui.Image? placeImage;
              if (shouldLoadImages && activity.imageUrl != null) {
                placeImage = await _loadImage(activity.imageUrl!);
                if (requestId != _markerUpdateId) return; // Cancel if newer request arrived
              }
              final icon = await _createNumberedMarkerIcon(j + 1, dayColor, pixelRatio, placeImage, activity.imageUrl);
              newMarkers.add(
                Marker(
                  markerId: MarkerId('trip_activity_${activity.id}'),
                  position: LatLng(activity.lat!, activity.lng!),
                  icon: icon,
                  infoWindow: InfoWindow.noText,
                  zIndexInt: 20,
                  onTap: () async {
                    if (_isDetailsSheetOpen) return;
                    
                    // Fetch image if missing
                    if ((activity.imageUrl == null || activity.imageUrl!.isEmpty) && activity.placeId != null) {
                      try {
                        debugPrint('Fetching details for placeId: ${activity.placeId}');
                        final details = await _placesService.getPlaceDetails(activity.placeId!);
                        if (details != null && details.photoReferences.isNotEmpty) {
                          final photoRef = details.photoReferences[0];
                          final photoUrl = _placesService.getPhotoUrl(photoRef);
                          debugPrint('Found photo URL: $photoUrl');
                          if (photoUrl != null) {
                            activity.imageUrl = photoUrl;
                          }
                        }
                      } catch (e) {
                        debugPrint('Error fetching image on tap: $e');
                      }
                    }

                    // Animate camera to center the marker
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(LatLng(activity.lat!, activity.lng!)),
                    );

                    // Get initial screen position
                    final screenPos = await _mapController?.getScreenCoordinate(LatLng(activity.lat!, activity.lng!));
                    
                    setState(() {
                      _selectedActivity = activity;
                      _selectedActivityTrip = filter;
                      _selectedActivityDay = day.dayIndex;
                      if (screenPos != null) {
                        _selectedActivityScreenPos = Offset(screenPos.x.toDouble(), screenPos.y.toDouble());
                      }
                    });
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
                if (shouldLoadImages && activity.imageUrl != null) {
                  placeImage = await _loadImage(activity.imageUrl!);
                  if (requestId != _markerUpdateId) return; // Cancel if newer request arrived
                }
                final icon = await _createNumberedMarkerIcon(activityCounter++, tripColor, pixelRatio, placeImage, activity.imageUrl);
                newMarkers.add(
                  Marker(
                    markerId: MarkerId('trip_activity_${activity.id}'),
                    position: LatLng(activity.lat!, activity.lng!),
                    icon: icon,
                    infoWindow: InfoWindow.noText,
                    zIndexInt: 20,
                    onTap: () async {
                      if (_isDetailsSheetOpen) return;
                      
                      // Fetch image if missing
                      if ((activity.imageUrl == null || activity.imageUrl!.isEmpty) && activity.placeId != null) {
                        try {
                          debugPrint('Fetching details for placeId: ${activity.placeId}');
                          final details = await _placesService.getPlaceDetails(activity.placeId!);
                          if (details != null && details.photoReferences.isNotEmpty) {
                            final photoRef = details.photoReferences[0];
                            final photoUrl = _placesService.getPhotoUrl(photoRef);
                            debugPrint('Found photo URL: $photoUrl');
                            if (photoUrl != null) {
                              activity.imageUrl = photoUrl;
                            }
                          }
                        } catch (e) {
                          debugPrint('Error fetching image on tap: $e');
                        }
                      }

                      // Animate camera to center the marker
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(LatLng(activity.lat!, activity.lng!)),
                      );

                      // Get initial screen position
                      final screenPos = await _mapController?.getScreenCoordinate(LatLng(activity.lat!, activity.lng!));
                      
                      setState(() {
                        _selectedActivity = activity;
                        _selectedActivityTrip = trip;
                        _selectedActivityDay = day.dayIndex;
                        if (screenPos != null) {
                          _selectedActivityScreenPos = Offset(screenPos.x.toDouble(), screenPos.y.toDouble());
                        }
                      });
                    },
                  ),
                );
              }
            }
          }
        }
      }

      if (requestId != _markerUpdateId) return;

      if (!mounted) return;
      setState(() {
        _tripMarkers = newMarkers.toSet();

      });
    } catch (e) {
      debugPrint('Error updating trip markers: $e');
      if (mounted && requestId == _markerUpdateId) {

      }
    }
  }

   Future<ui.Image?> _loadImage(String url) async {
    try {
      final proxiedUrl = _placesService.getPhotoUrl(url) ?? url;
      final response = await http.get(Uri.parse(proxiedUrl));
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

    // Google Map Pin proportions to feel standard
    final double width = 27.0 * pixelRatio;
    final double height = 43.0 * pixelRatio;
    final double radius = width / 2;
    
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
        style: TextStyle(
          fontSize: 14 * pixelRatio,
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
    final icon = BitmapDescriptor.bytes(byteData!.buffer.asUint8List(), imagePixelRatio: pixelRatio);
    
    _customMarkerCache[cacheKey] = icon;
    return icon;
  }

  Future<void> _updateBubblePosition() async {
    if (_selectedActivity != null && _mapController != null) {
      final screenPos = await _mapController!.getScreenCoordinate(
        LatLng(_selectedActivity!.lat!, _selectedActivity!.lng!)
      );
      if (mounted) {
        setState(() {
          _selectedActivityScreenPos = Offset(screenPos.x.toDouble(), screenPos.y.toDouble());
        });
      }
    }
  }



  double _calculatePlaceScore(PlaceResult place, LatLng anchor) {
    final dist = _calculateDistance(place.lat, place.lng, anchor.latitude, anchor.longitude);
    
    // 1. Proximity score (0-1): closer is better. 0 at radius limit
    final double proximityScore = math.max(0.0, 1.0 - (dist / _filterDistance));
    
    // 2. Rating score (0-1): 0-5 stars mapped to 0-1
    final double ratingScore = (place.rating ?? 3.0) / 5.0;
    
    // 3. Popularity score (0-1): log scale for reviews
    final double reviewCount = (place.userRatingsTotal ?? 0).toDouble();
    final double popularityScore = math.min(1.0, math.log(reviewCount + 1) / math.log(1000));

    // Weighted Score as per plan: 0.4*proximity + 0.4*rating + 0.2*popularity
    return (0.4 * proximityScore) + (0.4 * ratingScore) + (0.2 * popularityScore);
  }

  void _fitTripBounds(Trip trip) {
    if (_mapController == null) return;
    
    final List<LatLng> points = [];
    for (var day in trip.days) {
      for (var activity in day.activities) {
        if (activity.lat != null && activity.lng != null) {
          points.add(LatLng(activity.lat!, activity.lng!));
        }
      }
    }
    
    if (points.isEmpty) {
      // Fallback to city center if available
      if (trip.cityPlaceId != null) {
        _placesService.getPlaceDetailsRaw(trip.cityPlaceId!).then((details) {
          if (details != null && details['lat'] != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(details['lat'], details['lng']), 12)
            );
          }
        });
      }
      return;
    }
    
    if (points.length == 1) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(points.first, 14));
      return;
    }
    
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80, // padding
      ),
    );
  }

  void _fitAllTripsBounds(List<Trip> trips) {
    final List<LatLng> points = [];
    for (var trip in trips) {
      for (var day in trip.days) {
        for (var activity in day.activities) {
          if (activity.lat != null && activity.lng != null) {
            points.add(LatLng(activity.lat!, activity.lng!));
          }
        }
      }
    }
    
    if (points.isEmpty) {
      // Fallback: If no activities, try to fit to current center or show global view
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentCenter, 10));
      return;
    }
    
    if (points.length == 1) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(points.first, 12));
      return;
    }
    
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80, // padding
      ),
    );
  }
}

class BubblePointerPainter extends CustomPainter {
  final Color color;
  BubblePointerPainter({this.color = TripiColors.surfaceContainerLowest});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
