/// Route names and paths, kept in one place so no screen hardcodes a string.
///
/// Names are used for navigation (`context.goNamed(AppRoutes.venueDetails)`),
/// paths for the router table and deep links.
class AppRoutes {
  const AppRoutes._();

  static const String splash = 'splash';
  static const String splashPath = '/';

  static const String login = 'login';
  static const String loginPath = '/login';

  static const String register = 'register';
  static const String registerPath = '/register';

  static const String home = 'home';
  static const String homePath = '/home';

  static const String venueDetails = 'venue-details';
  // Relative to /home, so backing out of a venue lands on the list.
  static const String venueDetailsPath = 'venue/:venueId';

  static const String booking = 'booking';
  static const String bookingPath = 'book';

  static const String addVenue = 'add-venue';
  static const String addVenuePath = 'add-venue';

  static const String myBookings = 'my-bookings';
  static const String myBookingsPath = 'bookings';

  static const String chat = 'chat';
  static const String chatPath = 'chat/:receiverId';

  static const String profile = 'profile';
  static const String profilePath = 'profile';
}
