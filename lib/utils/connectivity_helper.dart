import 'dart:io';

/// Centralized connectivity checking
class ConnectivityHelper {
  /// Check if device has internet connection
  /// Tries Google.com as a reliable check
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
