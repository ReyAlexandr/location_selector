# location_selector

A standalone, plug-and-play Flutter widget for searching and selecting locations, with built-in GPS support and customizable callbacks.

## Features

- **Search field with debouncing**: Type to search for locations.
- **Customizable callbacks**: Fully control how locations are searched and resolved.
- **GPS Support**: A built-in "Use current location" button that can either use the internal `geolocator` implementation or a custom callback provided by you.
- **No Scaffold**: Just a clean widget that you can embed anywhere in your app.

## Getting started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  location_selector: ^0.0.1
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:location_selector/location_selector.dart';

class MyLocationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LocationSelectorWidget(
          onSearch: (query) async {
            // Fetch suggestions from your API
            return [
              LocationSuggestionItem(id: '1', title: 'New York', subtitle: 'NY, USA'),
            ];
          },
          onResolveSuggestion: (item) async {
            // Resolve the selected suggestion into lat/lng
            return ResolvedLocation(latitude: 40.7128, longitude: -74.0060, title: item.title);
          },
          onResolveGps: (lat, lng) async {
            // Reverse geocode the GPS coordinates
            return ResolvedLocation(latitude: lat, longitude: lng, title: 'Current Location');
          },
          onLocationSelected: (location) {
            print('Selected: ${location.title} at ${location.latitude}, ${location.longitude}');
          },
        ),
      ),
    );
  }
}
```

## Dependencies

This package relies on the following open-source plugins:

- [geolocator](https://pub.dev/packages/geolocator): Used internally to handle GPS permissions and fetch device coordinates seamlessly.

