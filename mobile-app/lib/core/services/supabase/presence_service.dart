import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService {
  final SupabaseClient _client;
  Timer? _timer;

  PresenceService(this._client);

  void start() {
    stop(); // Cancel any existing timer
    
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      final user = _client.auth.currentUser;
      if (user != null) {
        try {
          await _client
              .from('users')
              .update({'last_seen_at': DateTime.now().toIso8601String()})
              .eq('id', user.id);
        } catch (e) {
          debugPrint('[PresenceService] update presence error: $e');
        }
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
