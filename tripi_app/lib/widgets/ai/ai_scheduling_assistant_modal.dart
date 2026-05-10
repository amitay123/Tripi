import 'package:flutter/material.dart';
import '../../theme/tripi_colors.dart';

class AiSchedulingAssistantModal extends StatefulWidget {
  final int placeCount;
  final Future<void> Function() onSchedule;
  final VoidCallback onSkip;

  const AiSchedulingAssistantModal({
    super.key,
    required this.placeCount,
    required this.onSchedule,
    required this.onSkip,
  });

  @override
  State<AiSchedulingAssistantModal> createState() => _AiSchedulingAssistantModalState();

  static Future<void> show(
    BuildContext context, {
    required int placeCount,
    required Future<void> Function() onSchedule,
    required VoidCallback onSkip,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AiSchedulingAssistantModal(
        placeCount: placeCount,
        onSchedule: onSchedule,
        onSkip: onSkip,
      ),
    );
  }
}

class _AiSchedulingAssistantModalState extends State<AiSchedulingAssistantModal> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('AiSchedulingAssistantModal: initState with placeCount=${widget.placeCount}');
  }

  Future<void> _handleSchedule() async {
    setState(() => _isLoading = true);
    try {
      await widget.onSchedule();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AiSchedulingAssistantModal: building with isLoading=$_isLoading');
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Message
          Text(
            widget.placeCount == 1 
                ? 'Added 1 attraction' 
                : 'Added ${widget.placeCount} attractions',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Would you like me to schedule them for you?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          // Primary Action
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: TripiColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: TripiColors.primary.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Schedule for me',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // Secondary Action
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: _isLoading ? null : widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[500],
              ),
              child: const Text(
                'Maybe later',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}
