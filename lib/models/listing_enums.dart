// lib/models/listing_enums.dart
//
// Centralized enums for listing types and categories.
// Keys are the database values (lowercase), values are display labels.

class ListingEnums {
  static const Map<String, String> exchangeTypes = {
    'rent': 'Rent',
    'lend': 'Lend',
    'sell': 'Sell',
    'exchange': 'Exchange',
  };

  static const Map<String, String> categories = {
    'tractor': 'Tractor',
    'water_pump': 'Water Pump',
    'generator': 'Generator',
    'tools': 'Tools',
    'produce': 'Produce',
    'other': 'Other',
  };
}
