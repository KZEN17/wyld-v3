import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/bookings/create/screens/create_event_screen.dart';
import '../../features/bookings/screens/chosen_event_details.dart';
import '../../features/bookings/screens/steps/choose_event_location.dart';
import '../../features/bookings/screens/steps/event_date_time.dart';
import '../../features/bookings/screens/steps/event_details.dart';
import '../../features/bookings/screens/steps/event_type_selection.dart';
import '../../features/bookings/screens/steps/event_upload_images.dart';
import '../../features/bookings/screens/steps/invite_contacts.dart';
import '../../features/bookings/screens/steps/invite_success.dart';
import '../../features/bookings/screens/steps/number_of_guests.dart';
import '../../features/bookings/screens/steps/price_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_settings.dart';
import '../../features/profile/screens/profile_view.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String profileView = '/profile-view';
  static const String profileSettings = '/profile-settings';
  static const String createEvent = '/create-event';
  static const String eventTypeSelection = '/event-type-selection';
  static const String chooseEventLocation = '/choose-event-location';
  static const String eventDateTime = '/event-date-time';
  static const String eventDetails = '/event-details';
  static const String numberOfGuests = '/number-of-guests';
  static const String priceScreen = '/price-screen';
  static const String inviteContacts = '/invite-contacts';
  static const String inviteSuccess = '/invite-success';
  static const String chosenEventDetails = '/chosen-event-details';
  static const String eventImageUpload = '/event-image-upload';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case profileView:
        return MaterialPageRoute(builder: (_) => const ProfileView());
      case profileSettings:
        return MaterialPageRoute(builder: (_) => const ProfileSettings());
      case createEvent:
        return MaterialPageRoute(builder: (_) => const CreateEventScreen());
      case eventTypeSelection:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => EventTypeSelection(eventId: args),
          );
        }
        return _errorRoute('Event ID is required');
      case chooseEventLocation:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => ChooseEventLocation(eventId: args),
          );
        }
        return _errorRoute('Event ID is required');
      case eventDateTime:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => EventDateTime(eventId: args),
          );
        }
        return _errorRoute('Event ID is required');
      case eventDetails:
        if (args is String) {
          return MaterialPageRoute(builder: (_) => EventDetails(eventId: args));
        }
        return _errorRoute('Event ID is required');
      case numberOfGuests:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => NumberOfGuests(eventId: args),
          );
        }
        return _errorRoute('Event ID is required');
      case priceScreen:
        if (args is String) {
          return MaterialPageRoute(builder: (_) => PriceScreen(eventId: args));
        }
        return _errorRoute('Event ID is required');
      case eventImageUpload:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => EventImageUpload(eventId: args),
          );
        }
        return _errorRoute('Event ID is required');
      case inviteContacts:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => InviteContacts(eventId: args),
          );
        }
        return _errorRoute('Event ID is required');
      case inviteSuccess:
        return MaterialPageRoute(builder: (_) => const InviteSuccess());
      case chosenEventDetails:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => ChosenEventDetails(eventId: args),
          );
        }
        return _errorRoute('Event ID is required');
      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder:
          (_) => Scaffold(
            body: Center(
              child: Text(
                'Error: $message',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
    );
  }

  // Initial route based on authentication status
  static String initialRoute() {
    // This would typically check if a user is logged in
    // For now, we'll just return the login route
    return login;
  }
}
