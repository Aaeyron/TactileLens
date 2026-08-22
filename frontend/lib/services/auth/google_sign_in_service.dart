import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInServiceException implements Exception {
  const GoogleSignInServiceException(
    this.message, {
    this.code,
    this.description,
    this.details,
  });

  final String message;
  final GoogleSignInExceptionCode? code;
  final String? description;
  final Object? details;

  bool get wasCanceled {
    return code == GoogleSignInExceptionCode.canceled;
  }

  @override
  String toString() {
    return message;
  }
}

abstract final class GoogleSignInService {
  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static Future<void>? _initialization;

  static Future<void> initialize() async {
    final String serverClientId = _serverClientId.trim();

    if (serverClientId.isEmpty) {
      throw const GoogleSignInServiceException(
        'Google authentication is not configured.',
      );
    }

    _initialization ??= _googleSignIn.initialize(
      serverClientId: serverClientId,
    );

    try {
      await _initialization;
    } on GoogleSignInException catch (error) {
      _initialization = null;

      _logGoogleError(stage: 'initialization', error: error);

      throw _convertGoogleError(error);
    } catch (error, stackTrace) {
      _initialization = null;

      debugPrint('Google initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      throw GoogleSignInServiceException(
        'Google authentication could not be initialized.',
        details: error,
      );
    }
  }

  static Future<String> authenticate() async {
    await initialize();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const GoogleSignInServiceException(
        'Google authentication is not supported on this device.',
      );
    }

    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      final String? idToken = account.authentication.idToken;

      if (idToken == null || idToken.trim().isEmpty) {
        throw const GoogleSignInServiceException(
          'Google did not return an identity token.',
        );
      }

      return idToken.trim();
    } on GoogleSignInServiceException {
      rethrow;
    } on GoogleSignInException catch (error) {
      _logGoogleError(stage: 'authentication', error: error);

      throw _convertGoogleError(error);
    } catch (error, stackTrace) {
      debugPrint(
        'Unexpected Google authentication error: '
        '$error',
      );
      debugPrintStack(stackTrace: stackTrace);

      throw GoogleSignInServiceException(
        'Unable to continue with Google.',
        details: error,
      );
    }
  }

  static GoogleSignInServiceException _convertGoogleError(
    GoogleSignInException error,
  ) {
    final String description = error.description?.trim() ?? '';

    final String message;

    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        message = description.isNotEmpty
            ? 'Google sign-in was canceled: '
                  '$description'
            : 'Google sign-in was canceled.';

      case GoogleSignInExceptionCode.interrupted:
        message = description.isNotEmpty
            ? 'Google sign-in was interrupted: '
                  '$description'
            : 'Google sign-in was interrupted. '
                  'Please try again.';

      case GoogleSignInExceptionCode.clientConfigurationError:
        message = description.isNotEmpty
            ? 'Google OAuth configuration error: '
                  '$description'
            : 'Google OAuth is not configured '
                  'correctly for this app.';

      case GoogleSignInExceptionCode.providerConfigurationError:
        message = description.isNotEmpty
            ? 'Google provider configuration error: '
                  '$description'
            : 'Google authentication is unavailable '
                  'on this device.';

      case GoogleSignInExceptionCode.uiUnavailable:
        message = description.isNotEmpty
            ? 'Google sign-in could not open: '
                  '$description'
            : 'Google sign-in could not open on '
                  'this device.';

      default:
        message = description.isNotEmpty
            ? 'Unable to continue with Google: '
                  '$description'
            : 'Unable to continue with Google.';
    }

    return GoogleSignInServiceException(
      message,
      code: error.code,
      description: error.description,
      details: error.details,
    );
  }

  static void _logGoogleError({
    required String stage,
    required GoogleSignInException error,
  }) {
    debugPrint(
      'Google sign-in $stage error: '
      'code=${error.code}, '
      'description=${error.description}, '
      'details=${error.details}',
    );
  }

  static Future<void> signOut() async {
    await initialize();
    await _googleSignIn.signOut();
  }
}
