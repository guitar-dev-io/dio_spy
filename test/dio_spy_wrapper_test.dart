import 'package:net_spy/net_spy.dart';
import 'package:net_spy/src/core/dio_spy_storage.dart';
import 'package:net_spy/src/ui/call_list/call_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetSpy inspectorVisible', () {
    late NetSpy netSpy;

    setUp(() {
      netSpy = NetSpy(showOnShake: false, maxCalls: 100);
    });

    tearDown(() {
      netSpy.dispose();
    });

    test('should be false initially', () {
      expect(netSpy.inspectorVisible.value, isFalse);
    });

    test('show() should set inspectorVisible to true', () {
      netSpy.showInspector();
      expect(netSpy.inspectorVisible.value, isTrue);
    });

    test('hideInspector() should set inspectorVisible to false', () {
      netSpy.showInspector();
      expect(netSpy.inspectorVisible.value, isTrue);

      netSpy.hideInspector();
      expect(netSpy.inspectorVisible.value, isFalse);
    });

    test('show() when already visible should be a no-op (no extra notify)', () {
      var notifyCount = 0;
      netSpy.inspectorVisible.addListener(() => notifyCount++);

      netSpy.showInspector();
      netSpy.showInspector(); // same value — ValueNotifier does not notify

      expect(notifyCount, 1);
    });
  });

  group('NetSpyWrapper', () {
    late NetSpy netSpy;

    setUp(() {
      netSpy = NetSpy(showOnShake: false, maxCalls: 100);
    });

    tearDown(() {
      netSpy.dispose();
    });

    Widget buildTestApp({Widget? home}) {
      return MaterialApp(
        builder: (context, child) => NetSpyWrapper(
          netSpy: netSpy,
          child: child!,
        ),
        home: home ?? const Scaffold(body: Text('App Content')),
      );
    }

    testWidgets('should render child content normally', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets('should not show inspector initially', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.byType(CallListScreen), findsNothing);
    });

    testWidgets('should show inspector when show() is called', (tester) async {
      await tester.pumpWidget(buildTestApp());

      netSpy.showInspector();
      await tester.pumpAndSettle();

      expect(find.byType(CallListScreen), findsOneWidget);
    });

    testWidgets('should show close button in inspector AppBar', (tester) async {
      await tester.pumpWidget(buildTestApp());

      netSpy.showInspector();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should hide inspector when close button is tapped',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      netSpy.showInspector();
      await tester.pumpAndSettle();

      expect(find.byType(CallListScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(CallListScreen), findsNothing);
      expect(find.text('App Content'), findsOneWidget);
      expect(netSpy.inspectorVisible.value, isFalse);
    });

    testWidgets('should hide inspector when hideInspector() is called',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      netSpy.showInspector();
      await tester.pumpAndSettle();
      expect(find.byType(CallListScreen), findsOneWidget);

      netSpy.hideInspector();
      await tester.pumpAndSettle();

      expect(find.byType(CallListScreen), findsNothing);
    });

    testWidgets('should not open inspector twice', (tester) async {
      await tester.pumpWidget(buildTestApp());

      netSpy.showInspector();
      await tester.pumpAndSettle();

      netSpy.showInspector();
      await tester.pumpAndSettle();

      expect(find.byType(CallListScreen), findsOneWidget);
    });

    testWidgets('should allow reopening inspector after closing',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Open
      netSpy.showInspector();
      await tester.pumpAndSettle();
      expect(find.byType(CallListScreen), findsOneWidget);

      // Close
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(CallListScreen), findsNothing);

      // Re-open
      netSpy.showInspector();
      await tester.pumpAndSettle();
      expect(find.byType(CallListScreen), findsOneWidget);
    });

    testWidgets('should work with NetSpyWrapper widget directly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => NetSpyWrapper(
            netSpy: netSpy,
            child: child!,
          ),
          home: const Scaffold(body: Text('Direct Wrapper')),
        ),
      );

      expect(find.text('Direct Wrapper'), findsOneWidget);

      netSpy.showInspector();
      await tester.pumpAndSettle();

      expect(find.byType(CallListScreen), findsOneWidget);
    });
  });

  group('CallListScreen onClose', () {
    testWidgets('should not show close button when onClose is null',
        (tester) async {
      final storage = NetSpyStorage(maxCalls: 100);

      await tester.pumpWidget(
        MaterialApp(
          home: CallListScreen(storage: storage),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('should show close button when onClose is provided',
        (tester) async {
      final storage = NetSpyStorage(maxCalls: 100);
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CallListScreen(
            storage: storage,
            onBack: () => closed = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });
  });
}
