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

class Destination {
  final String id;
  final String name;
  final String country;
  final String imageUrl;
  final String description;
  final double rating;

  Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.imageUrl,
    required this.description,
    required this.rating,
  });
}

class Flight {
  final String id;
  final String airline;
  final String from;
  final String to;
  final DateTime departure;
  final DateTime arrival;
  final double price;

  Flight({
    required this.id,
    required this.airline,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    required this.price,
  });
}

class Trip {
  final String id;
  final String userId; // Associated with a specific user
  final Destination destination;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> activities;

  Trip({
    required this.id,
    required this.userId,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.activities = const [],
  });
}
