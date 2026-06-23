class ShuttleModel {
  final String id;
  final String plateNumber;
  final String driverName;
  final String currentLocation;
  final String nextStop;
  final int minutesAway;
  final int capacity;
  final int occupancy;
  final bool isOnRoute;

  const ShuttleModel({
    required this.id,
    required this.plateNumber,
    required this.driverName,
    required this.currentLocation,
    required this.nextStop,
    required this.minutesAway,
    required this.capacity,
    required this.occupancy,
    required this.isOnRoute,
  });

  double get occupancyRate => occupancy / capacity;

  static List<ShuttleModel> mockShuttles() => [
        const ShuttleModel(
          id: 'shuttle_001',
          plateNumber: 'GR 1234-20',
          driverName: 'Kofi Asante',
          currentLocation: 'KSB',
          nextStop: 'Unity Hall',
          minutesAway: 3,
          capacity: 32,
          occupancy: 18,
          isOnRoute: true,
        ),
        const ShuttleModel(
          id: 'shuttle_002',
          plateNumber: 'GR 5678-21',
          driverName: 'Ama Owusu',
          currentLocation: 'Main Gate',
          nextStop: 'Brunei Hall',
          minutesAway: 7,
          capacity: 32,
          occupancy: 28,
          isOnRoute: true,
        ),
        const ShuttleModel(
          id: 'shuttle_003',
          plateNumber: 'GR 9012-19',
          driverName: 'Yaw Boateng',
          currentLocation: 'Republic Hall',
          nextStop: 'Tech Junction',
          minutesAway: 12,
          capacity: 28,
          occupancy: 5,
          isOnRoute: false,
        ),
      ];
}
