import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_models.dart';

class GpsLocationButton extends StatefulWidget {
  const GpsLocationButton({
    super.key,
    required this.onResolveGps,
    this.onGetCurrentLocation,
    this.onError,
    this.enabled = true,
  });

  final Future<ResolvedLocation> Function(double latitude, double longitude)
  onResolveGps;
  final Future<({double latitude, double longitude})?> Function()?
  onGetCurrentLocation;
  final void Function(String errorMessage)? onError;
  final bool enabled;

  @override
  State<GpsLocationButton> createState() => _GpsLocationButtonState();
}

class _GpsLocationButtonState extends State<GpsLocationButton> {
  bool _isLoading = false;

  Future<void> _useCurrentLocation() async {
    if (_isLoading || !widget.enabled) return;
    setState(() => _isLoading = true);

    try {
      double lat;
      double lng;

      if (widget.onGetCurrentLocation != null) {
        final location = await widget.onGetCurrentLocation!();
        if (location == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        lat = location.latitude;
        lng = location.longitude;
      } else {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          await Geolocator.openLocationSettings();
          _showError('Turn on location services, then try again.');
          return;
        }

        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
          _showError('Allow location permission in settings, then try again.');
          return;
        }

        if (permission == LocationPermission.denied) {
          _showError('Location permission was denied.');
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
      }

      await widget.onResolveGps(lat, lng);
    } catch (error) {
      _showError('Could not get your current location. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (widget.onError != null) {
      widget.onError!(message);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: widget.enabled && !_isLoading ? _useCurrentLocation : null,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      label: Text(
        _isLoading ? 'Finding your location...' : 'Use current location',
      ),
    );
  }
}
