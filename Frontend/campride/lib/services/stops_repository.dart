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

  StopInfo copyWith({String? routeName}) => StopInfo(
    id: id,
    name: name,
    routeName: routeName ?? this.routeName,
    lat: lat,
    lng: lng,
  );
}

/// Built-in fallback set of campus stops. Used whenever the live backend
/// returns no routes/stops or is unreachable, so the search bar always has
/// suggestions to show while the user types.
///
/// Coordinates are illustrative KNUST-area lat/lng pairs.
const List<StopInfo> kFallbackStops = [
  StopInfo(
    id: 'fb-001',
    name: 'Brunei Hall',
    routeName: 'Main Campus Loop',
    lat: 6.6870,
    lng: -1.5710,
  ),
  StopInfo(
    id: 'fb-002',
    name: 'KSB',
    routeName: 'Main Campus Loop',
    lat: 6.6880,
    lng: -1.5720,
  ),
  StopInfo(
    id: 'fb-003',
    name: 'Unity Hall',
    routeName: 'Main Campus Loop',
    lat: 6.6890,
    lng: -1.5730,
  ),
  StopInfo(
    id: 'fb-004',
    name: 'JCRC',
    routeName: 'Main Campus Loop',
    lat: 6.6900,
    lng: -1.5740,
  ),
  StopInfo(
    id: 'fb-005',
    name: 'Main Gate',
    routeName: 'Main Campus Loop',
    lat: 6.6910,
    lng: -1.5750,
  ),
  StopInfo(
    id: 'fb-006',
    name: 'Tech Junction',
    routeName: 'Tech Junction Express',
    lat: 6.6920,
    lng: -1.5760,
  ),
  StopInfo(
    id: 'fb-007',
    name: 'Faculty of Engineering',
    routeName: 'Tech Junction Express',
    lat: 6.6930,
    lng: -1.5770,
  ),
  StopInfo(
    id: 'fb-008',
    name: 'Republic Hall',
    routeName: 'Tech Junction Express',
    lat: 6.6940,
    lng: -1.5780,
  ),
  StopInfo(
    id: 'fb-009',
    name: 'Pent Hall',
    routeName: 'Tech Junction Express',
    lat: 6.6950,
    lng: -1.5790,
  ),
  StopInfo(
    id: 'fb-010',
    name: 'University Hospital',
    routeName: 'University Hospital Route',
    lat: 6.6960,
    lng: -1.5800,
  ),
  StopInfo(
    id: 'fb-011',
    name: 'Staff Village',
    routeName: 'University Hospital Route',
    lat: 6.6970,
    lng: -1.5810,
  ),
  StopInfo(
    id: 'fb-012',
    name: 'Chancellor Hall',
    routeName: 'University Hospital Route',
    lat: 6.6980,
    lng: -1.5820,
  ),
];

/// Fetches the full set of stops across all routes.
///
/// Backend contract (Backend/app/schemas/route.py StopResponse):
/// stops are keyed by `lat`/`lng`, not `latitude`/`longitude`.
class StopsRepository {
  /// Fetches all stops across all routes. Requests are performed in parallel
  /// for speed. If the backend returns no stops or is unreachable, falls back
  /// to [kFallbackStops] so the search UI always has suggestions to show.
  Future<List<StopInfo>> fetchAllStops(String accessToken) async {
    try {
      final routesResponse = await http
          .get(
            Uri.parse('${ApiConfig.baseHttpUrl}/routes'),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 10));

      if (routesResponse.statusCode != 200) {
        return kFallbackStops;
      }

      final routes = jsonDecode(routesResponse.body) as List;
      if (routes.isEmpty) return kFallbackStops;

      // Fetch stops for every route in parallel.
      final results = await Future.wait(
        routes.map<Future<List<StopInfo>>>((route) async {
          final routeId = route['id'];
          final routeName = route['name'] as String? ?? 'Unknown route';
          try {
            final stopsResponse = await http
                .get(
                  Uri.parse('${ApiConfig.baseHttpUrl}/routes/$routeId/stops'),
                  headers: {'Authorization': 'Bearer $accessToken'},
                )
                .timeout(const Duration(seconds: 10));

            if (stopsResponse.statusCode != 200) return <StopInfo>[];

            final stopsJson = jsonDecode(stopsResponse.body) as List;
            final stops = <StopInfo>[];
            for (final stop in stopsJson) {
              final lat = stop['lat'];
              final lng = stop['lng'];
              if (lat == null || lng == null) continue;
              stops.add(
                StopInfo(
                  id: stop['id'] as String,
                  name: stop['name'] as String? ?? 'Unknown stop',
                  routeName: routeName,
                  lat: (lat as num).toDouble(),
                  lng: (lng as num).toDouble(),
                ),
              );
            }
            return stops;
          } catch (_) {
            // Skip a single route's stops on failure; keep the rest.
            return <StopInfo>[];
          }
        }),
      );

      final stops = results.expand((s) => s).toList();
      return stops.isNotEmpty ? stops : kFallbackStops;
    } catch (_) {
      // Backend unreachable or errored — still provide searchable stops.
      return kFallbackStops;
    }
  }
}
