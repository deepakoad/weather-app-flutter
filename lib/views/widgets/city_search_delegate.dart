import 'package:flutter/material.dart';
import 'package:project_mohali/models/location.dart';
import 'package:project_mohali/viewmodels/weather_view_model.dart';
import 'package:provider/provider.dart';

class CitySearchDelegate extends SearchDelegate<LocationModel?> {
  @override
  String get searchFieldLabel => 'Search City...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF2C5364)),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white60),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  Widget _buildResults(BuildContext context) {
    final vm = context.read<WeatherViewModel>();
    if (query.trim().isEmpty) return const Center(child: Text('Enter a city name'));

    return FutureBuilder(
      future: vm.searchCities(query),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final cities = snap.data ?? <LocationModel>[];
        if (cities.isEmpty) return const Center(child: Text('No cities found.'));
        return ListView.builder(
          itemCount: cities.length,
          itemBuilder: (_, i) {
            final c = cities[i];
            return ListTile(
              title: Text(c.toString()),
              onTap: () async {
                await vm.selectCity(c);
                if (context.mounted) close(context, c);
              },
            );
          },
        );
      },
    );
  }
}