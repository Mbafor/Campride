import '../models/shuttle_model.dart';

class MockShuttleService {
  Future<List<ShuttleModel>> getShuttles() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return ShuttleModel.mockShuttles();
  }

  Future<List<ShuttleModel>> getActiveShuttles() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return ShuttleModel.mockShuttles().where((s) => s.isOnRoute).toList();
  }

  Future<ShuttleModel?> getShuttleById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final shuttles = ShuttleModel.mockShuttles();
    try {
      return shuttles.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> startTrip(String shuttleId, String routeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> endTrip(String shuttleId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
