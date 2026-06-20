import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:learnova/features/content/domain/repositories/audio_playback_repository.dart';

class AudioStreamParams {
  final String url;
  final Map<String, String>? headers;
  const AudioStreamParams(this.url, [this.headers]);
}

/// Real audio playback implementation using `just_audio`.
///
/// Wraps [AudioPlayer] and exposes position/playing/completion streams
/// alongside the existing pure utility methods.
class AudioPlaybackRepositoryImpl implements AudioPlaybackRepository {
  AudioPlayer? _player;

  AudioPlayer get _audio {
    _player ??= AudioPlayer();
    return _player!;
  }

  // ── Real player methods ──

  @override
  Future<Duration?> load(String url) async {
    try {
      final AudioStreamParams streamParams = await _transformUrlAsync(url);
      final duration = await _audio.setUrl(
        streamParams.url,
        headers: streamParams.headers,
      );
      return duration;
    } catch (e) {
      return null;
    }
  }

  /// Transforms special URLs (like Google Drive or YouTube) into direct streamable links and required headers.
  Future<AudioStreamParams> _transformUrlAsync(String url) async {
    String workingUrl = url.trim();

    // 1. Google Drive Transformation
    // Convert: https://drive.google.com/file/d/FILE_ID/view
    // To: https://docs.google.com/uc?export=download&id=FILE_ID
    if (workingUrl.contains('drive.google.com')) {
      final regExp = RegExp(r'\/d\/([^\/]+)');
      final match = regExp.firstMatch(workingUrl);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        final downloadUrl = 'https://docs.google.com/uc?export=download&id=$fileId';
        
        try {
          String currentUrl = downloadUrl;
          Map<String, String> headers = {};
          final client = http.Client();
          
          try {
            for (int i = 0; i < 5; i++) {
              final request = http.Request('GET', Uri.parse(currentUrl))..followRedirects = false;
              request.headers.addAll(headers);
              
              final response = await client.send(request);
              
              if (response.statusCode >= 300 && response.statusCode < 400) {
                final location = response.headers['location'];
                if (location == null) break;
                
                String nextUrl = location;
                if (nextUrl.startsWith('/')) {
                  final uri = Uri.parse(currentUrl);
                  nextUrl = '${uri.scheme}://${uri.host}$nextUrl';
                }
                currentUrl = nextUrl;
                
                final setCookie = response.headers['set-cookie'];
                if (setCookie != null) {
                  headers['Cookie'] = setCookie.split(';').first;
                }
              } else if (response.statusCode == 200) {
                final contentType = response.headers['content-type'] ?? '';
                if (contentType.contains('text/html')) {
                  // It returned the HTML virus warning page directly!
                  final bodyString = await response.stream.bytesToString();
                  
                  // Try to find the download form and extract its action and hidden inputs
                  if (bodyString.contains('download-form')) {
                    final actionMatch = RegExp(r'action="([^"]+)"').firstMatch(bodyString);
                    final action = actionMatch?.group(1) ?? 'https://drive.usercontent.google.com/download';
                    
                    final inputsRegExp = RegExp(r'<input[^>]+type="hidden"[^>]+name="([^"]+)"[^>]+value="([^"]*)"');
                    final matches = inputsRegExp.allMatches(bodyString);
                    
                    String query = '';
                    for (final match in matches) {
                      final name = match.group(1)!;
                      final value = match.group(2)!;
                      if (query.isNotEmpty) query += '&';
                      query += '$name=$value';
                    }
                    
                    if (query.isNotEmpty) {
                      currentUrl = '$action?$query';
                      continue;
                    }
                  }
                  
                  // Fallback to old simple regex if form not found
                  final confirmRegExp = RegExp(r'confirm=([a-zA-Z0-9_-]+)');
                  final confirmMatch = confirmRegExp.firstMatch(bodyString);
                  if (confirmMatch != null && confirmMatch.groupCount >= 1) {
                    final confirmToken = confirmMatch.group(1);
                    currentUrl = '$downloadUrl&confirm=$confirmToken';
                    continue;
                  }
                  break;
                } else {
                  // We reached the direct media URL (not HTML)!
                  // Return this URL without headers since the Google content server uses token-based URL auth.
                  return AudioStreamParams(currentUrl);
                }
              } else {
                break;
              }
            }
          } finally {
            client.close();
          }
        } catch (_) {
          // If the bypass fetch fails, fallback to the standard URL
        }

        return AudioStreamParams(downloadUrl);
      }
    }

    return AudioStreamParams(workingUrl);
  }

  @override
  Future<void> play() async {
    await _audio.play();
  }

  @override
  Future<void> pause() async {
    await _audio.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audio.seek(position);
  }

  @override
  Stream<Duration> get positionStream => _audio.positionStream;

  @override
  Stream<bool> get playingStream => _audio.playingStream;

  @override
  Stream<void> get completionStream {
    return _audio.playerStateStream
        .where((state) =>
            state.processingState == ProcessingState.completed)
        .map((_) {});
  }

  @override
  Future<void> disposePlayer() async {
    await _player?.dispose();
    _player = null;
  }

  // ── Pure utility methods (unchanged) ──

  @override
  Duration? parseDuration(String rawDuration) {
    final List<String> parts = rawDuration.trim().split(':');

    if (parts.length == 2) {
      final int? minutes = int.tryParse(parts[0]);
      final int? seconds = int.tryParse(parts[1]);
      if (minutes == null || seconds == null) {
        return null;
      }
      return Duration(minutes: minutes, seconds: seconds);
    }

    if (parts.length == 3) {
      final int? hours = int.tryParse(parts[0]);
      final int? minutes = int.tryParse(parts[1]);
      final int? seconds = int.tryParse(parts[2]);
      if (hours == null || minutes == null || seconds == null) {
        return null;
      }
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }

    return null;
  }

  @override
  Duration clampPosition({
    required Duration position,
    required Duration totalDuration,
  }) {
    if (position < Duration.zero) {
      return Duration.zero;
    }
    if (position > totalDuration) {
      return totalDuration;
    }
    return position;
  }

  @override
  Duration positionFromProgress({
    required double progress,
    required Duration totalDuration,
  }) {
    final double normalizedProgress = progress.clamp(0.0, 1.0);
    return Duration(
      milliseconds: (totalDuration.inMilliseconds * normalizedProgress).round(),
    );
  }

  @override
  String formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
