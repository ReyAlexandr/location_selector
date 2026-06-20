class LocationSuggestionItem {
  final String id;
  final String title;
  final String subtitle;
  final dynamic data;

  const LocationSuggestionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.data,
  });
}

class ResolvedLocation {
  final double latitude;
  final double longitude;
  final String title;
  final dynamic data;

  const ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.title,
    this.data,
  });
}
