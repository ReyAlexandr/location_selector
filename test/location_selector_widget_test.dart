import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_selector/location_selector.dart';

void main() {
  Widget buildSelector({
    required FutureOr<void> Function(ResolvedLocation location)
    onLocationSelected,
    void Function(String message)? onError,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: LocationSelectorWidget(
          onSearch: (query) async => const [
            LocationSuggestionItem(
              id: 'location-1',
              title: 'Example Place',
              subtitle: 'Example Region',
            ),
          ],
          onResolveSuggestion: (item) async =>
              ResolvedLocation(latitude: 10, longitude: 20, title: item.title),
          onResolveGps: (latitude, longitude) async => ResolvedLocation(
            latitude: latitude,
            longitude: longitude,
            title: 'GPS location',
          ),
          onLocationSelected: onLocationSelected,
          onError: onError,
        ),
      ),
    );
  }

  Future<void> searchAndSelect(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'Exam');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.tap(find.text('Example Place'));
    await tester.pump();
  }

  testWidgets('stays busy until an asynchronous selection callback completes', (
    tester,
  ) async {
    final selectionCompleter = Completer<void>();

    await tester.pumpWidget(
      buildSelector(onLocationSelected: (_) => selectionCompleter.future),
    );

    await searchAndSelect(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    selectionCompleter.complete();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('reports errors from an asynchronous selection callback', (
    tester,
  ) async {
    String? reportedError;

    await tester.pumpWidget(
      buildSelector(
        onLocationSelected: (_) async {
          throw StateError('Selection processing failed');
        },
        onError: (message) => reportedError = message,
      ),
    );

    await searchAndSelect(tester);
    await tester.pump();

    expect(reportedError, 'Could not select this location. Try again.');
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });
}
