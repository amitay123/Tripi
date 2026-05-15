import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../theme/tripi_colors.dart';
import '../services/places_service.dart';
import '../services/place_details_cache_service.dart';
import '../models/place_result.dart';
import '../models/models.dart';
import '../providers/trip_provider.dart';
import '../utils/hours_normalizer.dart';
import '../widgets/place_details/image_carousel_widget.dart';
import '../widgets/place_details/expandable_text_widget.dart';

void _trackEvent(String name, {Map<String, dynamic>? props}) {
  debugPrint('[Analytics] $name ${props ?? ''}');
}

class PlaceDetailsScreen extends StatefulWidget {
  const PlaceDetailsScreen({super.key});
  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool _isLoading = true;
  PlaceResult? _place;
  bool _addSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _trackEvent('place_details_opened');
  }

  Future<void> _load() async {
    final placeId = ModalRoute.of(context)?.settings.arguments as String?;
    if (placeId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final cached = await PlaceDetailsCacheService.get(placeId);
    if (cached != null) {
      setState(() { _place = cached; _isLoading = false; });
      PlacesService().getPlaceDetails(placeId).then((fresh) {
        if (fresh != null && mounted) {
          setState(() => _place = fresh);
          PlaceDetailsCacheService.set(placeId, fresh);
        }
      });
      return;
    }
    final data = await PlacesService().getPlaceDetails(placeId);
    if (mounted) {
      setState(() { _place = data; _isLoading = false; });
      if (data != null) PlaceDetailsCacheService.set(placeId, data);
    }
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;
    const suspicious = ['bit.ly', 'tinyurl.com', 'goo.gl', 't.co'];
    return !suspicious.any((d) => uri.host.contains(d));
  }

  String _pricingLabel(PlaceResult p) {
    final lvl = p.priceLevel;
    if (lvl == null) return 'Check availability';
    if (lvl == 0) return 'Free entry';
    final sym = p.types.contains('lodging') ? '\$' : '€';
    return sym * lvl;
  }

  String _pricingSubtitle(PlaceResult p) {
    if (p.types.any((t) => ['restaurant','cafe','food','bar'].contains(t))) {
      return 'Per person estimate';
    }
    if (p.types.contains('lodging')) return 'From per night';
    return 'Admission';
  }

  List<String> _deduplicatedUrls(PlaceResult p) {
    final seen = <String>{};
    return p.photoReferences
        .map((ref) => PlacesService().getPhotoUrl(ref))
        .whereType<String>()
        .where((url) => seen.add(url))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: _isLoading ? _buildSkeleton() : _place == null ? _buildError() : _buildContent(),
    );
  }

  Widget _buildSkeleton() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.width * 9 / 16,
          backgroundColor: Colors.white,
          leading: _backButton(),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: const Color(0xFFDDE5EF)),
          ),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            _shimmerBox(28, double.infinity),
            const SizedBox(height: 12),
            _shimmerBox(16, 200),
            const SizedBox(height: 32),
            _shimmerBox(16, 60),
            const SizedBox(height: 12),
            _shimmerBox(15, double.infinity),
            _shimmerBox(15, double.infinity),
            _shimmerBox(15, 160),
          ]),
        )),
      ],
    );
  }

  Widget _shimmerBox(double height, double width) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 0.85),
      duration: const Duration(milliseconds: 800),
      builder: (_, v, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFE0E7EF), const Color(0xFFF0F4F9), v),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          leading: _backButton()),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.location_off_outlined, size: 56, color: Color(0xFFADB3B5)),
        const SizedBox(height: 16),
        Text('Place details unavailable', style: GoogleFonts.inter(fontSize: 17, color: TripiColors.onSurface, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Please try again later', style: GoogleFonts.inter(fontSize: 14, color: TripiColors.onSurfaceVariant)),
        const SizedBox(height: 24),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
      ])),
    );
  }

  Widget _buildContent() {
    final p = _place!;
    final urls = _deduplicatedUrls(p);
    final todayHours = HoursNormalizerUtil.getTodayHours(p.openingHours);
    final isOpen = HoursNormalizerUtil.isOpenNow(p.openingHours);
    final hasWebsite = _isValidUrl(p.website);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.width * 9 / 16,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: _backButton(),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: ImageCarouselWidget(
                key: ValueKey(p.placeId),
                imageUrls: urls,
                onImageSwiped: () => _trackEvent('image_swiped'),
                onFullscreenOpened: () => _trackEvent('fullscreen_image_opened'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildTitle(p),
                if (p.description != null) ...[
                  const SizedBox(height: 28),
                  _buildAbout(p),
                ],
                const SizedBox(height: 28),
                _buildInfoCards(p, todayHours, isOpen),
                const SizedBox(height: 28),
                _buildWebsiteButton(p, hasWebsite),
                const SizedBox(height: 12),
                _buildAddButton(p),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return Semantics(
      button: true,
      label: 'Go back',
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTitle(PlaceResult p) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Text(p.name, style: GoogleFonts.inter(
            fontSize: 26, fontWeight: FontWeight.bold, color: TripiColors.onSurface,
          )),
        ),
        if (p.rating != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: TripiColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
              const SizedBox(width: 4),
              Text(p.rating!.toStringAsFixed(1), style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.bold, color: TripiColors.primary,
              )),
            ]),
          ),
        ],
      ]),
      if (p.formattedAddress != null) ...[
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.location_on_rounded, size: 15, color: TripiColors.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(p.formattedAddress!, style: GoogleFonts.inter(
            fontSize: 13, color: TripiColors.onSurfaceVariant,
          ), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
      ],
    ]);
  }

  Widget _buildAbout(PlaceResult p) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('About', style: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.bold, color: TripiColors.onSurface,
      )),
      const SizedBox(height: 10),
      ExpandableTextWidget(
        text: p.description!,
        storageKey: PageStorageKey('desc_${p.placeId}'),
      ),
    ]);
  }

  Widget _buildInfoCards(PlaceResult p, String? todayHours, bool? isOpen) {
    _trackEvent('hours_viewed');
    _trackEvent('pricing_viewed');
    return Row(children: [
      Expanded(child: _infoCard(
        icon: Icons.access_time_rounded,
        title: 'HOURS',
        value: todayHours ?? 'Hours unavailable',
        badge: isOpen == null ? null : isOpen ? 'Open now' : 'Closed',
        badgeColor: isOpen == true ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
      )),
      const SizedBox(width: 14),
      Expanded(child: _infoCard(
        icon: Icons.confirmation_number_outlined,
        title: 'PRICING',
        value: _pricingLabel(p),
        subtitle: p.priceLevel != null ? _pricingSubtitle(p) : null,
      )),
    ]);
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    String? badge,
    Color? badgeColor,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: TripiColors.primary, size: 22),
        const SizedBox(height: 10),
        Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold,
            color: TripiColors.onSurfaceVariant, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
            color: TripiColors.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
        if (badge != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor!.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(badge, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor)),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: TripiColors.onSurfaceVariant)),
        ],
      ]),
    );
  }

  Widget _buildWebsiteButton(PlaceResult p, bool hasWebsite) {
    return Semantics(
      button: true,
      label: hasWebsite ? 'Visit official website' : 'Website unavailable',
      child: Opacity(
        opacity: hasWebsite ? 1.0 : 0.4,
        child: OutlinedButton.icon(
          onPressed: hasWebsite ? () => _launchWebsite(p.website!) : null,
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text(hasWebsite ? 'Visit Website' : 'Website unavailable'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            foregroundColor: TripiColors.primary,
            side: const BorderSide(color: TripiColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Future<void> _launchWebsite(String url) async {
    _trackEvent('visit_website_clicked');
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      _trackEvent(ok ? 'website_launch_success' : 'website_launch_failed');
    } catch (_) {
      _trackEvent('website_launch_failed');
    }
  }

  Widget _buildAddButton(PlaceResult p) {
    return Semantics(
      button: true,
      label: 'Add to itinerary',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: _addSuccess
              ? const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)])
              : const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
          borderRadius: BorderRadius.circular(27),
          boxShadow: [BoxShadow(
            color: (_addSuccess ? const Color(0xFF22C55E) : const Color(0xFF3B82F6)).withValues(alpha: 0.3),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: ElevatedButton(
          onPressed: () => _showAddToItinerary(p),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _addSuccess
                ? Row(key: const ValueKey('success'), mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Added!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ])
                : Row(key: const ValueKey('add'), mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text('Add to Itinerary', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
          ),
        ),
      ),
    );
  }

  void _showAddToItinerary(PlaceResult p) {
    _trackEvent('add_to_itinerary_clicked');
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    if (tripProvider.trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Create a trip first to add places to it.'),
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToItinerarySheet(
        place: p,
        tripProvider: tripProvider,
        onAdded: (tripName, dayIndex) {
          _trackEvent('add_to_itinerary_completed', props: {
            'place_id': p.placeId,
            'place_name': p.name,
            'day_index': dayIndex,
          });
          setState(() => _addSuccess = true);
          HapticFeedback.lightImpact();
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) setState(() => _addSuccess = false);
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Added to $tripName — Day $dayIndex'),
            backgroundColor: TripiColors.primary,
          ));
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add To Itinerary Bottom Sheet
// ---------------------------------------------------------------------------

class _AddToItinerarySheet extends StatefulWidget {
  final PlaceResult place;
  final TripProvider tripProvider;
  final void Function(String tripName, int dayIndex) onAdded;

  const _AddToItinerarySheet({
    required this.place,
    required this.tripProvider,
    required this.onAdded,
  });

  @override
  State<_AddToItinerarySheet> createState() => _AddToItinerarySheetState();
}

class _AddToItinerarySheetState extends State<_AddToItinerarySheet> {
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
