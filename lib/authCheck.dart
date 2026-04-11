import 'package:flutter/cupertino.dart';
import 'package:event_manager/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:event_manager/appLaunch.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasData && snapshot.data != null) {
          return HomepageState();
        }

        return const MyHomepage();
      },
    );
  }
}