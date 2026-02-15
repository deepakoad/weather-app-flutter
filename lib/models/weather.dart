class CurrentWeather {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final int? humidity;
  final double? feelsLike;
  final bool isDay;

  CurrentWeather({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
    this.humidity,
    this.feelsLike,
  });
}

class ForecastDay {
  final DateTime date;
  final double min;
  final double max;
  final int weatherCode;

  ForecastDay({
    required this.date,
    required this.min,
    required this.max,
    required this.weatherCode,
  });
}

class WeatherBundle {
  final String timezone;
  final CurrentWeather current;
  final List<ForecastDay> forecast;

  WeatherBundle({required this.timezone, required this.current, required this.forecast});
}

