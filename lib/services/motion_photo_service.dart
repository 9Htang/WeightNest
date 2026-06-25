import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for detecting and extracting Android motion photos (实况照片).
///
/// Android motion photos (Samsung, Google Pixel) are JPEG files with an
/// embedded MP4 video segment. The platform channel detects the presence
/// of the embedded video and extracts it to a standalone .mp4 file.
class MotionPhotoService {
  static const _channel = MethodChannel('com.weightnest/file_helper');

  /// Returns the path to the extracted video file, or `null` if the given
  /// JPEG is not a motion photo or extraction failed.
  static Future<String?> extractVideo(String jpegPath) async {
    try {
      final result =
          await _channel.invokeMethod<String>('extractMotionVideo', jpegPath);
      return result;
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint('[MotionPhoto] Extract video failed for $jpegPath: $e');
      return null;
    }
  }
}
