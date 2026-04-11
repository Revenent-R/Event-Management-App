import 'dart:convert';

import 'package:event_manager/user_login.dart';
import 'package:flutter/material.dart';
import 'package:event_manager/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class UserRegistrationState extends StatefulWidget {
  const UserRegistrationState({super.key});

  @override
  State<UserRegistrationState> createState() => UserRegistration();
}

class UserRegistration extends State<UserRegistrationState> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  static const Color primary = Color(0xFF9F9AE6);
  static const Color textMain = Color(0xFF334155);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool verifyEmail() {
    return emailController.text.trim().endsWith("@iiitkottayam.ac.in");
  }

  Future<void> callAPI() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await http.post(
      Uri.parse("https://event-manager-backend-ya4p.onrender.com/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'uid': user.uid,
        'role': 'user',
      }),
    );

    await user.getIdTokenResult(true);
  }

  void showSnack(String text, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor:
          success ? primary : const Color(0xFFEF4444),
        ),
      );
  }

  Future<void> register(BuildContext context) async {
    if (isLoading) return;

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showSnack("Fill all fields", false);
      return;
    }

    if (!verifyEmail()) {
      showSnack("Invalid email domain", false);
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await callAPI();

      if (!mounted) return;

      showSnack("You’re all set!", true);

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomepageState()),
              (route) => false,
        );
      });
    } catch (e) {
      showSnack("Error occurred", false);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5F3FF),
              Color(0xFFEDE9FE),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school,
                        size: 48, color: primary),
                    const SizedBox(height: 12),

                    const Text(
                      "Register As User",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        prefixIcon:
                        const Icon(Icons.person),
                        labelText: "Username",
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      obscureText: true,
                      controller: passwordController,
                      decoration: InputDecoration(
                        prefixIcon:
                        const Icon(Icons.lock),
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                        ),
                        onPressed:
                        isLoading ? null : () => register(context),
                        child: isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.white)
                            : const Text("Register"),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const UserLoginState()),
                        );
                      },
                      child: const Text(
                          "Already have an account? Login"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}