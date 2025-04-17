import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/full_width_button.dart';
import '../../../auth/screens/widgets/section_title.dart';
import '../../controllers/event_controller.dart';
import '../../screens/widgets/create_venue_appbar.dart';

class ChooseEventLocation extends ConsumerStatefulWidget {
  final String eventId;

  const ChooseEventLocation({super.key, required this.eventId});

  @override
  ConsumerState<ChooseEventLocation> createState() =>
      _ChooseEventLocationState();
}

class _ChooseEventLocationState extends ConsumerState<ChooseEventLocation> {
  String address = '';
  double? lat;
  double? lon;

  // Using OpenStreetMap tiles - no API key required
  final String mapUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // IMPORTANT: We'll recreate the map when location changes instead of using controller
  // This ensures the map fully refreshes with new coordinates

  Future<List<Map<String, dynamic>>> fetchSuggestions(String input) async {
    if (input.length < 3) return [];

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=$input&addressdetails=1',
    );

    try {
      // Add required User-Agent header
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FlutterMapApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data
            .map(
              (e) => {
            'display_name': e['display_name'] as String,
            'lat': e['lat'] as String,
            'lon': e['lon'] as String,
          },
        )
            .toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load suggestions');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CreateTabAppbar(
        onTap: () {
          _deleteEvent();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            const SectionTitle(
              title: 'Where are you \nbooking?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            TypeAheadField(
              suggestionsCallback: (pattern) async {
                return await fetchSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(
                    suggestion['display_name'],
                    style: const TextStyle(color: AppColors.primaryWhite),
                  ),
                  tileColor: AppColors.secondaryBackground,
                );
              },
              onSelected: (Map<String, dynamic> suggestion) {
                setState(() {
                  address = suggestion['display_name'];

                  // Parse coordinates
                  lat = double.tryParse(suggestion['lat']);
                  lon = double.tryParse(suggestion['lon']);

                  // Debug output
                  print('Selected location: $address');
                  print('Coordinates: lat=$lat, lon=$lon');
                });

                FocusScope.of(context).requestFocus(FocusNode());
              },
              builder: (context, controller, focusNode) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  cursorColor: Colors.white,
                  style: const TextStyle(color: AppColors.primaryWhite),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter Address',
                    hintStyle: const TextStyle(color: AppColors.secondaryWhite),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Icon(
                        Icons.search,
                        color: AppColors.secondaryWhite,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: AppColors.secondaryBackground,
                      ),
                      borderRadius: BorderRadius.circular(70.0),
                    ),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                        width: 0.8,
                        color: AppColors.secondaryBackground,
                      ),
                      borderRadius: BorderRadius.circular(70.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        width: 1.1,
                        color: AppColors.secondaryBackground,
                      ),
                      borderRadius: BorderRadius.circular(70.0),
                    ),
                  ),
                );
              },
            ),
            if (address.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  address,
                  style: const TextStyle(color: AppColors.primaryWhite),
                  textAlign: TextAlign.center,
                ),
              ),
            if (lat != null && lon != null)
              Expanded(
                // CRITICAL: Add unique key that changes when lat/lon changes
                // This forces Flutter to recreate the map widget
                key: ValueKey('map-${lat.toString()}-${lon.toString()}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FlutterMap(
                    // Don't use mapController here - we're forcing recreation instead
                    options: MapOptions(
                      initialCenter: LatLng(lat!, lon!),
                      initialZoom: 15,
                      maxZoom: 18,
                      minZoom: 3,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: mapUrl,
                        userAgentPackageName: 'com.wyld.wyld',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(lat!, lon!),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              size: 40.0,
                              color: AppColors.primaryPink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              const Spacer(),
            const SizedBox(height: 20.0),
            if (address.isNotEmpty)
              FullWidthButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20.0,
                ),
                name: 'Next',
                onPressed: _saveLocation,
              ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  void _saveLocation() async {
    try {
      // Save venue address
      await ref
          .read(eventControllerProvider.notifier)
          .updateEventField(widget.eventId, 'venueAddress', address);

      // Save venue name (first part of address)
      final venueName = address.split(',')[0];
      await ref
          .read(eventControllerProvider.notifier)
          .updateEventField(widget.eventId, 'nameOfVenue', venueName);

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamed('/event-date-time', arguments: widget.eventId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving location: $e')));
    }
  }

  void _deleteEvent() async {
    try {
      await ref
          .read(eventControllerProvider.notifier)
          .deleteEvent(widget.eventId);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting event: $e')));
    }
  }
}