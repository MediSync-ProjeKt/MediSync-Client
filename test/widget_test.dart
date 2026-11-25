import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisync_flutter/main.dart';

void main() {
  testWidgets('MediSync auth screen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MediSyncApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Auth screen should be shown first (not logged in)
    expect(find.text('MediSync'), findsWidgets);
    // Role toggle link present
    expect(find.textContaining('Are you a doctor?'), findsOneWidget);
    // Sign in button for patient
    expect(find.textContaining('Sign In to Patient Portal'), findsOneWidget);
    // Privacy badge
    expect(find.textContaining('End-to-End'), findsOneWidget);
  });
}
