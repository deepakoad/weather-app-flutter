import '../models/location.dart';
import '../models/weather.dart';
import '../services/api_client.dart';

class WeatherRepository {
  final ApiClient api;
  WeatherRepository(this.api);

  Future<List<LocationModel>> searchCity(String query) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '5',
      'language': 'en',
      'format': 'json',
    });
    final json = await api.getJson(uri);
    final results = (json['results'] as List<dynamic>? ?? [])
        .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return results;
  }

  Future<LocationModel?> reverseGeocode(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
          '?lat=$lat'
          '&lon=$lon'
          '&format=json'
          '&zoom=10'
          '&addressdetails=1',
    );

    final json = await api.getJson(uri);

    final address = json['address'] as Map<String, dynamic>?;

    if (address == null) return null;

    final city = address['city'] ??
        address['town'] ??
        address['village'] ??
        address['state'] ??
        'Current Location';

    return LocationModel(
      name: city.toString(),
      latitude: lat,
      longitude: lon,
    );
  }


  // Future<LocationModel?> reverseGeocode(double lat, double lon) async {
  //   final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/reverse', {
  //     'latitude': '$lat',
  //     'longitude': '$lon',
  //     'count': '1',
  //     'language': 'en',
  //     'format': 'json',
  //   });
  //
  //   final json = await api.getJson(uri);
  //
  //   final results = (json['results'] as List<dynamic>? ?? []);
  //   if (results.isEmpty) return null;
  //
  //   return LocationModel.fromJson(
  //       results.first as Map<String, dynamic>);
  // }


  Future<WeatherBundle> getWeather(double lat, double lon) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lon',
      'current_weather': 'true',
      'hourly': 'relative_humidity_2m,apparent_temperature',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      'timezone': 'auto',
    });

    final json = await api.getJson(uri);
    final cw = json['current_weather'];
    if (cw == null) {
      throw Exception("Weather data not available");
    }
    final currentTime = (cw['time'] ?? cw['date']) as String;
    final isDay = (cw['is_day'] as num?)?.toInt() == 1;
    final temp = (cw['temperature'] ?? cw['temperature_2m']) as num;
    final wind = (cw['windspeed'] ?? cw['wind_speed_10m'] ?? cw['wind_speed']) as num;
    final wcode = (cw['weather_code'] ?? cw['weathercode']) as num;
    final current = CurrentWeather(
      temperature: temp.toDouble(),
      windSpeed: wind.toDouble(),
      weatherCode: wcode.toInt(),
      isDay: isDay,
    );

    final hourly = json['hourly'] as Map<String, dynamic>? ?? {};
    final times = (hourly['time'] as List<dynamic>? ?? []).cast<String>();
    final idx = times.indexOf(currentTime);
    int? humidity;
    double? feelsLike;
    if (idx != -1) {
      final hum = (hourly['relative_humidity_2m'] as List<dynamic>? ?? []);
      final app = (hourly['apparent_temperature'] as List<dynamic>? ?? []);
      if (idx < hum.length) humidity = (hum[idx] as num?)?.toInt();
      if (idx < app.length) feelsLike = (app[idx] as num?)?.toDouble();
    }

    final currentWithExtras = CurrentWeather(
      temperature: current.temperature,
      windSpeed: current.windSpeed,
      weatherCode: current.weatherCode,
      isDay: current.isDay,
      humidity: humidity,
      feelsLike: feelsLike,
    );

    final daily = json['daily'] as Map<String, dynamic>;
    final dates = (daily['time'] as List<dynamic>).cast<String>();
    final maxs = (daily['temperature_2m_max'] as List<dynamic>).cast<num>();
    final mins = (daily['temperature_2m_min'] as List<dynamic>).cast<num>();
    final rawCodes =
        (daily['weather_code'] ?? daily['weathercode']) as List<dynamic>;
    final codes = rawCodes.cast<num>();

    final forecast = <ForecastDay>[];
    for (var i = 0; i < dates.length && i < 5; i++) {
      forecast.add(
        ForecastDay(
          date: DateTime.parse(dates[i]),
          max: maxs[i].toDouble(),
          min: mins[i].toDouble(),
          weatherCode: codes[i].toInt(),
        ),
      );
    }

    return WeatherBundle(
      timezone: (json['timezone'] ?? 'auto').toString(),
      current: currentWithExtras,
      forecast: forecast,
    );
  }
}
