// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/data/models/event_model.dart';
import '../../../../shared/widgets/full_width_button.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/event_controller.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fill,
                  image: AssetImage('assets/create.jpg'),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Text(
                'Create your Event',
                style: TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 36.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'You\'re just a few steps away from having a wyld time!',
                style: TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Spacer(),
            FullWidthButton(
              name: 'Let\'s get started',
              onPressed: () {
                _createNewEvent();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewEvent() async {
    final String eventId = uuid.v4();

    // Show loading indicator
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Creating new event...')));

    try {
      // Get the current user ID from auth controller
      final user = ref.read(authControllerProvider).value;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to create an event'),
          ),
        );
        return;
      }

      // Create new event with initial data
      final event = EventModel(
        eventId: eventId,
        eventType: "",
        venueAddress: "",
        nameOfVenue: "",
        eventDateTime: DateTime.now(),
        eventTitle: "",
        eventDescription: "",
        numberOfGuests: {'men': 0, 'women': 0},
        priceMen: 0.0,
        priceWomen: 0.0,
        isDraft: true,
        venueImages: [],
        hostId: user.id,
        guestsId: [],
      );

      // Save the event using the controller
      await ref.read(eventControllerProvider.notifier).addEvent(event);

      // Navigate to next screen
      Navigator.of(
        context,
      ).pushNamed('/event-type-selection', arguments: eventId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating event: $e')));
    }
  }
}
