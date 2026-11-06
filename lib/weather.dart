import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Times from this endpoint are wall-clock times in Europe/Warsaw.
/// Keep them as local-looking values: do not convert them to the device zone.
class WeatherReport {
  final DateTime time;
  final double temperature;
  final double? feelsLike;
  final double? humidity;
  final double? wind;
  final int? code;
  final bool isDay;
  final List<ForecastDay> days;

  const WeatherReport({
    required this.time,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.code,
    required this.isDay,
    required this.days,
  });

  factory WeatherReport.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    final dates = daily['time'] as List<dynamic>;
    if (dates.isEmpty) throw const FormatException('Empty forecast');
    double? value(String key, int i) {
      final values = daily[key];
      if (values is! List || i >= values.length) return null;
      return (values[i] as num?)?.toDouble();
    }

    return WeatherReport(
      time: DateTime.parse(current['time'] as String),
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num?)?.toDouble(),
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble(),
      wind: (current['wind_speed_10m'] as num?)?.toDouble(),
      code: (current['weather_code'] as num?)?.toInt(),
      isDay: current['is_day'] != 0,
      days: List.generate(
        dates.length,
        (i) => ForecastDay(
          date: DateTime.parse(dates[i] as String),
          low: value('temperature_2m_min', i),
          high: value('temperature_2m_max', i),
          rainChance: value('precipitation_probability_max', i),
          rain: value('precipitation_sum', i),
          wind: value('wind_speed_10m_max', i),
          code: value('weather_code', i)?.toInt(),
        ),
      ),
    );
  }
}

class ForecastDay {
  final DateTime date;
  final double? low, high, rainChance, rain, wind;
  final int? code;

  const ForecastDay({
    required this.date,
    required this.low,
    required this.high,
    required this.rainChance,
    required this.rain,
    required this.wind,
    required this.code,
  });
}

class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);
  @override
  String toString() => message;
}

abstract interface class WeatherSource {
  Future<WeatherReport> fetch();
  void close();
}

class OpenMeteoService implements WeatherSource {
  final http.Client _client;
  OpenMeteoService({http.Client? client}) : _client = client ?? http.Client();

  static final endpoint = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '52.2297',
    'longitude': '21.0122',
    'current':
        'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m',
    'daily':
        'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum,wind_speed_10m_max',
    'timezone': 'Europe/Warsaw',
    'forecast_days': '7',
    'temperature_unit': 'celsius',
    'wind_speed_unit': 'kmh',
    'precipitation_unit': 'mm',
  });

  @override
  Future<WeatherReport> fetch() async {
    try {
      final response = await _client
          .get(endpoint)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 429) {
        throw const WeatherException(
          'Źródło pogody jest teraz obciążone. Spróbuj ponownie za chwilę.',
        );
      }
      if (response.statusCode != 200) {
        throw const WeatherException(
          'Serwis pogodowy jest chwilowo niedostępny. Spróbuj ponownie.',
        );
      }
      return WeatherReport.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on WeatherException {
      rethrow;
    } on TimeoutException {
      throw const WeatherException(
        'Pobieranie trwa zbyt długo. Sprawdź połączenie i spróbuj ponownie.',
      );
    } on http.ClientException {
      throw const WeatherException(
        'Nie udało się połączyć. Sprawdź dostęp do internetu i spróbuj ponownie.',
      );
    } catch (_) {
      throw const WeatherException(
        'Nie udało się odczytać danych pogodowych. Spróbuj ponownie później.',
      );
    }
  }

  @override
  void close() => _client.close();
}

String weatherDescription(int? code) => switch (code) {
  0 => 'Bezchmurnie',
  1 => 'Przeważnie słonecznie',
  2 => 'Częściowe zachmurzenie',
  3 => 'Pochmurno',
  45 || 48 => 'Mgła',
  51 || 53 || 55 => 'Mżawka',
  56 || 57 => 'Marznąca mżawka',
  61 => 'Słaby deszcz',
  63 => 'Deszcz',
  65 => 'Silny deszcz',
  66 || 67 => 'Marznący deszcz',
  71 || 73 || 75 || 77 => 'Śnieg',
  80 || 81 || 82 => 'Przelotny deszcz',
  85 || 86 => 'Przelotny śnieg',
  95 => 'Burza',
  96 || 99 => 'Burza z gradem',
  _ => 'Brak opisu pogody',
};

String number(double? value, {int decimals = 0}) =>
    value == null ? '—' : value.toStringAsFixed(decimals).replaceAll('.', ',');

const weekdays = [
  'poniedziałek',
  'wtorek',
  'środa',
  'czwartek',
  'piątek',
  'sobota',
  'niedziela',
];
String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
