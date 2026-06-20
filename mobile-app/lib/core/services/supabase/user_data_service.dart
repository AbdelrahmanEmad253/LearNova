import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDataService {
  final SupabaseClient _client;
  const UserDataService(this._client);

  // Fetch the current user's row from public.users
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _client.from('users').select().eq('id', user.id).maybeSingle().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[UserDataService] fetchCurrentUser error: $e');
      return null;
    }
  }

  // Update full_name in users table
  Future<bool> updateFullName(String name) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    try {
      await _client.from('users').update({'full_name': name.trim()}).eq('id', user.id);
      return true;
    } catch (e) {
      debugPrint('[UserDataService] updateFullName error: $e');
      return false;
    }
  }

  // Update avatar_url in users table
  Future<bool> updateAvatarUrl(String url) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    try {
      await _client.from('users').update({'avatar_url': url}).eq('id', user.id);
      return true;
    } catch (e) {
      debugPrint('[UserDataService] updateAvatarUrl error: $e');
      return false;
    }
  }

  // Upload custom avatar image to Supabase Storage, return public URL
  Future<String?> uploadAvatar(Uint8List bytes, String fileExtension) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final path = '${user.id}/avatar.$fileExtension';
    await _client.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: 'image/$fileExtension'),
    );
    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    // Add cache buster to avoid CDN stale content
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  // Upload avatar and save URL to users table in one call
  Future<String?> uploadAndSaveAvatar(Uint8List bytes, String fileExtension) async {
    final url = await uploadAvatar(bytes, fileExtension);
    if (url != null) {
      await updateAvatarUrl(url);
    }
    return url;
  }

  // Save a prefab avatar filename (e.g. 'avatar3.svg') to users.avatar_url
  Future<bool> savePrefabAvatar(String fileName) async {
    return updateAvatarUrl(fileName);
  }
}
