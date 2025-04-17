import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/full_width_button.dart';
import '../../controllers/event_controller.dart';
import '../../screens/widgets/create_venue_appbar.dart';

class EventDetails extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetails({super.key, required this.eventId});

  @override
  ConsumerState<EventDetails> createState() => _EventDetailsState();
}

class _EventDetailsState extends ConsumerState<EventDetails> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CreateTabAppbar(
        onTap: () {
          _deleteEvent();
        },
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What\'s the event?',
                style: TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 28.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30.0),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 16.0,
                ),
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  labelStyle: TextStyle(
                    color: AppColors.secondaryWhite,
                    fontSize: 14.0,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grayBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30.0),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 16.0,
                ),
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Event Description',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(
                    color: AppColors.secondaryWhite,
                    fontSize: 14.0,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grayBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event description';
                  }
                  return null;
                },
              ),
              const Spacer(),
              FullWidthButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20.0,
                ),
                name: 'Confirm Event Details',
                onPressed: _saveEventDetails,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  void _saveEventDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Save event title
        await ref
            .read(eventControllerProvider.notifier)
            .updateEventField(
              widget.eventId,
              'eventTitle',
              _titleController.text,
            );

        // Save event description
        await ref
            .read(eventControllerProvider.notifier)
            .updateEventField(
              widget.eventId,
              'eventDescription',
              _descriptionController.text,
            );

        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamed('/number-of-guests', arguments: widget.eventId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving event details: $e')),
        );
      }
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
