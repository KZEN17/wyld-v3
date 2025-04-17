import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/data/models/event_model.dart';

final eventRepositoryProvider = Provider((ref) {
  return EventRepository(
    db: Databases(
      Client()
        ..setEndpoint(AppwriteConstants.endpoint)
        ..setProject(AppwriteConstants.projectId),
    ),
    storage: Storage(
      Client()
        ..setEndpoint(AppwriteConstants.endpoint)
        ..setProject(AppwriteConstants.projectId),
    ),
  );
});

class EventRepository {
  final Databases _db;
  final Storage _storage;

  EventRepository({required Databases db, required Storage storage})
    : _db = db,
      _storage = storage;

  // Create a new event with separate data fields
  Future<EventModel> addEventWithData(Map<String, dynamic> eventData) async {
    try {
      await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.eventsCollection,
        documentId: eventData['eventId'],
        data: eventData,
      );

      // Reconstruct the event model with the numberOfGuests map
      return EventModel(
        eventId: eventData['eventId'],
        eventType: eventData['eventType'],
        venueAddress: eventData['venueAddress'],
        nameOfVenue: eventData['nameOfVenue'],
        eventDateTime: DateTime.parse(eventData['eventDateTime']),
        eventTitle: eventData['eventTitle'],
        eventDescription: eventData['eventDescription'],
        numberOfGuests: {
          'men': eventData['numberOfGuestsMen'] ?? 0,
          'women': eventData['numberOfGuestsWomen'] ?? 0,
        },
        priceMen: eventData['priceMen'],
        priceWomen: eventData['priceWomen'],
        isDraft: eventData['isDraft'],
        venueImages: List<String>.from(eventData['venueImages']),
        hostId: eventData['hostId'],
        guestsId: List<String>.from(eventData['guestsId']),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Create a new event (for backward compatibility)
  Future<EventModel> addEvent(EventModel event) async {
    try {
      // Convert the event to data with separate fields
      final eventData = {
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

      await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.eventsCollection,
        documentId: event.eventId,
        data: eventData,
      );

      return event;
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
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.eventsCollection,
        documentId: eventId,
        data: {field: value},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get event by ID
  Future<EventModel> getEventById(String eventId) async {
    try {
      final document = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.eventsCollection,
        documentId: eventId,
      );

      // Convert the document data to an EventModel, combining the separate guest fields
      final data = document.data;
      return EventModel(
        eventId: data['eventId'],
        eventType: data['eventType'],
        venueAddress: data['venueAddress'],
        nameOfVenue: data['nameOfVenue'],
        eventDateTime: DateTime.parse(data['eventDateTime']),
        eventTitle: data['eventTitle'],
        eventDescription: data['eventDescription'],
        numberOfGuests: {
          'men': data['numberOfGuestsMen'] ?? 0,
          'women': data['numberOfGuestsWomen'] ?? 0,
        },
        priceMen: data['priceMen']?.toDouble() ?? 0.0,
        priceWomen: data['priceWomen']?.toDouble() ?? 0.0,
        isDraft: data['isDraft'] ?? true,
        venueImages: List<String>.from(data['venueImages'] ?? []),
        hostId: data['hostId'],
        guestsId: List<String>.from(data['guestsId'] ?? []),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _db.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.eventsCollection,
        documentId: eventId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get all non-draft events
  Future<List<EventModel>> getEvents() async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.eventsCollection,
        queries: [Query.equal('isDraft', false)],
      );

      return documents.documents.map((document) {
        final data = document.data;
        return EventModel(
          eventId: data['eventId'],
          eventType: data['eventType'],
          venueAddress: data['venueAddress'],
          nameOfVenue: data['nameOfVenue'],
          eventDateTime: DateTime.parse(data['eventDateTime']),
          eventTitle: data['eventTitle'],
          eventDescription: data['eventDescription'],
          numberOfGuests: {
            'men': data['numberOfGuestsMen'] ?? 0,
            'women': data['numberOfGuestsWomen'] ?? 0,
          },
          priceMen: data['priceMen']?.toDouble() ?? 0.0,
          priceWomen: data['priceWomen']?.toDouble() ?? 0.0,
          isDraft: data['isDraft'] ?? true,
          venueImages: List<String>.from(data['venueImages'] ?? []),
          hostId: data['hostId'],
          guestsId: List<String>.from(data['guestsId'] ?? []),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Upload event images

  Future<List<String>> uploadEventImages(
      List<File> imageFiles,
      String eventId,
      ) async {
    final List<String> imageUrls = [];

    for (var imageFile in imageFiles) {
      try {
        final uploadedFile = await _storage.createFile(
          bucketId: AppwriteConstants.eventImagesBucket,
          fileId: ID.unique(),
          file: InputFile.fromPath(
            path: imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        );

        // Build the URL string directly instead of using toString()
        final String fileUrl =
            '${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.eventImagesBucket}/files/${uploadedFile.$id}/preview?project=${AppwriteConstants.projectId}';

        imageUrls.add(fileUrl);
      } catch (e) {
        if (kDebugMode) {
          print('Error uploading image: $e');
        }
      }
    }

    // Update the event document with the new image URLs
    if (imageUrls.isNotEmpty) {
      try {
        await _db.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.eventsCollection,
          documentId: eventId,
          data: {'venueImages': imageUrls},
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error updating event with image URLs: $e');
        }
      }
    }

    return imageUrls;
  }

  // Future<List<String>> uploadEventImages(
  //   String eventId,
  //   List<String> imagePaths,
  // ) async {
  //   try {
  //     List<String> uploadedImageUrls = [];

  //     for (int i = 0; i < imagePaths.length; i++) {
  //       final path = imagePaths[i];
  //       final fileId = '${eventId.substring(0, 8)}_img_$i';

  //       final file = await _storage.createFile(
  //         bucketId: AppwriteConstants.eventImagesBucket,
  //         fileId: fileId,
  //         file: InputFile.fromPath(path: path),
  //       );

  //       final imageUrl =
  //           _storage
  //               .getFileView(
  //                 bucketId: AppwriteConstants.eventImagesBucket,
  //                 fileId: file.$id,
  //               )
  //               .toString();

  //       uploadedImageUrls.add(imageUrl);
  //     }

  //     // Update the event with new image URLs
  //     await _db.updateDocument(
  //       databaseId: AppwriteConstants.databaseId,
  //       collectionId: AppwriteConstants.eventsCollection,
  //       documentId: eventId,
  //       data: {'venueImages': uploadedImageUrls},
  //     );

  //     return uploadedImageUrls;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
}
