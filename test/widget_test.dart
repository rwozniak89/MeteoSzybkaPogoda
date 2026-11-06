import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warsaw_weather/main.dart';
import 'package:warsaw_weather/weather.dart';

import 'weather_test.dart' show sampleResponse;

class FakeWeatherSource implements WeatherSource {
  int requests = 0;
  bool fail = false;
  @override
  Future<WeatherReport> fetch() async {
    requests++;
    if (fail) throw const WeatherException('Brak połączenia z internetem.');
    return WeatherReport.fromJson(sampleResponse());
  }

  @override
  void close() {}
}

class PendingSource implements WeatherSource {
  final completer = Completer<WeatherReport>();
  int requests = 0;
  @override
  Future<WeatherReport> fetch() {
    requests++;
    return completer.future;
  }

  @override
  void close() {}
}

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('forecast fits a $width px screen', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(WeatherApp(source: FakeWeatherSource()));
      await tester.pumpAndSettle();
      expect(find.text('Warszawa'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Najbliższe 7 dni'), 250);
      expect(find.text('Najbliższe 7 dni'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Dane: Open-Meteo · CC BY 4.0 ↗'),
        400,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('initial error can be retried successfully', (tester) async {
    final source = FakeWeatherSource()..fail = true;
    await tester.pumpWidget(WeatherApp(source: source));
    await tester.pumpAndSettle();
    expect(find.text('Nie możemy sprawdzić pogody'), findsOneWidget);
    source.fail = false;
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.pumpAndSettle();
    expect(find.text('TERAZ W STOLICY'), findsOneWidget);
    expect(source.requests, 2);
  });

  testWidgets('refresh failure preserves weather and labels old data', (
    tester,
  ) async {
    final source = FakeWeatherSource();
    await tester.pumpWidget(WeatherApp(source: source));
    await tester.pumpAndSettle();
    source.fail = true;
    await tester.tap(find.byTooltip('Odśwież pogodę'));
    await tester.pumpAndSettle();
    expect(find.text('Nie udało się odświeżyć prognozy'), findsOneWidget);
    expect(find.textContaining('mogą być nieaktualne'), findsOneWidget);
    expect(find.text('TERAZ W STOLICY'), findsOneWidget);
  });

  testWidgets('loading disables duplicate fetch and disposal is safe', (
    tester,
  ) async {
    final source = PendingSource();
    await tester.pumpWidget(WeatherApp(source: source));
    expect(find.text('Pobieramy pogodę dla Warszawy…'), findsOneWidget);
    await tester.tap(find.byTooltip('Odśwież pogodę'));
    expect(source.requests, 1);
    await tester.pumpWidget(const SizedBox());
    source.completer.complete(WeatherReport.fromJson(sampleResponse()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
