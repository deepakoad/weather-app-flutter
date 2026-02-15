import 'dart:async';
import 'dart:io'; // For real internet check
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:project_mohali/viewmodels/theme_view_model.dart';
import 'package:project_mohali/viewmodels/weather_view_model.dart';
import 'package:project_mohali/views/widgets/city_search_delegate.dart';
import 'package:project_mohali/views/widgets/forecast_tile.dart';
import 'package:project_mohali/views/widgets/glass_card.dart';
import 'package:project_mohali/views/widgets/tags.dart';
import 'package:project_mohali/views/widgets/weather_icon.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
  }

  /// --- REAL INTERNET CHECK ---
  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  /// --- CONNECTIVITY LISTENER ---
  void _initConnectivityListener() async {
    // Initial check
    await _updateInternetStatus();

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) async {
          await _updateInternetStatus();
        });
  }

  Future<void> _updateInternetStatus() async {
    final results = await Connectivity().checkConnectivity();

    // Connectivity type available?
    final hasConnectionType = results.isNotEmpty && !results.contains(ConnectivityResult.none);

    bool hasInternet = false;
    if (hasConnectionType) {
      hasInternet = await _hasRealInternet();
    }

    if (mounted) {
      if (hasInternet != _isOnline) {
        setState(() => _isOnline = hasInternet);

        if (_isOnline) {
          // Internet back → refresh API
          try {
            await context.read<WeatherViewModel>().init();
          } catch (_) {
            // SocketException ignored
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeatherViewModel>();
    final themeVm = context.watch<ThemeViewModel>();

    final List<Color> gradientColors = themeVm.isDark
        ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
        : [const Color(0xFF4FACFE), const Color(0xFF00F2FE)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _isOnline
          ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          vm.selected?.toString() ?? 'Weather',
          style:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                showSearch(context: context, delegate: CitySearchDelegate()),
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          IconButton(
            onPressed: themeVm.toggle,
            icon: Icon(
              themeVm.isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
          ),
        ],
      )
          : null,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: _isOnline ? _buildBody(context, vm) : _buildNoInternetScreen(),
      ),
    );
  }

  /// --- NO INTERNET UI ---
  Widget _buildNoInternetScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.white70),
              vGap(20),
              const Text(
                'No Connection',
                style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              vGap(10),
              const Text(
                'Please check your internet settings and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              vGap(30),
              ElevatedButton(
                onPressed: _updateInternetStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text('CHECK AGAIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// --- BODY ---
  Widget _buildBody(BuildContext context, WeatherViewModel vm) {
    switch (vm.state) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator(color: Colors.white));

      case ViewState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              vGap(16),
              Text(vm.error ?? 'Something went wrong',
                  style: const TextStyle(color: Colors.white)),
              TextButton(
                onPressed: vm.init,
                child: const Text('Retry',
                    style: TextStyle(
                        color: Colors.white, decoration: TextDecoration.underline)),
              ),
            ],
          ),
        );

      case ViewState.ready:
        final data = vm.data!;
        final cw = data.current;

        return RefreshIndicator(
          onRefresh: vm.refresh,
          displacement: 100,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
            child: Column(
              children: [
                Icon(weatherIcon(cw.weatherCode, cw.isDay),
                    size: 100, color: Colors.white),
                vGap(10),
                Text(
                  '${cw.temperature.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                  ),
                ),
                vGap(30),
                GlassContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoCol(Icons.water_drop, '${cw.humidity ?? 0}%', 'Humidity'),
                      _buildInfoCol(Icons.air, '${cw.windSpeed.toInt()} km/h', 'Wind'),
                      _buildInfoCol(
                          Icons.thermostat, '${cw.feelsLike?.toInt() ?? 0}°', 'Feels Like'),
                    ],
                  ),
                ),
                vGap(20),
                if (vm.quote != null)
                  GlassContainer(
                    child: Column(
                      children: [
                        const Icon(Icons.format_quote, color: Colors.white54),
                        Text(
                          '“${vm.quote!.content}”',
                          textAlign: TextAlign.center,
                          style:
                          const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),
                        Text('- ${vm.quote!.author}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                vGap(30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      '7-Day Forecast',
                      style:
                      TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                vGap(15),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.forecast.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => ForecastTile(day: data.forecast[i]),
                  ),
                ),
                vGap(30),
                Text('Timezone: ${data.timezone}',
                    style: const TextStyle(color: Colors.white54, fontSize: 14)),
                vGap(20),
              ],
            ),
          ),
        );

      case ViewState.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInfoCol(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        vGap(8),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
