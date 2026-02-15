import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather.dart';
import 'weather_icon.dart';

class ForecastTile extends StatelessWidget {
  final ForecastDay day;
  const ForecastTile({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE');
    return Card(
      elevation: 0.5,
      child: SizedBox(
        width: 110,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(df.format(day.date), style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Icon(weatherIcon(day.weatherCode, true), size: 28),
              const SizedBox(height: 8),
              Text('${day.max.toStringAsFixed(0)}° / ${day.min.toStringAsFixed(0)}°'),
            ],
          ),
        ),
      ),
    );
  }
}

