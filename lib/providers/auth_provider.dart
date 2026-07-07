import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      state = user;
    });
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
