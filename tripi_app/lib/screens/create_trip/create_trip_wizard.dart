import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import 'steps/basic_info_step.dart';
import 'steps/dates_travelers_step.dart';
import 'steps/preferences_step.dart';
import 'steps/review_step.dart';

class CreateTripWizard extends StatefulWidget {
  const CreateTripWizard({super.key});

  @override
  State<CreateTripWizard> createState() => _CreateTripWizardState();
}

class _CreateTripWizardState extends State<CreateTripWizard> {
  final PageController _pageController = PageController();
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepChanged(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final currentStep = tripProvider.currentStep;
    final draftTrip = tripProvider.draftTrip;

    if (draftTrip == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Step ${currentStep + 1} of 4',
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 120,
                height: 4,
                child: LinearProgressIndicator(
                  value: (currentStep + 1) / 4,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save',
                style: TextStyle(
                    color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          BasicInfoStep(),
          DatesTravelersStep(),
          PreferencesStep(),
          ReviewStep(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border:
                Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              if (currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      tripProvider.previousStep();
                      _onStepChanged(tripProvider.currentStep);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    child: const Text('Back',
                        style: TextStyle(
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              if (currentStep > 0) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (currentStep == 3) {
                            setState(() => _isSaving = true);
                            final success = await tripProvider.saveTrip();
                            setState(() => _isSaving = false);

                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Trip created! Start exploring your itinerary.'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(tripProvider.lastError ??
                                      'Failed to save trip. Please check your connection or database setup.'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                  action: SnackBarAction(
                                    label: 'DISMISS',
                                    textColor: Colors.white,
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (_validateStep(currentStep, tripProvider)) {
                              tripProvider.nextStep();
                              _onStepChanged(tripProvider.currentStep);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please fill in all required fields.')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    minimumSize: const Size(0, 60),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          currentStep == 3 ? 'Create Trip' : 'Continue',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateStep(int step, TripProvider provider) {
    final trip = provider.draftTrip!;
    switch (step) {
      case 0:
        return trip.name.isNotEmpty && trip.country.isNotEmpty;
      case 1:
        return trip.endDate.isAfter(trip.startDate) ||
            trip.endDate.isAtSameMomentAs(trip.startDate);
      case 2:
        return trip.tripType != null; // Enum has a default but check is good
      default:
        return true;
    }
  }
}
