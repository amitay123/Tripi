import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';

class BookingProvider extends ChangeNotifier {
  User? _currentUser;
  Destination? _selectedDestination;
  Flight? _selectedFlight;
  String? _selectedSeat;
  int _extraBaggageCount = 0;

  User? get currentUser => _currentUser;
  Destination? get selectedDestination => _selectedDestination;
  Flight? get selectedFlight => _selectedFlight;
  String? get selectedSeat => _selectedSeat;
  int get extraBaggageCount => _extraBaggageCount;

  String? login(String email, String password) {
    // Check for hardcoded admin
    if (email == 'admin@tripi.com' && password == 'admin') {
      _currentUser = User(id: 'admin', email: 'admin@tripi.com', name: 'System Admin');
      notifyListeners();
      return '/admin';
    }

    try {
      final user = MockDataService.users.firstWhere((u) => u.email == email);
      _currentUser = user;
      notifyListeners();
      return '/explore';
    } catch (e) {
      return null;
    }
  }

  bool register(String name, String email) {
    if (email == 'admin@tripi.com') return false; // Prevent admin registration

    final newUser = User(
      id: 'u${MockDataService.users.length + 1}',
      email: email,
      name: name,
    );
    MockDataService.users.add(newUser);
    _currentUser = newUser;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    clearBooking();
    notifyListeners();
  }

  void selectDestination(Destination destination) {
    _selectedDestination = destination;
    notifyListeners();
  }

  void selectFlight(Flight flight) {
    _selectedFlight = flight;
    notifyListeners();
  }

  void selectSeat(String seat) {
    _selectedSeat = seat;
    notifyListeners();
  }

  void updateBaggage(int count) {
    _extraBaggageCount = count;
    notifyListeners();
  }

  void clearBooking() {
    _selectedDestination = null;
    _selectedFlight = null;
    _selectedSeat = null;
    _extraBaggageCount = 0;
    notifyListeners();
  }

  void addMockTrip() {
    if (_currentUser == null) return;

    final randomDest = MockDataService.destinations[
        DateTime.now().millisecondsSinceEpoch % MockDataService.destinations.length];
    
    final newTrip = Trip(
      id: 't${MockDataService.allTrips.length + 1}',
      userId: _currentUser!.id,
      name: '${randomDest.name} Getaway',
      country: randomDest.country,
      destination: randomDest,
      startDate: DateTime.now().add(const Duration(days: 14)),
      endDate: DateTime.now().add(const Duration(days: 21)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    MockDataService.allTrips.add(newTrip);
    notifyListeners();
  }

  List<Trip> get userTrips {
    if (_currentUser == null) return [];
    return MockDataService.allTrips.where((trip) => trip.userId == _currentUser!.id).toList();
  }
}
