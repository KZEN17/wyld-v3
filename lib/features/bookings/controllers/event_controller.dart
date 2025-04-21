import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/realtime_service.dart';
import '../../../shared/data/models/event_model.dart';
import '../repositories/event_repository.dart';

// Provider for all events (non-draft)
final eventsProvider =
StateNotifierProvider<EventController, AsyncValue<List<EventModel>>>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  final realtimeService = ref.watch(realtimeServiceProvider);
  return EventController(eventRepository, realtimeService);
});

// Provider for a specific event by ID with real-time updates
final eventProvider = StateNotifierProvider.family<SingleEventController, AsyncValue<EventModel>, String>(
      (ref, eventId) {
    final eventRepository = ref.watch(eventRepositoryProvider);
    final realtimeService = ref.watch(realtimeServiceProvider);
    return SingleEventController(eventRepository, realtimeService, eventId);
  },
);

// This is the critical fix - adding the eventControllerProvider
final eventControllerProvider =
StateNotifierProvider<EventController, AsyncValue<List<EventModel>>>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  final realtimeService = ref.watch(realtimeServiceProvider);
  return EventController(eventRepository, realtimeService);
});

// Controller for a single event with real-time updates
class SingleEventController extends StateNotifier<AsyncValue<EventModel>> {
  final EventRepository _eventRepository;
  final RealtimeService _realtimeService;
  final String _eventId;
  StreamSubscription? _subscription;

  SingleEventController(this._eventRepository, this._realtimeService, this._eventId)
      : super(const AsyncValue.loading()) {
    _loadEvent();
    _subscribeToEventChanges();
  }

  Future<void> _loadEvent() async {
    try {
      final event = await _eventRepository.getEventById(_eventId);
      state = AsyncValue.data(event);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _subscribeToEventChanges() {
    try {
      _subscription = _realtimeService
          .subscribeToDocument(AppwriteConstants.eventsCollection, _eventId)
          .listen((event) {
        if (kDebugMode) {
          print('Event real-time update received for $_eventId');
        }

        if (event.events.contains('databases.*.collections.*.documents.*.update') ||
            event.events.contains('databases.*.collections.*.documents.*.create')) {
          // Update state with new event data
          try {
            final updatedEvent = EventModel.fromJson(event.payload);
            state = AsyncValue.data(updatedEvent);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing updated event: $e');
            }
          }
        } else if (event.events.contains('databases.*.collections.*.documents.*.delete')) {
          // Handle delete if needed
          state = AsyncValue.error("Event has been deleted", StackTrace.current);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to event changes: $e');
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class EventController extends StateNotifier<AsyncValue<List<EventModel>>> {
  final EventRepository _eventRepository;
  final RealtimeService _realtimeService;
  StreamSubscription? _subscription;

  EventController(this._eventRepository, this._realtimeService) : super(const AsyncValue.loading()) {
    getEvents();
    _subscribeToEvents();
  }

  // Subscribe to events collection for real-time updates
  void _subscribeToEvents() {
    try {
      _subscription = _realtimeService
          .subscribeToCollection(AppwriteConstants.eventsCollection)
          .listen((event) {
        if (kDebugMode) {
          print('Events collection update: ${event.events}');
        }

        // Refresh all events on any change
        // This is a simple approach - you could also update only the changed event
        // for better performance in a larger application
        getEvents();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to events: $e');
      }
    }
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

      // No need to call getEvents() - we'll get the update via Realtime
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

      // No need to call getEvents() - we'll get the update via Realtime
    } catch (e) {
      rethrow;
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventRepository.deleteEvent(eventId);
      // No need to call getEvents() - we'll get the update via Realtime
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
      // No need to call getEvents() - we'll get the update via Realtime
      return imageUrls;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}