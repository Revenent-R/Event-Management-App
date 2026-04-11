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
  String selectedValue = "IIIT Kottayam";

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController organizationController = TextEditingController();

  final FirebaseFirestore firebase = FirebaseFirestore.instance;

  bool isLoading = false;

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

  String formatError(String code) {
    if (!code.contains('-')) return code;
    var d = code.indexOf('-');
    return "${code[0].toUpperCase()}${code.substring(1, d)} ${code[d + 1].toUpperCase()}${code.substring(d + 2)}";
  }

  Widget popupDialog({required String text, required bool status}) {
    return Dialog(
      backgroundColor: const Color(0xF0FAEFEF),
      elevation: 0,
      child: Container(
        width: 240,
        height: 220,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
        child: Column(
          children: [
            const SizedBox(height: 48),
            Icon(
              status ? Icons.check_circle : Icons.error,
              size: 64,
              color: status ? const Color(0xFF50C878) : const Color(0xFFA52A2A),
            ),
            const SizedBox(height: 18),
            Text(
              text,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> callAPI() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await http.post(
      Uri.parse("https://event-manager-backend-ya4p.onrender.com/login"),
      headers: {
        "Content-Type": "application/json",
      },
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
      showDialog(
        context: context,
        builder: (_) => popupDialog(text: "Fill all fields", status: false),
      );
      return;
    }

    if (!verifyEmail()) {
      showDialog(
        context: context,
        builder: (_) => popupDialog(text: "Invalid email domain", status: false),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

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

      showDialog(
        context: context,
        builder: (_) => popupDialog(text: "You’re all set!", status: true),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomepageState()),
              (route) => false,
        );
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => popupDialog(text: formatError(e.code), status: false),
      );
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) =>
            popupDialog(text: e.toString().replaceAll("Exception: ", ""), status: false),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  static const Color primary = Color(0xFF8B5CF6);
  static const Color bgLight = Color(0xFFF5F3FF);
  static const Color cardBg = Colors.white;
  static const Color textMain = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEDE9FE),
                    Color(0xFFFFFFFF),
                    Color(0xFFF3E8FF),
                  ],
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Register Organization",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Join the college event management community",
                        style: TextStyle(
                          fontSize: 14,
                          color: textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _inputField(
                        icon: Icons.person,
                        label: "Username",
                        hint: "Enter your username",
                        controller: emailController,
                      ),
                      const SizedBox(height: 20),
                      _inputField(
                        icon: Icons.lock,
                        label: "Password",
                        hint: "Create a password",
                        controller: passwordController,
                        obscure: true,
                        suffixIcon: Icons.visibility_off,
                      ),
                      const SizedBox(height: 20),
                      _inputField(
                        icon: Icons.account_balance,
                        label: "Organization Name",
                        hint: "Club Name",
                        controller: organizationController,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9F9AE6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: primary.withValues(alpha: 0.35),
                          ),
                          onPressed: isLoading ? null : () => register(context),
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Register Yourself",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(
                              fontSize: 14,
                              color: textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AdminState()),
                              );
                            },
                            child: const Text(
                              "Log in",
                              style: TextStyle(
                                fontSize: 14,
                                color: primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: MediaQuery.of(context).size.width / 2 - 60,
              child: Container(
                width: 120,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _inputField({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: primary),
            ),
          ),
        ),
      ],
    );
  }
}