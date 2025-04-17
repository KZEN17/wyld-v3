import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/full_width_button.dart';
import '../../controllers/event_controller.dart';
import '../../screens/widgets/create_venue_appbar.dart';

class EventTypeSelection extends ConsumerStatefulWidget {
  final String eventId;

  const EventTypeSelection({super.key, required this.eventId});

  @override
  ConsumerState<EventTypeSelection> createState() => _EventTypeSelectionState();
}

class _EventTypeSelectionState extends ConsumerState<EventTypeSelection> {
  String selectedEventType = '';
  final List<Map<String, dynamic>> eventTypes = [
    {'name': 'Dating', 'image': 'assets/dating.png'},
    {'name': 'Workshop', 'image': 'assets/workshop.png'},
    {'name': 'Meetup', 'image': 'assets/meetup.png'},
    {'name': 'Lunch', 'image': 'assets/lunch.png'},
    {'name': 'Coffee Time', 'image': 'assets/coffee_time.png'},
    {'name': 'Other', 'image': 'assets/other.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CreateTabAppbar(
        onTap: () {
          _deleteEvent();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What is the type of the event?',
              style: TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 28.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40.0),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  // childAspectRatio: 1.3,
                ),
                itemCount: eventTypes.length,
                itemBuilder: (context, index) {
                  final eventType = eventTypes[index];
                  final isSelected = selectedEventType == eventType['name'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedEventType = eventType['name'];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        image: DecorationImage(image: AssetImage(eventType['image']),
                            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.darken),
                            fit: BoxFit.cover),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primaryPink
                                  : AppColors.grayBorder,
                          width: 3.0,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            eventType['name'],
                            style: const TextStyle(
                              color: AppColors.primaryWhite,
                              fontSize: 20.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // const Spacer(),
            FullWidthButton(
              name: 'Next',
              onPressed: selectedEventType.isEmpty ? () {} : _saveEventType,
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20.0,
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  void _saveEventType() async {
    try {
      await ref
          .read(eventControllerProvider.notifier)
          .updateEventField(widget.eventId, 'eventType', selectedEventType);

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamed('/choose-event-location', arguments: widget.eventId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating event type: $e')));
    }
  }

  void _deleteEvent() async {
    try {
      await ref
          .read(eventControllerProvider.notifier)
          .deleteEvent(widget.eventId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting event: $e')));
    }
  }
}
