import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://campride-production.up.railway.app/api/v1';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
  });
}

class DriverRoute {
  final String id;
  final String name;
  final String startName;
  final String endName;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

  DriverRoute({
    required this.id,
    required this.name,
    required this.startName,
    required this.endName,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
  });

  factory DriverRoute.fromJson(Map<String, dynamic> json) {
    return DriverRoute(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      startName: json['start_name'] ?? '',
      endName: json['end_name'] ?? '',
      startLat: (json['start_location']?['coordinates']?[1] ?? 0.0).toDouble(),
      startLng: (json['start_location']?['coordinates']?[0] ?? 0.0).toDouble(),
      endLat: (json['end_location']?['coordinates']?[1] ?? 0.0).toDouble(),
      endLng: (json['end_location']?['coordinates']?[0] ?? 0.0).toDouble(),
    );
  }
}

class Stop {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int order;

  Stop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.order,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      lat: (json['location']?['coordinates']?[1] ?? 0.0).toDouble(),
      lng: (json['location']?['coordinates']?[0] ?? 0.0).toDouble(),
      order: json['order'] ?? 0,
    );
  }
}

class ShuttleInfo {
  final String id;
  final String name;
  final String plateNumber;
  final int capacity;
  final String status;
  final String? assignedDriverId;
  final String? assignedDriverName;

  ShuttleInfo({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.capacity,
    required this.status,
    this.assignedDriverId,
    this.assignedDriverName,
  });

  factory ShuttleInfo.fromJson(Map<String, dynamic> json) {
    final driver = json['assigned_driver'];
    return ShuttleInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      capacity: json['capacity'] ?? 0,
      status: json['status'] ?? 'idle',
      assignedDriverId: driver?['id'],
      assignedDriverName: driver?['name'],
    );
  }
}

class DriverInfo {
  final String id;
  final String name;
  final String email;
  final bool isActive;
  final String? assignedShuttleId;
  final String? assignedShuttleName;
  final String? assignedRouteId;
  final String? assignedRouteName;

  DriverInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    this.assignedShuttleId,
    this.assignedShuttleName,
    this.assignedRouteId,
    this.assignedRouteName,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    final shuttle = json['assigned_shuttle'];
    final route = json['assigned_route'];
    return DriverInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isActive: json['is_active'] ?? false,
      assignedShuttleId: shuttle?['id'],
      assignedShuttleName: shuttle?['name'],
      assignedRouteId: route?['id'],
      assignedRouteName: route?['name'],
    );
  }
}

