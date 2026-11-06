import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsaw_weather/weather.dart';

Map<String, dynamic> sampleResponse() => {
  'current': <String, dynamic>{
    'time': '2026-11-06T12:15',
    'temperature_2m': 8.3,
    'apparent_temperature': 5.1,
    'relative_humidity_2m': 80,
    'wind_speed_10m': 14.2,
    'weather_code': 3,
    'is_day': 1,
  },
  'daily': <String, dynamic>{
    'time': List.generate(
      7,
      (i) => '2026-11-${(6 + i).toString().padLeft(2, '0')}',
    ),
    'temperature_2m_min': [2, 3, 1, -1, 0, 4, 5],
    'temperature_2m_max': [8, 9, 7, 6, 7, 10, 11],
    'precipitation_probability_max': [20, 80, 0, 10, 30, 60, 15],
    'precipitation_sum': [0.2, 4, 0, 0, 0.6, 2, 0],
    'wind_speed_10m_max': [14, 18, 12, 10, 11, 20, 15],
    'weather_code': [3, 61, 0, 1, 2, 80, 3],
  },
};

void main() {
  test('reads forecast, units and Warsaw local time from API', () async {
    final source = OpenMeteoService(
      client: MockClient((request) async {
        expect(request.url.host, 'api.open-meteo.com');
        expect(request.url.queryParameters['timezone'], 'Europe/Warsaw');
        expect(request.url.queryParameters['forecast_days'], '7');
        expect(request.url.queryParameters['latitude'], '52.2297');
        expect(request.url.queryParameters['wind_speed_unit'], 'kmh');
        return http.Response(jsonEncode(sampleResponse()), 200);
      }),
    );
    addTearDown(source.close);
    final report = await source.fetch();
    expect(report.temperature, 8.3);
    expect(report.time.hour, 12);
    expect(report.days.length, 7);
    expect(report.days[3].low, -1);
    expect(report.days[1].rainChance, 80);
  });

  test('missing optional measurements stay missing, never become zero', () {
    final json = sampleResponse();
    (json['current'] as Map)['wind_speed_10m'] = null;
    (json['daily'] as Map)['precipitation_probability_max'] = [null];
    final report = WeatherReport.fromJson(json);
    expect(report.wind, isNull);
    expect(report.days.first.rainChance, isNull);
    expect(report.days.last.rainChance, isNull);
    expect(number(null), '—');
  });

  for (final status in [429, 500]) {
    test('HTTP $status yields a readable error', () async {
      final source = OpenMeteoService(
        client: MockClient((_) async => http.Response('', status)),
      );
      addTearDown(source.close);
      await expectLater(source.fetch(), throwsA(isA<WeatherException>()));
    });
  }

  test('network failure yields a readable error', () async {
    final source = OpenMeteoService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    addTearDown(source.close);
    await expectLater(
      source.fetch(),
      throwsA(
        isA<WeatherException>().having(
          (e) => e.message,
          'message',
          contains('internet'),
        ),
      ),
    );
  });

  test('invalid JSON and empty forecasts yield readable errors', () async {
    for (final body in ['not json', '{"current":{},"daily":{"time":[]}}']) {
      final source = OpenMeteoService(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(source.close);
      await expectLater(source.fetch(), throwsA(isA<WeatherException>()));
    }
  });

  test(
    'WMO codes cover ice, snow and thunderstorms; unknown code is explicit',
    () {
      expect(weatherDescription(67), 'Marznący deszcz');
      expect(weatherDescription(86), 'Przelotny śnieg');
      expect(weatherDescription(99), 'Burza z gradem');
      expect(weatherDescription(null), 'Brak opisu pogody');
    },
  );
}
