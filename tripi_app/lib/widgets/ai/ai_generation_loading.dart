import 'package:flutter/material.dart';
import '../../theme/tripi_colors.dart';

class AiGenerationLoading extends StatefulWidget {
  final String destination;
  const AiGenerationLoading({super.key, required this.destination});

  @override
  State<AiGenerationLoading> createState() => _AiGenerationLoadingState();
}

class _AiGenerationLoadingState extends State<AiGenerationLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;

  final List<String> _steps = [
    'Scanning cross-trip memory...',
    'Checking opening hours in {dest}...',
    'Optimizing geographic route...',
    'Matching your travel preferences...',
    'Validating time budget...',
    'Balancing daily intensity...',
    'Polishing your itinerary...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addListener(() {
        final step = (_controller.value * _steps.length).floor();
        if (step != _currentStep && step < _steps.length) {
          setState(() => _currentStep = step);
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentText = _steps[_currentStep].replaceAll('{dest}', widget.destination);

    return Container(
      width: double.infinity,
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
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The AI is crafting a journey unique to you',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 40),
          LinearProgressIndicator(
            value: _controller.value,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(TripiColors.primary),
            minHeight: 2,
          ),
        ],
      ),
    );
  }
}
