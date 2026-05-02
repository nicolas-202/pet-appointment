import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_appointment/config/theme.dart';
import 'package:pet_appointment/screens/authenticated_home_screen.dart';

void main() {
  testWidgets('AuthenticatedHomeScreen muestra saludo con el primer nombre',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthenticatedHomeScreen(name: 'Juan Pérez'),
      ),
    );

    expect(find.textContaining('Juan'), findsOneWidget);
    expect(find.text('Pet Sanctuary'), findsOneWidget);
  });

  testWidgets('AuthenticatedHomeScreen muestra badge En construcción',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthenticatedHomeScreen(name: 'Ana'),
      ),
    );

    expect(find.text('En construcción'), findsOneWidget);
    expect(find.byIcon(Icons.construction_rounded), findsOneWidget);
  });

  testWidgets('AppLogoTitle muestra ícono y nombre de la app',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Icon(Icons.pets, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Pet Sanctuary',
                style: TextStyle(
                  fontFamily: AppFonts.primary,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.pets), findsOneWidget);
    expect(find.text('Pet Sanctuary'), findsOneWidget);
  });
}
