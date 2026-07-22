import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  static const String _supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String _storageBucket = 'listing-photos';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static AuthRepo get auth => client.auth;
  static StorageClient get storage => client.storage;

  static Future<String> uploadPhoto(File photoFile, String fileName) async {
    final userId = auth.currentUser!.id;
    final filePath = '$userId/$fileName';
    
    await storage.from(_storageBucket).upload(filePath, photoFile);
    
    final imageUrl = storage.from(_storageBucket).getPublicUrl(filePath);
    return imageUrl;
  }

  static Future<void> createListing({
    required String title,
    required String description,
    required String category,
    required String type,
    String? photoUrl,
    required double latitude,
    required double longitude,
  }) async {
    final userId = auth.currentUser!.id;
    
    await client.from('listings').insert({
      'owner_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      'photo_url': photoUrl,
      'status': 'active',
      'location_lat': latitude,
      'location_lng': longitude,
    });
  }
}
