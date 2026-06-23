class RouteModel {
  final String id;
  final String name;
  final List<String> stops;
  final String startTime;
  final String endTime;
  final bool isActive;
  final int frequency;

  const RouteModel({
    required this.id,
    required this.name,
    required this.stops,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.frequency,
  });

  static List<RouteModel> mockRoutes() => [
        const RouteModel(
          id: 'route_001',
          name: 'Main Campus Loop',
          stops: ['Brunei Hall', 'KSB', 'Unity Hall', 'JCRC', 'Main Gate'],
          startTime: '6:00 AM',
          endTime: '10:00 PM',
          isActive: true,
          frequency: 15,
        ),
        const RouteModel(
          id: 'route_002',
          name: 'Tech Junction Express',
          stops: ['Tech Junction', 'Faculty of Engineering', 'Republic Hall', 'Pent Hall'],
          startTime: '7:00 AM',
          endTime: '8:00 PM',
          isActive: true,
          frequency: 20,
        ),
        const RouteModel(
          id: 'route_003',
          name: 'University Hospital Route',
          stops: ['Main Gate', 'University Hospital', 'Staff Village', 'Chancellor Hall'],
          startTime: '8:00 AM',
          endTime: '6:00 PM',
          isActive: false,
          frequency: 30,
        ),
      ];
}
