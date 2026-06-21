import 'dart:async';
import 'package:flutter/material.dart';
import '../models/location_models.dart';
import 'gps_button.dart';

class LocationSelectorWidget extends StatefulWidget {
  const LocationSelectorWidget({
    super.key,
    required this.onSearch,
    required this.onResolveSuggestion,
    required this.onResolveGps,
    required this.onLocationSelected,
    this.onGetCurrentLocation,
    this.onError,
    this.initialQuery,
    this.enabled = true,
  });

  final Future<List<LocationSuggestionItem>> Function(String query) onSearch;
  final Future<ResolvedLocation> Function(LocationSuggestionItem item)
  onResolveSuggestion;
  final Future<ResolvedLocation> Function(double latitude, double longitude)
  onResolveGps;

  /// Called after a suggestion or GPS location has been resolved.
  ///
  /// The selector stays in its resolving state until the returned future
  /// completes, allowing consumers to perform asynchronous work such as
  /// validation, persistence, or navigation without re-enabling the UI early.
  final FutureOr<void> Function(ResolvedLocation location) onLocationSelected;
  final Future<({double latitude, double longitude})?> Function()?
  onGetCurrentLocation;
  final void Function(String errorMessage)? onError;
  final String? initialQuery;
  final bool enabled;

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  static const _minimumQueryLength = 3;
  static const _searchDelay = Duration(milliseconds: 300);

  late final TextEditingController _controller;
  Timer? _searchTimer;
  List<LocationSuggestionItem> _suggestions = const [];
  String? _errorMessage;
  bool _isLoading = false;
  bool _isResolving = false;
  LocationSuggestionItem? _resolvingSuggestion;
  int _requestRevision = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);

    if (_controller.text.trim().length >= _minimumQueryLength) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleSearch(_controller.text);
      });
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSearch(String rawQuery) {
    _searchTimer?.cancel();
    final requestRevision = ++_requestRevision;
    final query = rawQuery.trim();

    setState(() {
      _suggestions = const [];
      _errorMessage = null;
      _isLoading = false;
    });

    if (query.length < _minimumQueryLength) {
      return;
    }

    _searchTimer = Timer(_searchDelay, () => _search(query, requestRevision));
  }

  Future<void> _search(String query, int requestRevision) async {
    if (!mounted || requestRevision != _requestRevision) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final suggestions = await widget.onSearch(query);
      if (!mounted || requestRevision != _requestRevision) return;

      setState(() => _suggestions = suggestions);
    } catch (error) {
      if (!mounted || requestRevision != _requestRevision) return;

      setState(() {
        _suggestions = const [];
        _errorMessage = 'Could not load location suggestions. Try again.';
      });
    } finally {
      if (mounted && requestRevision == _requestRevision) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectSuggestion(LocationSuggestionItem suggestion) async {
    if (_isResolving) return;
    setState(() {
      _isResolving = true;
      _resolvingSuggestion = suggestion;
    });

    try {
      final resolved = await widget.onResolveSuggestion(suggestion);
      await widget.onLocationSelected(resolved);
    } catch (error) {
      if (!mounted) return;
      if (widget.onError != null) {
        widget.onError!('Could not select this location. Try again.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not select this location. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
          _resolvingSuggestion = null;
        });
      }
    }
  }

  Future<ResolvedLocation> _handleResolveGps(double lat, double lng) async {
    if (_isResolving) throw Exception('Already resolving');
    setState(() {
      _isResolving = true;
    });

    try {
      final resolved = await widget.onResolveGps(lat, lng);
      await widget.onLocationSelected(resolved);
      return resolved;
    } catch (error) {
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: widget.enabled && !_isResolving,
          autofocus: true,
          maxLength: 96,
          onChanged: _scheduleSearch,
          decoration: InputDecoration(
            labelText: 'Search location',
            hintText: 'Type an area, city, or address',
            border: const OutlineInputBorder(),
            counterText: '',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: widget.enabled && !_isResolving
                        ? () {
                            _controller.clear();
                            _scheduleSearch('');
                          }
                        : null,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        GpsLocationButton(
          enabled: widget.enabled && !_isResolving,
          onResolveGps: _handleResolveGps,
          onGetCurrentLocation: widget.onGetCurrentLocation,
          onError: widget.onError,
        ),
        const SizedBox(height: 12),
        if (query.length < _minimumQueryLength)
          const Text('Type at least 3 characters to search.'),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (!_isLoading &&
            !_isResolving &&
            _errorMessage == null &&
            query.length >= _minimumQueryLength &&
            _suggestions.isEmpty)
          const Text('No matching locations found.'),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: _suggestions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];

              return ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(suggestion.title),
                subtitle: Text(suggestion.subtitle),
                trailing: _resolvingSuggestion == suggestion
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: widget.enabled && !_isResolving
                    ? () => _selectSuggestion(suggestion)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