class ShuttleService {
  // DRIVER ENDPOINTS
  /// Get the driver's currently assigned/active route
  Future<ApiResponse<DriverRoute?>> getDriverRoute({
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/route'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json == null) {
          return ApiResponse(success: true, data: null, message: 'No route assigned');
        }
        return ApiResponse(success: true, data: DriverRoute.fromJson(json));
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to get driver route (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Update the driver's route selection
  /// TODO: Backend API gap - no public endpoint to list available routes.
  /// Drivers need a way to discover which routes they can select from.
  /// Workaround: For now, use /admin/routes endpoint or request full list from backend.
  Future<ApiResponse<DriverRoute>> updateDriverRoute({
    required String accessToken,
    required String routeId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/driver/route'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'route_id': routeId}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final route = DriverRoute.fromJson(json['route']);
        return ApiResponse(success: true, data: route);
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to update route (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Get stops for a specific route
  Future<ApiResponse<List<Stop>>> getRouteStops({
    required String accessToken,
    required String routeId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/routes/$routeId/stops'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        final stops = json.map((s) => Stop.fromJson(s)).toList();
        return ApiResponse(success: true, data: stops);
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to get route stops (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Get the driver's currently assigned shuttle
  Future<ApiResponse<ShuttleInfo?>> getDriverShuttle({
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/shuttle'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse(success: true, data: ShuttleInfo.fromJson(json));
      } else if (response.statusCode == 404) {
        return ApiResponse(success: true, data: null, message: 'No shuttle assigned');
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to get driver shuttle (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  // FLEET MANAGER ENDPOINTS
  /// List all drivers with their shuttle and route assignments
  Future<ApiResponse<List<DriverInfo>>> listDrivers({
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fleet/drivers'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        final drivers = json.map((d) => DriverInfo.fromJson(d)).toList();
        return ApiResponse(success: true, data: drivers);
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to list drivers (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Get a specific driver's details
  Future<ApiResponse<DriverInfo>> getDriver({
    required String accessToken,
    required String driverId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fleet/drivers/$driverId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse(success: true, data: DriverInfo.fromJson(json));
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to get driver details (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// List all shuttles with driver assignments
  Future<ApiResponse<List<ShuttleInfo>>> listShuttles({
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fleet/shuttles'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        final shuttles = json.map((s) => ShuttleInfo.fromJson(s)).toList();
        return ApiResponse(success: true, data: shuttles);
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to list shuttles (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  // ADMIN ENDPOINTS
  /// List all shuttles (admin view)
  Future<ApiResponse<List<ShuttleInfo>>> adminListShuttles({
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/shuttles'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        final shuttles = json.map((s) => ShuttleInfo.fromJson(s)).toList();
        return ApiResponse(success: true, data: shuttles);
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to list shuttles (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Get a specific shuttle (admin)
  Future<ApiResponse<ShuttleInfo>> adminGetShuttle({
    required String accessToken,
    required String shuttleId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/shuttles/$shuttleId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse(success: true, data: ShuttleInfo.fromJson(json));
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to get shuttle (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Create a new shuttle
  Future<ApiResponse<ShuttleInfo>> createShuttle({
    required String accessToken,
    required String name,
    required String plateNumber,
    required int capacity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/shuttles'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'plate_number': plateNumber,
          'capacity': capacity,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse(success: true, data: ShuttleInfo.fromJson(json));
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to create shuttle (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Update an existing shuttle
  Future<ApiResponse<ShuttleInfo>> updateShuttle({
    required String accessToken,
    required String shuttleId,
    String? name,
    String? plateNumber,
    int? capacity,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (plateNumber != null) body['plate_number'] = plateNumber;
      if (capacity != null) body['capacity'] = capacity;
      if (status != null) body['status'] = status;

      final response = await http.put(
        Uri.parse('$baseUrl/admin/shuttles/$shuttleId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse(success: true, data: ShuttleInfo.fromJson(json));
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to update shuttle (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Delete a shuttle
  Future<ApiResponse<void>> deleteShuttle({
    required String accessToken,
    required String shuttleId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/shuttles/$shuttleId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true);
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to delete shuttle (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Assign a driver to a shuttle
  Future<ApiResponse<ShuttleInfo>> assignDriverToShuttle({
    required String accessToken,
    required String shuttleId,
    required String driverId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/shuttles/$shuttleId/assign-driver'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'driver_id': driverId}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse(success: true, data: ShuttleInfo.fromJson(json['shuttle']));
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to assign driver (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// List all shuttles (student/public view)
  Future<ApiResponse<List<ShuttleInfo>>> getPublicShuttles({
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shuttles'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        final shuttles = json.map((s) => ShuttleInfo.fromJson(s)).toList();
        return ApiResponse(success: true, data: shuttles);
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to get shuttles (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// List all routes (ADMIN - currently the only way to list routes)
  /// TODO: Backend gap - no public endpoint to list available routes for drivers
  Future<ApiResponse<List<DriverRoute>>> listRoutes({
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/routes'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        final routes = json.map((r) => DriverRoute.fromJson(r)).toList();
        return ApiResponse(success: true, data: routes);
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to list routes (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Create a new route (admin)
  Future<ApiResponse<DriverRoute>> createRoute({
    required String accessToken,
    required String name,
    required String startName,
    required String endName,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/routes'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'start_name': startName,
          'end_name': endName,
          'start_lat': startLat,
          'start_lng': startLng,
          'end_lat': endLat,
          'end_lng': endLng,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse(success: true, data: DriverRoute.fromJson(json));
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to create route (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Update an existing route
  Future<ApiResponse<DriverRoute>> updateRoute({
    required String accessToken,
    required String routeId,
    required String name,
    required String startName,
    required String endName,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/routes/$routeId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'start_name': startName,
          'end_name': endName,
          'start_lat': startLat,
          'start_lng': startLng,
          'end_lat': endLat,
          'end_lng': endLng,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse(success: true, data: DriverRoute.fromJson(json));
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to update route (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Delete a route
  Future<ApiResponse<void>> deleteRoute({
    required String accessToken,
    required String routeId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/routes/$routeId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true);
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to delete route (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Add a stop to a route
  Future<ApiResponse<Stop>> addRouteStop({
    required String accessToken,
    required String routeId,
    required String name,
    required double lat,
    required double lng,
    required int order,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/routes/$routeId/stops'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'lat': lat,
          'lng': lng,
          'order': order,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse(success: true, data: Stop.fromJson(json));
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to add stop (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Delete a stop
  Future<ApiResponse<void>> deleteStop({
    required String accessToken,
    required String stopId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/stops/$stopId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true);
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to delete stop (${response.statusCode})',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  // FLEET MANAGER ADMIN ENDPOINTS
  /// Create a new driver
  Future<ApiResponse<DriverInfo>> createDriver({
    required String name,
    required String email,
    required String password,
    required String accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/users/driver'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': 'driver',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return ApiResponse(success: true, data: DriverInfo.fromJson(json));
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['detail']?['message'] ?? 'Failed to create driver';
        return ApiResponse(success: false, message: message);
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }
}
