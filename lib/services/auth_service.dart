import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      print("❌ Auth Error: $e");
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On web, signInSilently should be used after user clicks the rendered button
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
        if (googleUser == null) return null;
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null; // User canceled
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      print('❌ Sign Out Error: '
          '[31m'
          '[0m'
          '[1m'
          '[0m'
          '[4m'
          '[0m'
          '[7m'
          '[0m'
          '[3m'
          '[0m'
          '[9m'
          '[0m'
          '[5m'
          '[0m'
          '[2m'
          '[0m'
          '[8m'
          '[0m'
          '[6m'
          '[0m'
          '[10m'
          '[0m'
          '[11m'
          '[0m'
          '[12m'
          '[0m'
          '[13m'
          '[0m'
          '[14m'
          '[0m'
          '[15m'
          '[0m'
          '[16m'
          '[0m'
          '[17m'
          '[0m'
          '[18m'
          '[0m'
          '[19m'
          '[0m'
          '[20m'
          '[0m'
          '[21m'
          '[0m'
          '[22m'
          '[0m'
          '[23m'
          '[0m'
          '[24m'
          '[0m'
          '[25m'
          '[0m'
          '[26m'
          '[0m'
          '[27m'
          '[0m'
          '[28m'
          '[0m'
          '[29m'
          '[0m'
          '[30m'
          '[0m'
          '[31m'
          '[0m'
          '[32m'
          '[0m'
          '[33m'
          '[0m'
          '[34m'
          '[0m'
          '[35m'
          '[0m'
          '[36m'
          '[0m'
          '[37m'
          '[0m'
          '[38m'
          '[0m'
          '[39m'
          '[0m'
          '[40m'
          '[0m'
          '[41m'
          '[0m'
          '[42m'
          '[0m'
          '[43m'
          '[0m'
          '[44m'
          '[0m'
          '[45m'
          '[0m'
          '[46m'
          '[0m'
          '[47m'
          '[0m'
          '[48m'
          '[0m'
          '[49m'
          '[0m'
          '[50m'
          '[0m'
          '[51m'
          '[0m'
          '[52m'
          '[0m'
          '[53m'
          '[0m'
          '[54m'
          '[0m'
          '[55m'
          '[0m'
          '[56m'
          '[0m'
          '[57m'
          '[0m'
          '[58m'
          '[0m'
          '[59m'
          '[0m'
          '[60m'
          '[0m'
          '[61m'
          '[0m'
          '[62m'
          '[0m'
          '[63m'
          '[0m'
          '[64m'
          '[0m'
          '[65m'
          '[0m'
          '[66m'
          '[0m'
          '[67m'
          '[0m'
          '[68m'
          '[0m'
          '[69m'
          '[0m'
          '[70m'
          '[0m'
          '[71m'
          '[0m'
          '[72m'
          '[0m'
          '[73m'
          '[0m'
          '[74m'
          '[0m'
          '[75m'
          '[0m'
          '[76m'
          '[0m'
          '[77m'
          '[0m'
          '[78m'
          '[0m'
          '[79m'
          '[0m'
          '[80m'
          '[0m'
          '[81m'
          '[0m'
          '[82m'
          '[0m'
          '[83m'
          '[0m'
          '[84m'
          '[0m'
          '[85m'
          '[0m'
          '[86m'
          '[0m'
          '[87m'
          '[0m'
          '[88m'
          '[0m'
          '[89m'
          '[0m'
          '[90m'
          '[0m'
          '[91m'
          '[0m'
          '[92m'
          '[0m'
          '[93m'
          '[0m'
          '[94m'
          '[0m'
          '[95m'
          '[0m'
          '[96m'
          '[0m'
          '[97m'
          '[0m'
          '[98m'
          '[0m'
          '[99m'
          '\u001b[0m');
    }
  }
}
