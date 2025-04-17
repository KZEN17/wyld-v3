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
import '../widgets/create_venue_appbar.dart';

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
  String styleUrl =
      "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png";
  String apiKey =
      "22d0ef19-8f92-4d02-96d9-f5703c4def64"; // Replace with your API key

  Future<List<Map<String, dynamic>>> fetchSuggestions(String input) async {
    if (input.length < 3) return [];

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=$input&addressdetails=1',
    );

    final response = await http.get(url);

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
      throw Exception('Failed to load suggestions');
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
                  lat = double.tryParse(suggestion['lat']);
                  lon = double.tryParse(suggestion['lon']);
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
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  address,
                  style: const TextStyle(color: AppColors.primaryWhite),
                  textAlign: TextAlign.center,
                ),
              ),
            if (lat != null && lon != null)
              Expanded(
                child: FlutterMap(
                  key: ValueKey("$lat$lon"),
                  options: MapOptions(
                    // center: LatLng(lat!, lon!),
                    // zoom: 18,
                    maxZoom: 18,
                    minZoom: 3,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: styleUrl,
                      additionalOptions: {"api_key": apiKey},
                      maxZoom: 20,
                      maxNativeZoom: 20,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat!, lon!),
                          child: const Icon(
                            Icons.location_pin,
                            size: 30.0,
                            color: AppColors.primaryPink,
                          ),
                        ),
                      ],
                    ),
                  ],
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
