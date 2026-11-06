class WeatherCity {
  final String name, region;
  final double latitude, longitude;
  const WeatherCity(this.name, this.region, this.latitude, this.longitude);
}

const warsaw = WeatherCity('Warszawa', 'mazowieckie', 52.2297, 21.0122);

// One city per voivodeship: the seat of the voivode.
const cities = [
  WeatherCity('Białystok', 'podlaskie', 53.1325, 23.1688),
  WeatherCity('Bydgoszcz', 'kujawsko-pomorskie', 53.1235, 18.0084),
  WeatherCity('Gdańsk', 'pomorskie', 54.3520, 18.6466),
  WeatherCity('Gorzów Wielkopolski', 'lubuskie', 52.7368, 15.2288),
  WeatherCity('Katowice', 'śląskie', 50.2649, 19.0238),
  WeatherCity('Kielce', 'świętokrzyskie', 50.8661, 20.6286),
  WeatherCity('Kraków', 'małopolskie', 50.0647, 19.9450),
  WeatherCity('Lublin', 'lubelskie', 51.2465, 22.5684),
  WeatherCity('Łódź', 'łódzkie', 51.7592, 19.4560),
  WeatherCity('Olsztyn', 'warmińsko-mazurskie', 53.7784, 20.4801),
  WeatherCity('Opole', 'opolskie', 50.6751, 17.9213),
  WeatherCity('Poznań', 'wielkopolskie', 52.4064, 16.9252),
  WeatherCity('Rzeszów', 'podkarpackie', 50.0412, 21.9991),
  WeatherCity('Szczecin', 'zachodniopomorskie', 53.4285, 14.5528),
  warsaw,
  WeatherCity('Wrocław', 'dolnośląskie', 51.1079, 17.0385),
];
