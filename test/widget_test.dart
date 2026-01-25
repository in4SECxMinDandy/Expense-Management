// SpendWise Widget Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_manager/main.dart';

void main() {
  testWidgets('SpendWise app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SpendWiseApp());

    // Verify that the app loads with bottom navigation
    expect(
      find.byType(BottomNavigationBar).evaluate().isNotEmpty ||
          find.byType(NavigationBar).evaluate().isNotEmpty ||
          find.text('Tổng quan').evaluate().isNotEmpty,
      true,
    );
  });
}
