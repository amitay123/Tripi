import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_models.dart';
import '../models/models.dart';
import '../providers/ai_provider.dart';
import '../theme/tripi_colors.dart';
import '../widgets/ai/ai_suggestion_card.dart';
import '../widgets/ai/ai_generation_loading.dart';

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
  void initState() {
    super.initState();
    // Initial generation handled by the caller, but we ensure it's loaded
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Reviewing Day ${widget.dayIndex + 1} in ${widget.trip.city ?? widget.trip.country}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          if (aiProvider.status == AiGenerationStatus.ready)
            TextButton(
              onPressed: () => _showRegenerateOptions(context),
              child: const Text('Regenerate'),
            ),
        ],
      ),
      body: _buildBody(aiProvider),
      bottomNavigationBar: _buildBottomBar(aiProvider),
    );
  }

  Widget _buildBody(AiProvider aiProvider) {
    if (aiProvider.status == AiGenerationStatus.loading) {
      return AiGenerationLoading(
        destination: widget.trip.city ?? widget.trip.country,
      );
    }

    if (aiProvider.status == AiGenerationStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Generation Failed', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(aiProvider.error ?? 'Unknown error occurred'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => aiProvider.generateDailyItinerary(
                trip: widget.trip,
                dayIndex: widget.dayIndex,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (aiProvider.suggestions.isEmpty) {
      return const Center(child: Text('No suggestions found for this criteria.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: aiProvider.suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = aiProvider.suggestions[index];
        return AiSuggestionCard(
          suggestion: suggestion,
          onAccept: () => aiProvider.toggleAccept(suggestion.id),
          onReject: () => aiProvider.toggleReject(suggestion.id),
        );
      },
    );
  }

  Widget? _buildBottomBar(AiProvider aiProvider) {
    if (aiProvider.status != AiGenerationStatus.ready && 
        aiProvider.status != AiGenerationStatus.applying) {
      return null;
    }

    final acceptedCount = aiProvider.suggestions.where((s) => s.isAccepted).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$acceptedCount Items Selected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Will be added to your itinerary',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 56,
              width: 160,
              child: ElevatedButton(
                onPressed: acceptedCount > 0 && aiProvider.status != AiGenerationStatus.applying
                    ? () async {
                        await aiProvider.applyToItinerary(widget.trip, widget.dayIndex);
                        if (mounted) Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TripiColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
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
                        'Apply Changes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
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
            const Text(
              'Regenerate Suggestions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Not quite what you were looking for?',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildStyleTile(
              context,
              'Different Vibe',
              'Completely different suggestions',
              Icons.shuffle,
              RegenerationStyle.different,
            ),
            _buildStyleTile(
              context,
              'More Relaxed',
              'Shorter activities and more breaks',
              Icons.spa_outlined,
              RegenerationStyle.moreRelaxed,
            ),
            _buildStyleTile(
              context,
              'More Local',
              'Less popular, hidden gems',
              Icons.location_on_outlined,
              RegenerationStyle.moreLocal,
            ),
            _buildStyleTile(
              context,
              'Most Popular',
              'Top-rated landmarks only',
              Icons.star_outline,
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
      leading: Icon(icon, color: TripiColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
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
