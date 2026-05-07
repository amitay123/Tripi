import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tripi_colors.dart';
import '../services/places_service.dart';
import '../models/place_result.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../models/models.dart';

class PlaceDetailsScreen extends StatefulWidget {
  const PlaceDetailsScreen({super.key});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool _isLoading = true;
  PlaceResult? _placeDetail;
  bool _isDescriptionExpanded = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPlaceDetails();
  }

  Future<void> _fetchPlaceDetails() async {
    // We get the placeId from the arguments
    // For now, if no arguments, we try to use the selected destination from BookingProvider as a fallback
    // But better to pass it directly.

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final String? placeId =
          ModalRoute.of(context)?.settings.arguments as String?;

      if (placeId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await PlacesService().getPlaceDetails(placeId);
      if (data != null) {
        setState(() {
          _placeDetail = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: TripiColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_placeDetail == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Place details not found')),
      );
    }

    return Scaffold(
      backgroundColor: TripiColors.background,
      body: Stack(
        children: [
          // Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroImage(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(),
                      const SizedBox(height: 32),
                      _buildAboutSection(),
                      const SizedBox(height: 32),
                      _buildInfoGrid(),
                      const SizedBox(height: 140), // Space for sticky buttons
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Custom Header
          _buildHeader(),

          // Sticky Bottom Buttons
          _buildStickyButtons(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=tripi'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    final photos = _placeDetail!.photoReferences;
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: photos.isEmpty
                ? Container(
                    color: TripiColors.surfaceContainerLow,
                    child: const Icon(Icons.image,
                        size: 64, color: TripiColors.outlineVariant),
                  )
                : PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentImageIndex = index),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final url = PlacesService().getPhotoUrl(photos[index]);
                      return Image.network(
                        url ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: TripiColors.surfaceContainerLow,
                          child: const Icon(Icons.broken_image),
                        ),
                      );
                    },
                  ),
          ),
        ),
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),
        // Carousel indicators
        if (photos.length > 1)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length > 5
                    ? 5
                    : photos.length, // Limit to 5 dots for clean look
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 12 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _placeDetail!.name,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: TripiColors.onSurface,
                ),
              ),
            ),
            if (_placeDetail!.rating != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: TripiColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      _placeDetail!.rating.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TripiColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: TripiColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _placeDetail!.formattedAddress ?? 'Location not available',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: TripiColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    if (_placeDetail!.description == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: TripiColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _placeDetail!.description!,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: TripiColors.onSurfaceVariant,
            height: 1.5,
          ),
          maxLines: _isDescriptionExpanded ? null : 3,
          overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
        ),
        GestureDetector(
          onTap: () =>
              setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _isDescriptionExpanded ? 'Read less' : 'Read more',
              style: GoogleFonts.inter(
                color: TripiColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.access_time_filled,
            title: 'HOURS',
            value: _placeDetail!.todayHours ?? 'Hours not available',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.confirmation_number,
            title: 'PRICING',
            value: _placeDetail!.priceLevelString.isNotEmpty
                ? _placeDetail!.priceLevelString
                : 'Check availability',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      {required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: TripiColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: TripiColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TripiColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStickyButtons() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Column(
        children: [
          if (_placeDetail!.types.contains('lodging')) ...[
            Row(
              children: [
                Expanded(
                  child: _buildBookingButton(
                    'Booking.com',
                    'https://www.booking.com/searchresults.html?ss=${Uri.encodeComponent(_placeDetail!.name)}',
                    const Color(0xFF003580),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBookingButton(
                    'Agoda',
                    'https://www.agoda.com/search?text=${Uri.encodeComponent(_placeDetail!.name)}',
                    const Color(0xFFF33D5D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else if (_placeDetail!.website != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: OutlinedButton(
                onPressed: () => launchUrl(Uri.parse(_placeDetail!.website!)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: TripiColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(
                  'Visit Website',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: TripiColors.primary),
                ),
              ),
            ),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                _showAddToTripDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              child: Text(
                '+ Add to Itinerary',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(String label, String url, Color color) {
    return ElevatedButton(
      onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddToTripDialog() {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    if (tripProvider.trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active trips found. Create a trip first!')),
      );
      return;
    }

    // Use the first trip or a logic to select a trip if multiple exist
    final trip = tripProvider.trips.first; 

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Text(
              'Add to Trip',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: TripiColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trip.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: TripiColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: trip.days.length,
                itemBuilder: (context, index) {
                  final day = trip.days[index];
                  return GestureDetector(
                    onTap: () {
                      final activity = Activity(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _placeDetail!.name,
                        types: _placeDetail!.types,
                        lat: _placeDetail!.lat,
                        lng: _placeDetail!.lng,
                        placeId: _placeDetail!.placeId,
                        imageUrl: _placeDetail!.photoReferences.isNotEmpty
                            ? PlacesService()
                                .getPhotoUrl(_placeDetail!.photoReferences.first)
                            : null,
                        address: _placeDetail!.formattedAddress,
                        rating: _placeDetail!.rating,
                      );
                      
                      tripProvider.addActivity(trip.id, day.dayIndex, activity);
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to Day ${day.dayIndex}'),
                          backgroundColor: TripiColors.primary,
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: TripiColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: TripiColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Day',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: TripiColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.dayIndex}',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: TripiColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.luggage, 'Trips'),
          _buildNavItem(Icons.calendar_month_outlined, 'Timeline'),
          _buildNavItem(Icons.map, 'Explore', isActive: true),
          _buildNavItem(Icons.bookmark_border_rounded, 'Saved'),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? TripiColors.primary : const Color(0xFF9CA3AF),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isActive ? TripiColors.primary : const Color(0xFF9CA3AF),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
