import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _googleSignIn.initialize(
        clientId: '125135700407-a1330gt4rtr3envqm8tpmtl1sl8aodom.apps.googleusercontent.com',          // web client ID if web platform
        serverClientId: '125135700407-f296b3mksep3bfon2125ka3kkroukmhn.apps.googleusercontent.com',    // optional, for backend token exchange
      );
    } catch (e) {
      print('GoogleSignIn initialization error: $e');
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.authenticate();
      if (account == null) {
        print('User cancelled sign-in');
        return null;
      }

      // If you only need the ID token (for passing to your backend):
      final auth = await account.authentication;
      final idToken = auth.idToken;
      print('ID Token: ${idToken?.substring(0, 20)}...');

      return idToken;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('User signed out');
    } catch (e) {
      print('Google Sign-Out error: $e');
    }
  }

  Future<String?> trySilentSignIn() async {
    try {
      final account = await _googleSignIn.attemptLightweightAuthentication();
      if (account == null) return null;
      final auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      print('Silent sign-in failed: $e');
      return null;
    }
  }

  
}