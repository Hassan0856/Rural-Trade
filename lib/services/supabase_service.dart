import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class SupabaseService {
  static const String _storageBucket = 'listing-photos';

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env file');
    }
    
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;

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

  static Future<List<Map<String, dynamic>>> fetchListings() async {
    final response = await client
        .from('listings')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> createRequest({
    required String listingId,
    required String ownerId,
  }) async {
    final requesterId = auth.currentUser!.id;
    
    await client.from('requests').insert({
      'listing_id': listingId,
      'requester_id': requesterId,
      'owner_id': ownerId,
      'status': 'pending',
    });
  }

  static Future<Map<String, dynamic>?> fetchUserData(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> fetchUserReviews(String userId) async {
    try {
      final response = await client
          .from('reviews')
          .select('rating')
          .eq('reviewee_id', userId);
      
      final reviews = List<Map<String, dynamic>>.from(response);
      
      if (reviews.isEmpty) {
        return {'averageRating': 0.0, 'totalReviews': 0};
      }
      
      final totalRating = reviews.fold<double>(
        0, (sum, review) => sum + (review['rating'] as num).toDouble()
      );
      final averageRating = totalRating / reviews.length;
      
      return {
        'averageRating': averageRating,
        'totalReviews': reviews.length,
      };
    } catch (e) {
      return {'averageRating': 0.0, 'totalReviews': 0};
    }
  }

  static String getVerificationBadge(int? trustScore, String? badgeLevel) {
    if (badgeLevel != null && badgeLevel.toLowerCase() == 'flagged') {
      return 'Flagged';
    }
    
    if (trustScore == null || trustScore < 50) {
      return 'New trader';
    }
    
    if (trustScore >= 80) {
      return 'Verified';
    }
    
    return 'New trader';
  }

  static Color getVerificationBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'flagged':
        return Colors.red;
      case 'new trader':
      default:
        return Colors.orange;
    }
  }
}
