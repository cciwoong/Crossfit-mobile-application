import 'package:final_project/auth/login_or_register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../pages/home_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // When the user is logged in
          if (snapshot.hasData){
            return const HomePage();
          }
          // When the user is not logged in
          else {
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}
