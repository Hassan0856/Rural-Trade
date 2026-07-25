import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  static Database? _database;

  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('LocalDatabase is not supported on web.');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rural_trader.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createCachedListingsTable(db);

    // Queue table for pending listings
    await db.execute('''
      CREATE TABLE pending_listings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        location_lat REAL,
        location_lng REAL,
        location_name TEXT,
        image_base64 TEXT,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final tableInfo = await db.rawQuery('PRAGMA table_info(pending_listings)');
      final hasPayloadColumn = tableInfo.any((column) => column['name'] == 'payload');
      if (!hasPayloadColumn) {
        await db.execute('ALTER TABLE pending_listings ADD COLUMN payload TEXT NOT NULL DEFAULT "{}"');
      }
    }

    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS cached_listings');
      await _createCachedListingsTable(db);
    }
  }

  Future<void> _createCachedListingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE cached_listings (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        location_lat REAL,
        location_lng REAL,
        location_name TEXT,
        image_url TEXT,
        photo_url TEXT,
        owner_id TEXT NOT NULL,
        owner_name TEXT,
        owner_phone TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
  }

  // Listings cache operations
  Future<void> cacheListings(List<Map<String, dynamic>> listings) async {
    if (kIsWeb) return;

    final db = await database;
    final batch = db.batch();
    
    // Clear existing cache
    batch.delete('cached_listings');
    
    final cachedAt = DateTime.now().millisecondsSinceEpoch;
    
    for (final listing in listings) {
      batch.insert('cached_listings', {
        'id': listing['id'],
        'title': listing['title'],
        'description': listing['description'],
        'category': listing['category'],
        'type': listing['type'],
        'location_lat': listing['location_lat'],
        'location_lng': listing['location_lng'],
        'location_name': listing['location_name'],
        'image_url': listing['image_url'],
        'owner_id': listing['owner_id'],
        'owner_name': listing['owner_name'],
        'owner_phone': listing['owner_phone'],
        'status': listing['status'],
        'created_at': listing['created_at'],
        'cached_at': cachedAt,
      });
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedListings() async {
    if (kIsWeb) return [];
    final db = await database;
    final listings = await db.query('cached_listings');
    return listings;
  }

  Future<void> clearCache() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('cached_listings');
  }

  // Pending listings operations
  Future<int> addPendingListing(Map<String, dynamic> listingData) async {
    if (kIsWeb) return -1;
    final db = await database;
    return await db.insert('pending_listings', {
      'title': listingData['title'],
      'description': listingData['description'],
      'category': listingData['category'],
      'type': listingData['type'],
      'location_lat': listingData['location_lat'],
      'location_lng': listingData['location_lng'],
      'location_name': listingData['location_name'],
      'image_base64': listingData['image_base64'],
      'payload': jsonEncode(listingData),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingListings() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query('pending_listings', orderBy: 'created_at ASC');
  }

  Future<void> deletePendingListing(int id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('pending_listings', where: 'id = ?', whereArgs: [id]);
  }
}
