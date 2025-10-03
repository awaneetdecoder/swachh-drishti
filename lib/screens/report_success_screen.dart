// lib/screens/report_success_screen.dart
import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../widget/app_logo.dart';

class ReportSuccessScreen extends StatelessWidget {
  final ReportModel report;

  const ReportSuccessScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppLogo(radius: 50, iconSize: 50),
            const SizedBox(height: 24),
            Text(
              'Reported Successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thank you for making our city cleaner. Your report has been submitted and is now pending review.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Submitted Information:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 20),
                    _buildInfoRow('Location Details:', report.locationDetails),
                    const SizedBox(height: 12),
                    _buildInfoRow('Problem:', report.problemDescription),
                    const SizedBox(height: 12),
                    _buildInfoRow('Status:', report.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Pop back to the root of the reporter tab
                Navigator.of(context).pop();
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(data, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}