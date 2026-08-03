import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// A campus stop, flattened from a route for use in search/selection UIs.
class StopInfo {
  final String id;
  final String name;
  final String routeName;
  final double lat;
  final double lng;

  const StopInfo({
    required this.id,
    required this.name,
    required this.routeName,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'routeName': routeName,
        'lat': lat,
        'lng': lng,
      };

  factory StopInfo.fromJson(Map<String, dynamic> json) => StopInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        routeName: json['routeName'] as String? ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}

/// Fetches the full set of stops across all routes.
///
/// Backend contract (Backend/app/schemas/route.py StopResponse):
/// stops are keyed by `lat`/`lng`, not `latitude`/`longitude`.
class StopsRepository {
  Future<List<StopInfo>> fetchAllStops(String accessToken) async {
    final routesResponse = await http.get(
      Uri.parse('${ApiConfig.baseHttpUrl}/routes'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(const Duration(seconds: 10));

    if (routesResponse.statusCode != 200) {
      throw Exception('Failed to load routes (${routesResponse.statusCode})');
    }

    final routes = jsonDecode(routesResponse.body) as List;
    final stops = <StopInfo>[];

    for (final route in routes) {
      final routeId = route['id'];
      final routeName = route['name'] as String? ?? 'Unknown route';

      final stopsResponse = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/routes/$routeId/stops'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));

      if (stopsResponse.statusCode != 200) continue;

      final stopsJson = jsonDecode(stopsResponse.body) as List;
      for (final stop in stopsJson) {
        final lat = stop['lat'];
        final lng = stop['lng'];
        if (lat == null || lng == null) continue;
        stops.add(StopInfo(
          id: stop['id'] as String,
          name: stop['name'] as String? ?? 'Unknown stop',
          routeName: routeName,
          lat: (lat as num).toDouble(),
          lng: (lng as num).toDouble(),
        ));
      }
    }

    return stops;
  }
}
