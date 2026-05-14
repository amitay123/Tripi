import 'package:flutter/material.dart';
import '../../theme/tripi_colors.dart';

class AiSchedulingLoadingOverlay extends StatefulWidget {
  final String destination;
  const AiSchedulingLoadingOverlay({super.key, required this.destination});

  @override
  State<AiSchedulingLoadingOverlay> createState() => _AiSchedulingLoadingOverlayState();
}

class _AiSchedulingLoadingOverlayState extends State<AiSchedulingLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;

  final List<String> _steps = [
    'Building your perfect day...',
    'Calculating walking routes...',
    'Finding lunch spots...',
    'Optimizing schedule...',
    'Finalizing itinerary...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        final step = (_controller.value * _steps.length).floor();
        if (step != _currentStep && step < _steps.length) {
          setState(() => _currentStep = step);
        }
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentText = _steps[_currentStep];

    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(
                  value: _controller.value,
                  strokeWidth: 4,
                  valueColor: const AlwaysStoppedAnimation<Color>(TripiColors.primary),
                  backgroundColor: TripiColors.primary.withValues(alpha: 0.1),
                ),
              ),
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: TripiColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: TripiColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              currentText,
              key: ValueKey(currentText),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
