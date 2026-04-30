
method = """
  Widget _buildActivityItem(BuildContext context, Trip trip, TripDay day,
      Activity activity, int index, String arrivalTime,
      {required Key key}) {
    return Column(
      key: key,
      children: [
        if (index > 0)
          _buildTimelineTransportDivider(context, trip, day, activity),
        Dismissible(
          key: Key('dismiss_${activity.id}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            context
                .read<TripProvider>()
                .deleteActivity(trip.id, day.dayIndex, activity.id);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 2,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(activity),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Icon(_getCategoryIcon(activity),
                          color: _getCategoryIconColor(activity), size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(activity.duration),
                      style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TripiCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activity.imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                            child: Image.network(
                              activity.imageUrl!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      arrivalTime,
                                      style: const TextStyle(
                                          color: TripiColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      activity.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1E293B)),
                                    ),
                                    if (activity.address != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          activity.address!,
                                          style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 12),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: () {
                                        if (activity.placeId != null &&
                                            activity.placeId!.isNotEmpty) {
                                          Navigator.of(context).pushNamed(
                                            '/place-details',
                                            arguments: activity.placeId,
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              'View Details',
                                              style: TextStyle(
                                                color: TripiColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: TripiColors.primary,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.drag_handle,
                                      color: Color(0xFFCBD5E1), size: 24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
"""

open_p = method.count('(')
close_p = method.count(')')
open_b = method.count('[')
close_b = method.count(']')
open_c = method.count('{')
close_c = method.count('}')

print(f"Parentheses: ({open_p}, {close_p})")
print(f"Brackets: [{open_b}, {close_b}]")
print(f"Curly: {{{open_c}, {close_c}}}")
if open_p == close_p and open_b == close_b and open_c == close_c:
    print("ALL BALANCED")
else:
    print("MISMATCH DETECTED")
