import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:campride/providers/authentication_provider.dart';
import 'package:campride/screens/driver/map/driver_map_screen.dart';

void main() {
  testWidgets('DriverMapScreen shows a connection error instead of crashing when unauthenticated',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthenticationProvider(),
        child: const MaterialApp(
          home: Scaffold(body: DriverMapScreen()),
        ),
      ),
    );
    await tester.pump();

    // No access token is set (no login performed), so DriverMapScreen should
    // surface its own error state rather than throwing or rendering a blank
    // screen — proves _connect()'s early-return guard and error UI work.
    expect(find.text('Connection Error'), findsOneWidget);
    expect(find.text('Authentication token not found'), findsOneWidget);
    expect(find.text('Retry Connection'), findsOneWidget);

    // Tapping retry should re-run _connect() without throwing.
    await tester.tap(find.text('Retry Connection'));
    await tester.pump();
    expect(find.text('Connection Error'), findsOneWidget);
  });
}
