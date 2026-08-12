import 'package:flutter/material.dart';

/// Maps an amenity name to an icon.
///
/// Amenities are free-form strings on the backend, so this matches on a
/// lowercased substring rather than exact equality — "Free Parking" and
/// "Parking" both resolve to the same glyph. Anything unrecognised falls back
/// to a neutral check so an unexpected value still renders sensibly.
IconData iconForAmenity(String amenity) {
  final String name = amenity.toLowerCase();

  if (name.contains('wifi') || name.contains('wi-fi')) return Icons.wifi;
  if (name.contains('parking')) return Icons.local_parking_outlined;
  if (name.contains('shower')) return Icons.shower_outlined;
  if (name.contains('locker')) return Icons.lock_outline;
  if (name.contains('water') || name.contains('drink')) {
    return Icons.local_drink_outlined;
  }
  if (name.contains('flood') || name.contains('light')) {
    return Icons.lightbulb_outline;
  }
  if (name.contains('changing') || name.contains('room')) {
    return Icons.checkroom_outlined;
  }
  if (name.contains('cafe') || name.contains('food')) {
    return Icons.restaurant_outlined;
  }
  if (name.contains('first aid') || name.contains('medical')) {
    return Icons.medical_services_outlined;
  }
  if (name.contains('seat') || name.contains('spectator')) {
    return Icons.event_seat_outlined;
  }
  if (name.contains('toilet') || name.contains('restroom')) return Icons.wc;
  if (name.contains('security') || name.contains('cctv')) {
    return Icons.videocam_outlined;
  }

  return Icons.check_circle_outline;
}

/// The amenities offered in the filter sheet and the add-venue form.
///
/// One list rather than the two that had drifted apart — the home filter
/// offered six options while the add-venue form offered nine, so three
/// amenities could be set on a venue but never filtered for.
const List<String> kAmenityOptions = <String>[
  'Wifi',
  'Parking',
  'Showers',
  'Lockers',
  'Water',
  'Floodlights',
  'Changing Rooms',
  'Cafeteria',
  'First Aid',
];
