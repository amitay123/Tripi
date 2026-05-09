import 'package:flutter/material.dart';
import '../../models/ai_models.dart';
import '../../theme/tripi_colors.dart';

/// A compact horizontal-scroll card for an AI recommendation.
/// Fixed width (~270px) so users can peek the next card.
class AiHorizontalCard extends StatelessWidget {
  final AiSuggestion suggestion;
  final VoidCallback onAdd;

  const AiHorizontalCard({
    super.key,
    required this.suggestion,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isAdded = suggestion.isAccepted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: 270,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: isAdded
            ? TripiColors.primary.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdded
              ? TripiColors.primary.withValues(alpha: 0.35)
              : Colors.grey.withValues(alpha: 0.13),
          width: isAdded ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ────────────────────────────────────────────────────────
            _buildImage(),

            // ── Details ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + category badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          suggestion.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CategoryBadge(category: suggestion.category),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating + review count
                  _buildRatingRow(),
                  const SizedBox(height: 8),

                  // AI explanation
                  Text(
                    suggestion.explanation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: isAdded
                          ? _buildAddedButton(context)
                          : _buildAddButton(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        if (suggestion.imageUrl != null)
          Image.network(
            suggestion.imageUrl!,
            height: 130,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          )
        else
          _placeholder(),

        // Confidence badge
        Positioned(
          top: 10,
          left: 10,
          child: _ConfidenceBadge(confidence: suggestion.confidence),
        ),

        // Local Gem badge
        if (suggestion.isLocalGem)
          Positioned(
            top: 10,
            right: 10,
            child: _GemBadge(),
          ),

        // Duration chip at bottom
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time,
                    size: 11, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  '${suggestion.estimatedDuration} min',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      height: 130,
      width: double.infinity,
      color: Colors.grey[100],
      child: Icon(Icons.image_outlined,
          size: 36, color: Colors.grey[300]),
    );
  }

  Widget _buildRatingRow() {
    final rating = suggestion.popularityScore;
    final reviews = suggestion.userRatingsTotal;
    return Row(
      children: [
        // Stars
        Row(
          children: List.generate(5, (i) {
            if (i < rating.floor()) {
              return const Icon(Icons.star_rounded,
                  size: 13, color: Color(0xFFFFB800));
            } else if (i < rating) {
              return const Icon(Icons.star_half_rounded,
                  size: 13, color: Color(0xFFFFB800));
            }
            return Icon(Icons.star_outline_rounded,
                size: 13, color: Colors.grey[300]);
          }),
        ),
        const SizedBox(width: 5),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          reviews > 0 ? '(${_formatReviews(reviews)})' : '',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton.icon(
      key: const ValueKey('add'),
      onPressed: onAdd,
      icon: const Icon(Icons.add, size: 16),
      label: const Text(
        'Add to Trip',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: TripiColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildAddedButton(BuildContext context) {
    return ElevatedButton.icon(
      key: const ValueKey('added'),
      onPressed: onAdd, // tap again to un-add
      icon: const Icon(Icons.check_circle, size: 16),
      label: const Text(
        'Added',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _formatReviews(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k+';
    return n.toString();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _color().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color().withValues(alpha: 0.25)),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: _color(),
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Color _color() {
    switch (category) {
      case 'Museum':
      case 'Art Gallery':
        return const Color(0xFF6366F1);
      case 'Restaurant':
        return const Color(0xFFEF4444);
      case 'Cafe':
        return const Color(0xFFF59E0B);
      case 'Park':
      case 'Nature':
        return const Color(0xFF10B981);
      case 'Landmark':
      case 'Attraction':
        return const Color(0xFF3B82F6);
      case 'Historical Site':
        return const Color(0xFF8B5CF6);
      case 'Amusement Park':
      case 'Zoo':
      case 'Aquarium':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF64748B);
    }
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final AiConfidence confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (confidence) {
      case AiConfidence.highlyRecommended:
        color = const Color(0xFF6366F1);
        text = 'Top Pick';
        icon = Icons.auto_awesome;
        break;
      case AiConfidence.greatMatch:
        color = Colors.teal;
        text = 'Great Match';
        icon = Icons.favorite_rounded;
        break;
      case AiConfidence.popularChoice:
        color = Colors.orange;
        text = 'Popular';
        icon = Icons.trending_up_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GemBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_rounded, size: 10, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'Local Gem',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
