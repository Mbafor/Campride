import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/firebase_config.dart';
import '../theme/app_theme.dart';

class LocationSearchResult {
  final String name;
  final double latitude;
  final double longitude;

  LocationSearchResult({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class SearchLocationPicker extends StatefulWidget {
  final String title;
  final String hint;
  final LocationSearchResult? initialLocation;

  const SearchLocationPicker({
    super.key,
    required this.title,
    this.hint = 'Search for a location...',
    this.initialLocation,
  });

  @override
  State<SearchLocationPicker> createState() => _SearchLocationPickerState();
}

class _SearchLocationPickerState extends State<SearchLocationPicker> {
  late TextEditingController _searchController;
  List<PlacePrediction> _predictions = [];
  LocationSearchResult? _selectedLocation;
  bool _isLoadingPredictions = false;
  bool _isLoadingDetails = false;
  Timer? _debounceTimer;
  GoogleMapController? _mapController;
  String? _error;

  static const String _googleApiKey = FirebaseConfig.googleMapsApiKey;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedLocation = widget.initialLocation;
    if (widget.initialLocation != null) {
      _searchController.text = widget.initialLocation!.name;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    setState(() {
      _isLoadingPredictions = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _googleApiKey,
        },
        body: jsonEncode({'input': input, 'languageCode': 'en'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final suggestions = data['suggestions'] as List<dynamic>? ?? [];

        setState(() {
          _predictions = suggestions
              .map((s) => PlacePrediction.fromJson(s as Map<String, dynamic>))
              .toList();
        });
      } else {
        setState(() => _error = 'Failed to fetch suggestions');
      }
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoadingPredictions = false);
    }
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    setState(() => _isLoadingDetails = true);

    try {
      final response = await http.get(
        Uri.parse('https://places.googleapis.com/v1/places/${prediction.placeId}'),
        headers: {
          'X-Goog-Api-Key': _googleApiKey,
          'X-Goog-FieldMask': 'displayName,location',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName =
            data['displayName']['text'] ?? prediction.description;
        final location = data['location'] as Map<String, dynamic>?;

        if (location != null) {
          final latitude = location['latitude'] as double?;
          final longitude = location['longitude'] as double?;

          if (latitude != null && longitude != null) {
            setState(() {
              _selectedLocation = LocationSearchResult(
                name: displayName,
                latitude: latitude,
                longitude: longitude,
              );
              _searchController.text = displayName;
              _predictions = [];
            });

            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: LatLng(latitude, longitude), zoom: 16),
              ),
            );
            return;
          }
        }
      }
      setState(() => _error = 'Could not get location details');
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoadingDetails = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(value);
    });
  }

  void _confirm() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: context.fieldFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.fieldBorder),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: context.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: context.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: context.textSecondary,
                      ),
                      suffixIcon: _isLoadingPredictions
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_predictions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: context.textSecondary,
                    ),
                    title: Text(
                      prediction.mainText,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      prediction.secondaryText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                    onTap: () => _selectPrediction(prediction),
                  );
                },
              ),
            )
          else if (_selectedLocation == null &&
              _predictions.isEmpty &&
              _searchController.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No results found',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: context.textSecondary,
                  ),
                ),
              ),
            )
          else if (_selectedLocation == null && _searchController.text.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Search for a location',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ),
          if (_selectedLocation != null)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _selectedLocation!.latitude,
                          _selectedLocation!.longitude,
                        ),
                        zoom: 16,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      markers: {
                        Marker(
                          markerId: const MarkerId('selected_location'),
                          position: LatLng(
                            _selectedLocation!.latitude,
                            _selectedLocation!.longitude,
                          ),
                          infoWindow: InfoWindow(
                            title: _selectedLocation!.name,
                          ),
                        ),
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.fieldFill,
                      border: Border(
                        top: BorderSide(color: context.fieldBorder),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Selected Location',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedLocation!.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: _selectedLocation != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoadingDetails ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoadingDetails
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Confirm Location',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            )
          : null,
    );
  }
}

class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;

  PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final placePrediction =
        json['placePrediction'] as Map<String, dynamic>? ?? {};
    final structuredFormat =
        placePrediction['structuredFormat'] as Map<String, dynamic>? ?? {};
    final mainText = structuredFormat['mainText'] as Map<String, dynamic>?;
    final secondaryText =
        structuredFormat['secondaryText'] as Map<String, dynamic>?;

    final mainTextStr = mainText?['text'] as String? ?? '';
    final secondaryTextStr = secondaryText?['text'] as String? ?? '';

    return PlacePrediction(
      placeId: placePrediction['placeId'] ?? '',
      mainText: mainTextStr,
      secondaryText: secondaryTextStr,
      description: '$mainTextStr $secondaryTextStr'.trim(),
    );
  }
}
