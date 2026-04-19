import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../theme/tripi_colors.dart';
import 'steps/basic_info_step.dart';
import 'steps/dates_step.dart';
import 'steps/travelers_step.dart';
import 'steps/budget_step.dart';
import 'steps/preferences_step.dart';
import 'steps/itinerary_setup_step.dart';
import 'steps/review_step.dart';

class CreateTripWizard extends StatefulWidget {
  const CreateTripWizard({super.key});

  @override
  State<CreateTripWizard> createState() => _CreateTripWizardState();
}

class _CreateTripWizardState extends State<CreateTripWizard> {
  final PageController _pageController = PageController();

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
          icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Step ${currentStep + 1} of 7',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                width: 100,
                height: 4,
                child: LinearProgressIndicator(
                  value: (currentStep + 1) / 7,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: const AlwaysStoppedAnimation<Color>(TripiColors.primary),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Save draft logic (could be backgrounded)
              Navigator.pop(context);
            },
            child: const Text('Save Draft', style: TextStyle(color: Color(0xFF6B7280))),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          BasicInfoStep(),
          DatesStep(),
          TravelersStep(),
          BudgetStep(),
          PreferencesStep(),
          ItinerarySetupStep(),
          ReviewStep(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
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
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    child: const Text('Back', style: TextStyle(color: Color(0xFF4B5563))),
                  ),
                ),
              if (currentStep > 0) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    if (currentStep == 6) {
                      if (tripProvider.saveTrip()) {
                        Navigator.pop(context);
                        // Show success feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trip created successfully!')),
                        );
                      }
                    } else {
                      // Add validation here per step
                      if (_validateStep(currentStep, tripProvider)) {
                        tripProvider.nextStep();
                        _onStepChanged(tripProvider.currentStep);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TripiColors.primary,
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    currentStep == 6 ? 'Confirm & Create' : 'Next',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        return trip.endDate.isAfter(trip.startDate) || trip.endDate.isAtSameMomentAs(trip.startDate);
      case 2:
        return trip.travelersCount > 0;
      default:
        return true;
    }
  }
}
