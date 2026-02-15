import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/location.dart';
import '../models/quote.dart';
import '../models/weather.dart';
import '../repositories/quote_repository.dart';
import '../repositories/weather_repository.dart';
import '../services/api_client.dart';

enum ViewState { idle, loading, ready, error }

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepository _weatherRepo = WeatherRepository(ApiClient());
  final QuoteRepository _quoteRepo = QuoteRepository(ApiClient());

  ViewState state = ViewState.idle;
  String? error;
  LocationModel? selected;
  WeatherBundle? data;
  Quote? quote;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    state = ViewState.loading;
    notifyListeners();

    try {
      await _loadWeather();

      state = ViewState.ready;
      notifyListeners();

      try {
        quote = await _quoteRepo.randomQuote();
        notifyListeners();
      } catch (e) {
        print("Quote failed but ignoring → $e");
      }

    } catch (e, stack) {
      print("VIEWMODEL ERROR → $e");
      print(stack);
      error = e.toString();
      state = ViewState.error;
      notifyListeners();
    }
  }



  Future<void> refresh() async {
    if (selected == null) return;
    state = ViewState.loading;
    notifyListeners();
    try {
      data = await _weatherRepo.getWeather(
        selected!.latitude,
        selected!.longitude,
      );
      state = ViewState.ready;
      notifyListeners();
      try {
        quote = await _quoteRepo.randomQuote();
        notifyListeners();
      } catch (e, stack) {
        print("VIEWMODEL ERROR → $e");
        print(stack);
        error = e.toString();
        state = ViewState.error;
      }
    } catch (e) {
      print("Quote failed but ignoring → $e");
    }
    notifyListeners();
  }

  Future<List<LocationModel>> searchCities(String q) => _weatherRepo.searchCity(q);

  Future<void> selectCity(LocationModel loc) async {
    selected = loc;
    await refresh();
  }

  Future<Position?> _getPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return null;
      }
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        ).timeout(const Duration(seconds: 3));
        return pos;
      } on TimeoutException {
        return await Geolocator.getLastKnownPosition();
      }
    }catch (e, stack) {
      print("VIEWMODEL ERROR → $e");
      print(stack);
      error = e.toString();
      state = ViewState.error;
    }
    return null;
  }

  Future<void> _loadWeather() async {
    final pos = await _getPosition();

    if (pos != null) {
      selected =
          await _weatherRepo.reverseGeocode(pos.latitude, pos.longitude) ??
              LocationModel(
                name: 'Current Location',
                latitude: pos.latitude,
                longitude: pos.longitude,
              );
    } else {
      selected = LocationModel(
        name: 'Rohtak',
        latitude: 30.7046,
        longitude: 76.7179,
      );
    }

    data = await _weatherRepo.getWeather(
      selected!.latitude,
      selected!.longitude,
    );
  }

}
