import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_manager/admin_login.dart';
import 'package:event_manager/homepage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AdminRegistrationState extends StatefulWidget {
  const AdminRegistrationState({super.key});

  @override
  State<AdminRegistrationState> createState() => AdminRegistration();
}

class AdminRegistration extends State<AdminRegistrationState> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController organizationController = TextEditingController();

  final FirebaseFirestore firebase = FirebaseFirestore.instance;

  bool isLoading = false;

  static const Color primary = Color(0xFF9F9AE6);
  static const Color textMain = Color(0xFF334155);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    organizationController.dispose();
    super.dispose();
  }

  bool verifyEmail() {
    return emailController.text.trim().endsWith("@iiitkottayam.ac.in");
  }

  Future<bool> verifyOrganization() async {
    final query = await firebase
        .collection('organizations')
        .where('club-name', isEqualTo: organizationController.text.trim())
        .limit(1)
        .get();

    return query.docs.isEmpty;
  }

  Future<void> addOrganization(String organizationName) async {
    await firebase.collection('organizations').add({
      'club-name': organizationName.trim()
    });
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

  Future<void> callAPI() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await http.post(
      Uri.parse("https://event-manager-backend-ya4p.onrender.com/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'uid': user.uid,
        'role': 'admin',
        'club-name': organizationController.text.trim()
      }),
    );

    await user.getIdTokenResult(true);
  }

  Future<void> register(BuildContext context) async {
    if (isLoading) return;

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        organizationController.text.isEmpty) {
      showSnack("Fill all fields", false);
      return;
    }

    if (!verifyEmail()) {
      showSnack("Invalid email domain", false);
      return;
    }

    setState(() => isLoading = true);

    try {
      if (!(await verifyOrganization())) {
        throw Exception("Club already exists");
      }

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await callAPI();
      await addOrganization(organizationController.text);

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
      showSnack(
          e.toString().replaceAll("Exception: ", ""), false);
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
                      "Register Organization",
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

                    const SizedBox(height: 16),

                    TextField(
                      controller: organizationController,
                      decoration: InputDecoration(
                        prefixIcon:
                        const Icon(Icons.account_balance),
                        labelText: "Organization",
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
                              builder: (_) => const AdminState()),
                        );
                      },
                      child: const Text("Already have an account? Login"),
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