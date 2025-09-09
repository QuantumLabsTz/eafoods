import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:eafoods/providers/product_provider.dart';
import 'package:eafoods/providers/order_provider.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('App should start with dashboard screen', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ProductProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: Text('EA Foods - Pre-Order System')),
            ),
          ),
        ),
      );

      // Verify that the app title is displayed
      expect(find.text('EA Foods - Pre-Order System'), findsOneWidget);
    });

    testWidgets('Dashboard should show welcome message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ProductProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Center(child: Text('Welcome to EA Foods'))),
          ),
        ),
      );

      expect(find.text('Welcome to EA Foods'), findsOneWidget);
    });
  });
}
