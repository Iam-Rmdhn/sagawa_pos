import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://kdqfwxltbnxmfobehvbk.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkcWZ3eGx0Ym54bWZvYmVodmJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMDAyMTksImV4cCI6MjA3NzY3NjIxOX0.gsi1vd5QU1o9r60LvzWvOEpLwBzVg4kj1zk_JZuuno0',
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Upload image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadProductImage(File imageFile) async {
    try {
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'product_$timestamp$extension';

      // Upload to bucket
      await client.storage.from('product_image').upload(fileName, imageFile);

      // Get public URL
      final publicUrl = client.storage
          .from('product_image')
          .getPublicUrl(fileName);

      print('✅ Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Supabase Storage
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;

      await client.storage.from('product_image').remove([fileName]);

      print('✅ Image deleted successfully: $fileName');
    } catch (e) {
      print('❌ Error deleting image: $e');
      // Don't throw error, just log it
      // Deletion failure shouldn't block other operations
    }
  }

  /// Update image - delete old and upload new
  Future<String> updateProductImage(
    String? oldImageUrl,
    File newImageFile,
  ) async {
    // Upload new image first
    final newImageUrl = await uploadProductImage(newImageFile);

    // Delete old image if exists
    if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
      try {
        await deleteProductImage(oldImageUrl);
      } catch (e) {
        print('⚠️ Warning: Could not delete old image: $e');
        // Continue even if deletion fails
      }
    }

    return newImageUrl;
  }

  /// Check if bucket exists and is accessible
  Future<bool> testConnection() async {
    try {
      final buckets = await client.storage.listBuckets();
      final hasProductBucket = buckets.any((b) => b.name == 'product_image');
      print(
        '✅ Supabase connection test: ${hasProductBucket ? "SUCCESS" : "Bucket not found"}',
      );
      return hasProductBucket;
    } catch (e) {
      print('❌ Supabase connection test failed: $e');
      return false;
    }
  }
}
