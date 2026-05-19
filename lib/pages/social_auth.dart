import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialAuth {
  static Future<UserCredential?> loginGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  static Future<UserCredential?> loginFacebook() async {
    final result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success) return null;
    final credential =
        FacebookAuthProvider.credential(result.accessToken!.tokenString);
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
