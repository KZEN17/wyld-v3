import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/full_width_button.dart';
import '../../controllers/event_controller.dart';
import '../widgets/create_venue_appbar.dart';

class EventTypeSelection extends ConsumerStatefulWidget {
  final String eventId;

  const EventTypeSelection({super.key, required this.eventId});

  @override
  ConsumerState<EventTypeSelection> createState() => _EventTypeSelectionState();
}

class _EventTypeSelectionState extends ConsumerState<EventTypeSelection> {
  String selectedEventType = '';
  final List<Map<String, dynamic>> eventTypes = [
    {'name': 'Dinner', 'icon': Icons.dinner_dining},
    {'name': 'Drinks', 'icon': Icons.local_bar},
    {'name': 'Party', 'icon': Icons.celebration},
    {'name': 'Business', 'icon': Icons.business},
    {'name': 'Other', 'icon': Icons.more_horiz},
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
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What type of event?',
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
                  childAspectRatio: 1.3,
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
                        color:
                            isSelected
                                ? AppColors.primaryPink
                                : AppColors.secondaryBackground,
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primaryPink
                                  : AppColors.grayBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            eventType['icon'],
                            color: AppColors.primaryWhite,
                            size: 40.0,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            eventType['name'],
                            style: const TextStyle(
                              color: AppColors.primaryWhite,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
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
