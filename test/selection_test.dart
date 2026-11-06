import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsaw_weather/cities.dart';
import 'package:warsaw_weather/main.dart';
import 'package:warsaw_weather/weather.dart';
import 'weather_test.dart' show sampleResponse;
import 'widget_test.dart' show FakeWeatherSource;

class ControlledSource implements WeatherSource {
  final requests = <(WeatherCity, Completer<WeatherReport>)>[];
  @override
  Future<WeatherReport> fetch({WeatherCity city = warsaw}) {
    final result = Completer<WeatherReport>();
    requests.add((city, result));
    return result.future;
  }

  @override
  void close() {}
}

void main() {
  test('16 distinct regional capitals request their own coordinates', () async {
    expect(cities.length, 16);
    expect(cities.map((c) => c.region).toSet().length, 16);
    for (final city in cities) {
      final service = OpenMeteoService(
        client: MockClient((request) async {
          expect(request.url.queryParameters['latitude'], '${city.latitude}');
          expect(request.url.queryParameters['longitude'], '${city.longitude}');
          expect(request.url.queryParameters['forecast_days'], '16');
          return http.Response(jsonEncode(sampleResponse()), 200);
        }),
      );
      await service.fetch(city: city);
      service.close();
    }
  });

  testWidgets(
    'calendar selects a day, cancel preserves it and limits match data',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(WeatherApp(source: FakeWeatherSource()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('date-selector')));
      await tester.pumpAndSettle();
      final calendar = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(calendar.firstDate, DateTime(2026, 11, 6));
      expect(calendar.lastDate, DateTime(2026, 11, 21));
      await tester.tap(find.text('8').last);
      await tester.tap(find.text('Wybierz'));
      await tester.pumpAndSettle();
      expect(find.text('Prognoza na 08.11.2026'), findsOneWidget);
      expect(find.text('POGODA TERAZ'), findsNothing);
      await tester.tap(find.byKey(const Key('date-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(find.text('Prognoza na 08.11.2026'), findsOneWidget);
    },
  );

  testWidgets('city menu changes heading and supports long names on mobile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(WeatherApp(source: FakeWeatherSource()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('city-selector')));
    await tester.pumpAndSettle();
    final option = find.text('Gorzów Wielkopolski — lubuskie');
    await tester.scrollUntilVisible(
      option,
      -150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('city-heading'))).data,
      'Gorzów Wielkopolski',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'late response never overwrites the new city and city error clears old data',
    (tester) async {
      final source = ControlledSource();
      await tester.pumpWidget(WeatherApp(source: source));
      final selector = tester.widget<DropdownButtonFormField<WeatherCity>>(
        find.byKey(const Key('city-selector')),
      );
      selector.onChanged!(cities.first);
      await tester.pump();
      expect(source.requests.last.$1.name, 'Białystok');
      final fresh = sampleResponse();
      (fresh['current'] as Map)['temperature_2m'] = 19;
      source.requests.last.$2.complete(WeatherReport.fromJson(fresh));
      await tester.pumpAndSettle();
      source.requests.first.$2.complete(
        WeatherReport.fromJson(sampleResponse()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('POGODA TERAZ'), 250);
      expect(find.text('19°'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('city-selector')),
        -400,
      );
      tester
          .widget<DropdownButtonFormField<WeatherCity>>(
            find.byKey(const Key('city-selector')),
          )
          .onChanged!(cities[2]);
      await tester.pump();
      source.requests.last.$2.completeError(
        const WeatherException('Brak internetu.'),
      );
      await tester.pumpAndSettle();
      expect(find.text('19°'), findsNothing);
      expect(find.text('Nie możemy sprawdzić pogody'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('city-heading'))).data,
        'Gdańsk',
      );
    },
  );
}
