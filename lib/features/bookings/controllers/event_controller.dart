import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/models/event_model.dart';
import '../repositories/event_repository.dart';

// Provider for all events (non-draft)
final eventsProvider =
    StateNotifierProvider<EventController, AsyncValue<List<EventModel>>>((ref) {
      final eventRepository = ref.watch(eventRepositoryProvider);
      return EventController(eventRepository);
    });

// Provider for a specific event by ID
final eventProvider = FutureProvider.family<EventModel, String>((ref, eventId) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return eventRepository.getEventById(eventId);
});

// This is the critical fix - adding the eventControllerProvider
final eventControllerProvider =
    StateNotifierProvider<EventController, AsyncValue<List<EventModel>>>((ref) {
      final eventRepository = ref.watch(eventRepositoryProvider);
      return EventController(eventRepository);
    });

class EventController extends StateNotifier<AsyncValue<List<EventModel>>> {
  final EventRepository _eventRepository;

  EventController(this._eventRepository) : super(const AsyncValue.loading()) {
    getEvents();
  }

  // Get all events
  Future<void> getEvents() async {
    state = const AsyncValue.loading();
    try {
      final events = await _eventRepository.getEvents();
      state = AsyncValue.data(events);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Add a new event
  Future<EventModel> addEvent(EventModel event) async {
    try {
      // When adding a new event, we need to separate the numberOfGuests field
      // into numberOfGuestsMen and numberOfGuestsWomen for Appwrite
      final Map<String, dynamic> eventData = {
        'eventId': event.eventId,
        'eventType': event.eventType,
        'venueAddress': event.venueAddress,
        'nameOfVenue': event.nameOfVenue,
        'eventDateTime': event.eventDateTime.toIso8601String(),
        'eventTitle': event.eventTitle,
        'eventDescription': event.eventDescription,
        'numberOfGuestsMen': event.numberOfGuests['men'] ?? 0,
        'numberOfGuestsWomen': event.numberOfGuests['women'] ?? 0,
        'priceMen': event.priceMen,
        'priceWomen': event.priceWomen,
        'isDraft': event.isDraft,
        'venueImages': event.venueImages,
        'hostId': event.hostId,
        'guestsId': event.guestsId,
      };

      final newEvent = await _eventRepository.addEventWithData(eventData);

      // Refresh events list
      getEvents();
      return newEvent;
    } catch (e) {
      rethrow;
    }
  }

  // Update an event field
  Future<void> updateEventField(
    String eventId,
    String field,
    dynamic value,
  ) async {
    try {
      // Special handling for numberOfGuests which is now split into two fields
      if (field == 'numberOfGuests' && value is Map<String, dynamic>) {
        // Update both men and women count fields separately
        await _eventRepository.updateEventField(
          eventId,
          'numberOfGuestsMen',
          value['men'] ?? 0,
        );

        await _eventRepository.updateEventField(
          eventId,
          'numberOfGuestsWomen',
          value['women'] ?? 0,
        );
      } else {
        // Regular field update
        await _eventRepository.updateEventField(eventId, field, value);
      }

      // Refresh events list
      getEvents();
    } catch (e) {
      rethrow;
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventRepository.deleteEvent(eventId);
      // Refresh events list
      getEvents();
    } catch (e) {
      rethrow;
    }
  }

  // Upload event images

  Future<List<String>> uploadEventImages(
      String eventId,
      List<File> imageFiles,
      ) async {
    try {
      // Fix the parameter order here
      final imageUrls = await _eventRepository.uploadEventImages(
        imageFiles,  // First parameter - list of image files
        eventId,     // Second parameter - the event ID
      );
      // Refresh events list
      getEvents();
      return imageUrls;
    } catch (e) {
      rethrow;
    }
  }
}
