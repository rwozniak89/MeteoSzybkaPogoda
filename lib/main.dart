import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'weather.dart';

void main() => runApp(const WeatherApp());

const ink = Color(0xFF203B36);
const paper = Color(0xFFF6F7F2);
const muted = Color(0xFF64756E);
const accent = Color(0xFFE4F3A2);

class WeatherApp extends StatelessWidget {
  final WeatherSource? source;
  const WeatherApp({super.key, this.source});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Warszawa • Pogoda',
    debugShowCheckedModeBanner: false,
    locale: const Locale('pl'),
    supportedLocales: const [Locale('pl')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: ink, surface: paper),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
    ),
    home: WeatherPage(source: source),
  );
}

class WeatherPage extends StatefulWidget {
  final WeatherSource? source;
  const WeatherPage({super.key, this.source});
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late final WeatherSource _source;
  WeatherReport? _report;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _source = widget.source ?? OpenMeteoService();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await _source.fetch();
      if (mounted) setState(() => _report = report);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is WeatherException
              ? error.message
              : 'Nie udało się pobrać pogody. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    if (widget.source == null) _source.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      body: SafeArea(
        child: SelectionArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1140),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width < 600 ? 20 : 48,
                  vertical: 32,
                ),
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 26),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'POGODA / WARSZAWA',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Odśwież pogodę',
                        onPressed: _loading ? null : _load,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 38),
                  const Text(
                    'Dobry dzień zaczyna się\nod dobrej prognozy.',
                    style: TextStyle(fontSize: 14, color: muted, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Warszawa',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Polska  /  52,23° N, 21,01° E',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 28),
                  if (_loading) ...[
                    const LinearProgressIndicator(
                      minHeight: 3,
                      semanticsLabel: 'Pobieranie prognozy',
                    ),
                    const SizedBox(height: 16),
                    if (report == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Text('Pobieramy pogodę dla Warszawy…'),
                        ),
                      ),
                  ],
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEADB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report == null
                                ? 'Nie możemy sprawdzić pogody'
                                : 'Nie udało się odświeżyć prognozy',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_error!),
                          if (report != null)
                            const Text(
                              'Poniżej ostatnio pobrane dane — mogą być nieaktualne.',
                            ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Spróbuj ponownie'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (report != null) ...[
                    _CurrentWeather(report: report),
                    const SizedBox(height: 36),
                    const Text(
                      'Najbliższe 7 dni',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Twój tydzień, dzień po dniu.',
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 850
                            ? 7
                            : constraints.maxWidth >= 550
                            ? 4
                            : constraints.maxWidth >= 340
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (var i = 0; i < report.days.length; i++)
                              SizedBox(
                                width: width,
                                child: _DayCard(day: report.days[i], index: i),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: muted),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Temperatury: maksimum i minimum dnia. Procent oznacza najwyższe prawdopodobieństwo opadów w danym dniu.',
                            style: TextStyle(
                              fontSize: 12,
                              color: muted,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 36),
                  const Divider(color: Color(0xFFDBE1D6)),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      const Text(
                        'Czas lokalny Warszawy • °C • km/h',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                      TextButton(
                        onPressed: () async {
                          final opened = await launchUrl(
                            Uri.parse('https://open-meteo.com/'),
                          );
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Źródło danych: https://open-meteo.com/',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Dane: Open-Meteo · CC BY 4.0 ↗',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentWeather extends StatelessWidget {
  final WeatherReport report;
  const _CurrentWeather({required this.report});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(28),
    ),
    child: DefaultTextStyle(
      style: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final overview = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TERAZ W STOLICY',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                children: [
                  Text(
                    '${number(report.temperature)}°',
                    style: const TextStyle(
                      fontSize: 86,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -5,
                      height: 1.1,
                    ),
                  ),
                  Icon(
                    weatherIcon(report.code, isDay: report.isDay),
                    size: 64,
                    color: accent,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                weatherDescription(report.code),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Dane na ${shortDate(report.time)}, ${report.time.hour.toString().padLeft(2, '0')}:${report.time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Color(0xFFBACCC4), fontSize: 12),
              ),
            ],
          );
          final metrics = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                icon: Icons.thermostat,
                label: 'Odczuwalna',
                value: '${number(report.feelsLike)} °C',
              ),
              _Metric(
                icon: Icons.air,
                label: 'Wiatr',
                value: '${number(report.wind)} km/h',
              ),
              _Metric(
                icon: Icons.water_drop_outlined,
                label: 'Wilgotność',
                value: '${number(report.humidity)}%',
              ),
              _Metric(
                icon: Icons.umbrella_outlined,
                label: 'Opady dziś',
                value: '${number(report.days.first.rain, decimals: 1)} mm',
              ),
            ],
          );
          if (constraints.maxWidth >= 650) {
            return Row(
              children: [
                Expanded(child: overview),
                const SizedBox(width: 24),
                SizedBox(width: 312, child: metrics),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [overview, const SizedBox(height: 28), metrics],
          );
        },
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Metric({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF2F4A43),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(height: 14),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 21),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFBACCC4), fontSize: 12),
        ),
      ],
    ),
  );
}

class _DayCard extends StatelessWidget {
  final ForecastDay day;
  final int index;
  const _DayCard({required this.day, required this.index});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
    decoration: BoxDecoration(
      color: index == 0 ? accent : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: index == 0 ? accent : const Color(0xFFE3E8DF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          index == 0
              ? 'Dzisiaj'
              : index == 1
              ? 'Jutro'
              : weekdays[day.date.weekday - 1],
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 5),
        Text(
          shortDate(day.date),
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 22),
        Icon(
          weatherIcon(day.code),
          size: 32,
          color: ink,
          semanticLabel: weatherDescription(day.code),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${number(day.high)}°',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
            ),
            Text(
              '${number(day.low)}°',
              style: const TextStyle(fontSize: 17, color: muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: Text(
            weatherDescription(day.code),
            style: const TextStyle(fontSize: 12, color: muted, height: 1.4),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.water_drop_outlined, size: 14),
            const SizedBox(width: 5),
            Text(
              '${number(day.rainChance)}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.air, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '${number(day.wind)} km/h',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

IconData weatherIcon(int? code, {bool isDay = true}) => switch (code) {
  0 || 1 => isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
  2 => Icons.cloud_queue,
  3 => Icons.cloud_outlined,
  45 || 48 => Icons.foggy,
  51 ||
  53 ||
  55 ||
  56 ||
  57 ||
  61 ||
  63 ||
  65 ||
  66 ||
  67 ||
  80 ||
  81 ||
  82 => Icons.grain,
  71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit,
  95 || 96 || 99 => Icons.thunderstorm_outlined,
  _ => Icons.help_outline,
};
