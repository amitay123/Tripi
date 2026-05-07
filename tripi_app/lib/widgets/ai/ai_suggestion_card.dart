import 'package:flutter/material.dart';
import '../../models/ai_models.dart';
import '../../theme/tripi_colors.dart';

class AiSuggestionCard extends StatelessWidget {
  final AiSuggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const AiSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAccepted = suggestion.isAccepted;
    final isRejected = suggestion.isRejected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isAccepted
            ? TripiColors.primary.withValues(alpha: 0.05)
            : isRejected
                ? Colors.grey.withValues(alpha: 0.05)
                : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAccepted
              ? TripiColors.primary.withValues(alpha: 0.3)
              : isRejected
                  ? Colors.grey.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
          width: isAccepted ? 2 : 1,
        ),
        boxShadow: [
          if (!isRejected)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Image
          if (suggestion.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              child: Stack(
                children: [
                  Image.network(
                    suggestion.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildConfidenceTag(suggestion.confidence),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isRejected ? Colors.grey : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.category_outlined,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                suggestion.category,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${suggestion.estimatedDuration} min',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (suggestion.recommendedArrivalTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: TripiColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          suggestion.recommendedArrivalTime!,
                          style: TextStyle(
                            color: TripiColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 16, color: TripiColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.explanation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[800],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (suggestion.mayBeClosed) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        'May be closed at this time',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: Icon(
                          isRejected ? Icons.undo : Icons.close,
                          size: 18,
                        ),
                        label: Text(isRejected ? 'Undo' : 'Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isRejected ? Colors.grey[600] : Colors.red[400],
                          side: BorderSide(
                            color: isRejected ? Colors.grey[300]! : Colors.red[100]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: Icon(
                          isAccepted ? Icons.check_circle : Icons.add,
                          size: 18,
                        ),
                        label: Text(isAccepted ? 'Added' : 'Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAccepted ? Colors.green : TripiColors.primary,
                          foregroundColor: Colors.white,
                          elevation: isAccepted ? 0 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceTag(AiConfidence confidence) {
    Color color;
    String text;
    IconData icon;

    switch (confidence) {
      case AiConfidence.highlyRecommended:
        color = const Color(0xFF6366F1); // Indigo
        text = 'Highly Recommended';
        icon = Icons.star;
        break;
      case AiConfidence.greatMatch:
        color = Colors.teal;
        text = 'Great Match';
        icon = Icons.favorite;
        break;
      case AiConfidence.popularChoice:
        color = Colors.orange;
        text = 'Popular Choice';
        icon = Icons.trending_up;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
