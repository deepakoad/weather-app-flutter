class LocationModel {
  final String name;
  final String? country;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
  });

  factory LocationModel.fromJson(Map<String, dynamic> j) => LocationModel(
        name: j['name'] ?? '',
        country: j['country'],
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
      );

  @override
  String toString() => country == null ? name : '$name, $country';
}

