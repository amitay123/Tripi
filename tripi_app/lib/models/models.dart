class User {
  final String id;
  final String email;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.name,
  });
}

class Activity {
  final String time;
  final String title;
  final String description;
  final String? travelMode;
  final String? travelTime;

  Activity({
    required this.time,
    required this.title,
    required this.description,
    this.travelMode,
    this.travelTime,
  });
}

class DayItinerary {
  final int dayNumber;
  final List<Activity> activities;

  DayItinerary({
    required this.dayNumber,
    required this.activities,
  });
}

class Itinerary {
  final String title;
  final String location;
  final String imageUrl;
  final List<DayItinerary> days;

  Itinerary({
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.days,
  });
}
