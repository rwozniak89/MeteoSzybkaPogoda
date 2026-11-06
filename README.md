# Pogoda w Warszawie

Prosta aplikacja **Dart + Flutter Web**, po polsku, z bieżącą pogodą i prognozą na 7 dni. Układ dopasowuje się do komputera i telefonu.

## Uruchomienie

Wymagany Flutter w kanale stable (Dart >= 3.8). Z katalogu `warsaw_weather`:

```powershell
flutter pub get
flutter run -d chrome
```

W tym środowisku Flutter został pobrany lokalnie do `C:\Projects\Codex\.tools\flutter`. Można użyć przygotowanego skryptu:

```powershell
.\start.ps1
```

Skrypt uruchamia serwer pod adresem http://localhost:8080. Otwórz adres w przeglądarce. Zakończenie: Ctrl+C. Można wybrać inny port: `.\start.ps1 -Port 8090`.

## Funkcje

- Aktualna temperatura, temperatura odczuwalna, wilgotność i wiatr.
- Prognoza na 7 dni: temperatury maksymalna i minimalna, opis pogody, najwyższe dzienne prawdopodobieństwo opadów i maksymalny wiatr.
- Dzisiejsza prognozowana suma opadów (cały dzień, nie pomiar bieżący).
- Ręczne odświeżanie, wskaźnik pobierania i ponowienie po błędzie.
- Zachowanie ostatnio pobranych danych podczas nieudanego odświeżania z ostrzeżeniem, że mogą być nieaktualne. Dane nie są zapisywane pomiędzy uruchomieniami.
- Obsługa brakujących pomiarów symbolem „—”.
- Stała lokalizacja Warszawy, bez pytania o dostęp do lokalizacji użytkownika.

## Źródło danych

[Open-Meteo](https://open-meteo.com/) to projekt [open source](https://github.com/open-meteo/open-meteo). Publiczny endpoint nie wymaga klucza i jest bezpłatny **do użytku niekomercyjnego**, zgodnie z [warunkami](https://open-meteo.com/en/terms). Dane są udostępniane na licencji [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); aplikacja zawiera podpis źródła. Komercyjne użycie hostowanego API wymaga odpowiedniego planu. Limity bezpłatnego API: poniżej 10 000 zapytań/dzień, 5 000/godzinę i 600/minutę.

Endpoint: `https://api.open-meteo.com/v1/forecast`. Współrzędne: `52.2297, 21.0122`. Parametry zapytania są w `lib/weather.dart`. [Dokumentacja](https://open-meteo.com/en/docs).

Czas pochodzi z API i jest czasem lokalnym Warszawy (`Europe/Warsaw`), niezależnie od strefy urządzenia. Temperatura: °C, wiatr: km/h, opady: mm. „Dane na” wskazuje czas danych bieżących, nie czas wykonania zapytania. Bieżące wartości Open-Meteo są danymi modelowymi. Aplikacja pobiera dane przy otwarciu i po kliknięciu odświeżania; nie odpytuje API w tle. Wymaga połączenia z internetem, bez backendu i konta.

## Weryfikacja i kompilacja

```powershell
flutter analyze
flutter test
flutter build web --release
```

Wynik produkcyjny jest w `build/web`. Udostępnij zawartość przez serwer HTTP/HTTPS; otwieranie samego pliku `index.html` z dysku nie uruchomi aplikacji poprawnie. Publikowanie w podkatalogu wymaga `flutter build web --base-href /nazwa/`.

Testy sprawdzają odczyt danych, błędy API i sieci, brakujące pomiary, kody pogody, ponawianie, zachowanie danych przy awarii odświeżania, blokowanie jednoczesnych zapytań oraz układ przy szerokościach 320, 390, 768 i 1440 px. Testy używają danych przykładowych i nie odpytują API.

## Struktura

- `lib/main.dart` — interfejs i stan ekranu.
- `lib/weather.dart` — modele, komunikacja z API, opisy kodów WMO.
- `test/` — testy logiki i interfejsu.
- `web/index.html` — strona startowa Flutter Web.

Projekt zawiera platformę web. Dodanie Androida wymaga wygenerowania plików platformy (`flutter create --platforms=android .`), zainstalowania Android SDK i dodania uprawnienia `android.permission.INTERNET` w głównym manifeście aplikacji.
