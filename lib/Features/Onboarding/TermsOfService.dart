import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsOfService extends StatefulWidget {
  const TermsOfService({super.key});

  @override
  State<TermsOfService> createState() => _TermsOfServiceState();
}

class _TermsOfServiceState extends State<TermsOfService> {
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms of Service"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: const Text(
                  "By using this app, you agree to our Terms of Service and Privacy Policy.\n\n"
                      "These terms govern your use of our app and services. Please read them carefully. "
                      "If you do not agree, you may not use this application.\n\n"
                      "[Insert your actual terms and privacy policy here.]",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: accepted,
                  onChanged: (val) {
                    setState(() {
                      accepted = val ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text("I agree to the Terms of Service and Privacy Policy"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: accepted
                  ? () => Get.back(result: true)
                  : () => Get.snackbar(
                "Agreement Required",
                "You must agree to continue.",
                snackPosition: SnackPosition.BOTTOM,
              ),
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
