import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_models.dart';
import '../models/models.dart';
import '../providers/ai_provider.dart';
import '../theme/tripi_colors.dart';
import '../widgets/ai/ai_generation_loading.dart';
import '../widgets/ai/ai_scheduling_loading_overlay.dart';
import '../widgets/ai/ai_recommendation_section.dart';

class AiReviewScreen extends StatefulWidget {
  final Trip trip;
  final int dayIndex;

  const AiReviewScreen({
    super.key,
    required this.trip,
    required this.dayIndex,
  });

  @override
  State<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends State<AiReviewScreen> {
  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(aiProvider, theme),
      body: Stack(
        children: [
          _buildBody(aiProvider, theme),
          if (aiProvider.status == AiGenerationStatus.applying)
            Positioned.fill(
              child: AiSchedulingLoadingOverlay(
                destination: widget.trip.city ?? widget.trip.country,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(aiProvider),
    );
  }

  PreferredSizeWidget _buildAppBar(AiProvider aiProvider, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Discovery',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          Text(
            widget.trip.city ?? widget.trip.country,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
      actions: [
        if (aiProvider.status == AiGenerationStatus.ready)
          TextButton.icon(
            onPressed: () => _showRegenerateOptions(context),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Regenerate'),
            style: TextButton.styleFrom(
              foregroundColor: TripiColors.primary,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(AiProvider aiProvider, ThemeData theme) {
    if (aiProvider.status == AiGenerationStatus.loading) {
      return AiGenerationLoading(
        destination: widget.trip.city ?? widget.trip.country,
      );
    }

    if (aiProvider.status == AiGenerationStatus.error) {
      return _buildError(aiProvider, theme);
    }

    final recs = aiProvider.recommendations;
    if (recs == null || recs.isEmpty) {
      return _buildEmpty(theme);
    }

    return _buildSections(aiProvider, recs);
  }

  Widget _buildSections(AiProvider aiProvider, AiRecommendationSet recs) {
    final options = aiProvider.currentOptions;

    return CustomScrollView(
      slivers: [
        // Active toggles summary chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 16),
            child: AiOptionsChipRow(options: options),
          ),
        ),

        // ── Must-See Landmarks ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: AiRecommendationSection(
            title: 'Must-See Landmarks',
            subtitle: 'Iconic attractions and top sights',
            icon: Icons.star_rate_rounded,
            accentColor: const Color(0xFF3B82F6),
            items: recs.landmarks,
            onAdd: (s) => aiProvider.toggleAccept(s.id),
          ),
        ),

        // ── Local Gems ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: AiRecommendationSection(
            title: 'Local Gems',
            subtitle: 'Hidden favourites loved by locals',
            icon: Icons.explore_rounded,
            accentColor: const Color(0xFF10B981),
            items: recs.localGems,
            onAdd: (s) => aiProvider.toggleAccept(s.id),
            showWhenEmpty: !options.localGems,
            disabledHint: 'Enable "Local Gems" in options to see hidden spots',
          ),
        ),

        // ── Food & Drinks ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: AiRecommendationSection(
            title: 'Food & Drinks',
            subtitle: 'Restaurants and cafes nearby',
            icon: Icons.restaurant_menu_rounded,
            accentColor: const Color(0xFFEF4444),
            items: recs.food,
            onAdd: (s) => aiProvider.toggleAccept(s.id),
            showWhenEmpty: !options.includeRestaurants && !options.includeCafes,
            disabledHint:
                'Enable restaurants or cafes in options to see food spots',
          ),
        ),

        // Bottom padding so content clears the sticky bottom bar
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.search_off_rounded, size: 48, color: Colors.blue[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'No recommendations found',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "We couldn't find places matching your preferences for "
              "${widget.trip.city ?? widget.trip.country}. "
              "Try adjusting your toggles or choosing a different style.",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(AiProvider aiProvider, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Generation Failed', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              aiProvider.error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => aiProvider.generateRecommendations(
              trip: widget.trip,
              options: aiProvider.currentOptions,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(AiProvider aiProvider) {
    if (aiProvider.status != AiGenerationStatus.ready &&
        aiProvider.status != AiGenerationStatus.applying &&
        aiProvider.status != AiGenerationStatus.done) {
      return null;
    }

    final acceptedCount = aiProvider.acceptedCount;
    if (acceptedCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ready to build your day?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'The AI assistant will organize your selected places into an optimized schedule.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: aiProvider.status != AiGenerationStatus.applying
                  ? () async {
                      // Trigger Generation (STEP 2)
                      // Temporary logic until provider is updated:
                      // await aiProvider.generateScheduleFromSelections(widget.trip, widget.dayIndex);
                      // Navigator.pop(context);
                      await aiProvider.applyToItinerary(
                          widget.trip, widget.dayIndex);
                      
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: TripiColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: aiProvider.status == AiGenerationStatus.applying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Generate My Day',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // For now, doing nothing just allows the user to continue scrolling the list
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continue Editing'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegenerateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Regenerate Suggestions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Not quite what you were looking for?',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildStyleTile(
              context,
              'Different Vibe',
              'Completely different suggestions',
              Icons.shuffle_rounded,
              RegenerationStyle.different,
            ),
            _buildStyleTile(
              context,
              'More Relaxed',
              'Shorter activities and more free time',
              Icons.spa_outlined,
              RegenerationStyle.moreRelaxed,
            ),
            _buildStyleTile(
              context,
              'More Local',
              'Less touristy, hidden gems only',
              Icons.explore_rounded,
              RegenerationStyle.moreLocal,
            ),
            _buildStyleTile(
              context,
              'Most Popular',
              'Top-rated landmarks and icons only',
              Icons.star_rounded,
              RegenerationStyle.morePopular,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    RegenerationStyle style,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: TripiColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: TripiColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500])),
      onTap: () {
        Navigator.pop(context);
        context.read<AiProvider>().generateDailyItinerary(
              trip: widget.trip,
              dayIndex: widget.dayIndex,
              style: style,
            );
      },
    );
  }
}
