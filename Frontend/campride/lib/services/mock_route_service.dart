import '../models/route_model.dart';

class MockRouteService {
  Future<List<RouteModel>> getRoutes() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return RouteModel.mockRoutes();
  }

  Future<List<RouteModel>> searchRoutes(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final routes = RouteModel.mockRoutes();
    if (query.isEmpty) return routes;
    return routes.where((r) =>
      r.name.toLowerCase().contains(query.toLowerCase()) ||
      r.stops.any((s) => s.toLowerCase().contains(query.toLowerCase()))
    ).toList();
  }

  Future<RouteModel?> getRouteById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final routes = RouteModel.mockRoutes();
    try {
      return routes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
