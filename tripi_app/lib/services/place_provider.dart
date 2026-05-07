import '../models/place_result.dart';

abstract class PlaceProvider {
  Future<List<PlaceResult>> searchNearby({
    required double lat,
    required double lng,
    String? type,
    String? keyword,
    int radius = 5000,
    int maxResults = 20,
  });

  Future<PlaceResult?> getPlaceDetails(String placeId);
}
