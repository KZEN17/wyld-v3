class EventModel {
  String eventId;
  String eventType;
  String venueAddress;
  String nameOfVenue;
  DateTime eventDateTime;
  String eventTitle;
  String eventDescription;
  Map<String, int> numberOfGuests;
  double priceMen;
  double priceWomen;
  bool isDraft;
  List<String> venueImages;
  String hostId;
  List<String> guestsId;

  EventModel({
    required this.eventId,
    required this.eventType,
    required this.venueAddress,
    required this.nameOfVenue,
    required this.eventDateTime,
    required this.eventTitle,
    required this.eventDescription,
    required this.numberOfGuests,
    required this.priceMen,
    required this.priceWomen,
    required this.isDraft,
    required this.venueImages,
    required this.hostId,
    required this.guestsId,
  });

  // For sending to Appwrite, we split numberOfGuests into separate fields
  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'eventType': eventType,
    'venueAddress': venueAddress,
    'nameOfVenue': nameOfVenue,
    'eventDateTime': eventDateTime.toIso8601String(),
    'eventTitle': eventTitle,
    'eventDescription': eventDescription,
    'numberOfGuestsMen': numberOfGuests['men'] ?? 0,
    'numberOfGuestsWomen': numberOfGuests['women'] ?? 0,
    'priceMen': priceMen,
    'priceWomen': priceWomen,
    'isDraft': isDraft,
    'venueImages': venueImages,
    'hostId': hostId,
    'guestsId': guestsId,
  };

  // When receiving from Appwrite, we combine the separate fields into the numberOfGuests map
  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
    eventId: json['eventId'] ?? '',
    eventType: json['eventType'] ?? '',
    venueAddress: json['venueAddress'] ?? '',
    nameOfVenue: json['nameOfVenue'] ?? '',
    eventDateTime:
        json['eventDateTime'] != null
            ? DateTime.parse(json['eventDateTime'])
            : DateTime.now(),
    eventTitle: json['eventTitle'] ?? '',
    eventDescription: json['eventDescription'] ?? '',
    numberOfGuests: {
      'men': json['numberOfGuestsMen'] ?? 0,
      'women': json['numberOfGuestsWomen'] ?? 0,
    },
    priceMen: (json['priceMen'] ?? 0).toDouble(),
    priceWomen: (json['priceWomen'] ?? 0).toDouble(),
    isDraft: json['isDraft'] ?? true,
    venueImages:
        json['venueImages'] != null
            ? List<String>.from(json['venueImages'])
            : [],
    hostId: json['hostId'] ?? '',
    guestsId:
        json['guestsId'] != null ? List<String>.from(json['guestsId']) : [],
  );
}
