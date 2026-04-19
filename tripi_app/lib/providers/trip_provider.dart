import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';

class TripProvider extends ChangeNotifier {
  // --- Trips List ---
  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  void fetchTrips(String userId) {
    _trips = MockDataService.allTrips.where((t) => t.userId == userId).toList();
    notifyListeners();
  }

  // --- Wizard State ---
  Trip? _draftTrip;
  int _currentStep = 0;

  Trip? get draftTrip => _draftTrip;
  int get currentStep => _currentStep;

  void startNewTrip(String userId) {
    _draftTrip = Trip(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: '',
      country: '',
      startDate: DateTime.now().add(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 14)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _currentStep = 0;
    notifyListeners();
  }

  void updateDraft(Trip updatedTrip) {
    _draftTrip = updatedTrip;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 6) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 6) {
      _currentStep = step;
      notifyListeners();
    }
  }

  bool saveTrip() {
    if (_draftTrip == null) return false;

    // In a real app, this would be an API call
    final newRealTrip = Trip(
      id: 't${MockDataService.allTrips.length + 1}',
      userId: _draftTrip!.userId,
      name: _draftTrip!.name,
      country: _draftTrip!.country,
      city: _draftTrip!.city,
      startDate: _draftTrip!.startDate,
      endDate: _draftTrip!.endDate,
      travelersCount: _draftTrip!.travelersCount,
      travelersBreakdown: _draftTrip!.travelersBreakdown,
      tripType: _draftTrip!.tripType,
      travelStyle: _draftTrip!.travelStyle,
      budgetTotal: _draftTrip!.budgetTotal,
      currency: _draftTrip!.currency,
      preferences: _draftTrip!.preferences,
      pace: _draftTrip!.pace,
      interests: _draftTrip!.interests,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      activities: _draftTrip!.activities,
    );

    MockDataService.allTrips.add(newRealTrip);
    _trips.add(newRealTrip);
    _draftTrip = null;
    notifyListeners();
    return true;
  }
}
