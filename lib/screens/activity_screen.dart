import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/report_model.dart';
import '../services/secure_storage_service.dart';
import '../widget/activity_list_item.dart';

/// A screen that displays the logged-in user's report history.
///
/// This screen fetches reports from the backend and separates them into
/// "Pending" and "History" tabs for a clear user experience. It handles
/// loading, error, and empty states.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // A Future variable to hold the asynchronous operation of fetching reports.
  late Future<List<ReportModel>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    // When the screen first loads, immediately start fetching the user's reports.
    _reportsFuture = _fetchMyReports();
  }

  /// Fetches the logged-in user's report history from the backend.
  Future<List<ReportModel>> _fetchMyReports() async {
    try {
      // 1. Get the user's saved "ID card" (token) from secure storage.
      final token = await SecureStorageService.getToken();
      if (token == null || token.isEmpty) {
        // If the user is not logged in, we cannot fetch reports.
        throw Exception('User is not authenticated.');
      }

      // 2. Make a secure GET request to the backend for the user's reports.
      final response = await http.get(
        Uri.parse(ApiConfig.myReports),
        headers: {
          'Authorization': 'Bearer $token', // Include the token for authentication.
        },
      );

      if (response.statusCode == 200) {
        // 3. If the request is successful, parse the JSON data from the response.
        final List<dynamic> reportsJson = jsonDecode(response.body);

        // 4. Convert the raw JSON data into a list of structured ReportModel objects.
        return reportsJson.map((json) {
          return ReportModel(
            // The keys ('address', 'description', etc.) must match what the backend sends.
            locationDetails: json['address'] ?? 'No address provided',
            problemDescription: json['description'] ?? 'No description provided',
            status: json['status'] ?? 'Pending',
            date: json['createdAt']?.substring(0, 10) ?? 'N/A', // Format the date to YYYY-MM-DD
          );
        }).toList();
      } else {
        // If the server returns an error code (e.g., 401 Unauthorized, 500 Server Error).
        throw Exception('Failed to load reports from the server.');
      }
    } catch (e) {
      // If there's a network error or any other exception during the process.
      // Rethrow the exception to be caught by the FutureBuilder.
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          // The TabBar is placed in the AppBar for a clean look.
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TabBar(
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'History'),
                ],
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
              ),
            ],
          ),
        ),
        // A FutureBuilder is the professional way to handle UI that depends on asynchronous data.
        body: FutureBuilder<List<ReportModel>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            // Case 1: The data is still being fetched from the server.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Case 2: An error occurred during the fetch.
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                ),
              );
            }

            // Case 3: The data was fetched successfully, but the user has no reports.
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'You have not submitted any reports yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            // Case 4: Data is ready! Filter and display it.
            final allReports = snapshot.data!;
            final pendingReports = allReports.where((report) => report.status == 'Pending').toList();
            final historyReports = allReports.where((report) => report.status != 'Pending').toList();

            return TabBarView(
              children: [
                // --- Pending Tab ---
                _buildReportList(pendingReports, "No pending reports."),
                // --- History Tab ---
                _buildReportList(historyReports, "No resolved or rejected reports in your history."),
              ],
            );
          },
        ),
      ),
    );
  }

  /// A helper widget to build the list of reports for each tab.
  Widget _buildReportList(List<ReportModel> reports, String emptyMessage) {
    if (reports.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return ActivityListItem(report: reports[index]);
      },
    );
  }
}

