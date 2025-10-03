import 'package:flutter/material.dart';
import '../models/report_model.dart';

class ActivityListItem extends StatelessWidget {
  final ReportModel report;

  const ActivityListItem({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (report.status.contains('Resolved')) {
      statusColor = Colors.green;
    } else if (report.status.contains('Rejected')) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(report.locationDetails, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(report.problemDescription, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(report.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(report.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
