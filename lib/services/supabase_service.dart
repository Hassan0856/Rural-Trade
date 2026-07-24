import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';

class SupabaseService {
  static late final String _supabaseUrl;
  static late final String _supabaseAnonKey;
  static const String _storageBucket = 'listing-photos';

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'YOUR_SUPABASE_URL';
    _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY';
    
  await Supabase.initialize(
  url: _supabaseUrl,
  publishableKey: _supabaseAnonKey,
);
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;

  static Future<String> uploadPhotoBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = auth.currentUser!.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '$userId/${timestamp}_$fileName';
    
    await storage.from(_storageBucket).uploadBinary(
      filePath,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );
    
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
    
    try {
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
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
