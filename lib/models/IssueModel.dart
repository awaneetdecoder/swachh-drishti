// lib/models/issue_model.dart
//this file equivalent of your Java Issue entity.it send the data form the issue entity to the front end in a structured way. It is used to parse the JSON response from the backend API into a Dart object that can be easily used in the Flutter app.
class IssueModel {
  final int id;
  final double latitude;
  final double longitude;
  final String address;
  final String imageUrl;
  final String issueType;
  final String severity;
  final int urgencyScore;
  final String responsibleDepartment;
  final String citizenAdvisory;
  final String description;
  final String status;
  final int upvoteCount;
  final String createdAt;

  IssueModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.imageUrl,
    required this.issueType,
    required this.severity,
    required this.urgencyScore,
    required this.responsibleDepartment,
    required this.citizenAdvisory,
    required this.description,
    required this.status,
    required this.upvoteCount,
    required this.createdAt,
  });

  // WHY fromJson factory:
  // When your backend sends HTTP response, it's a raw String
  // jsonDecode() turns that String into Map<String, dynamic>
  // fromJson() turns that Map into a typed Dart object
  // You want typed objects (not Maps) because:
  // - Type safety: issue.latitude is a double, not dynamic
  // - Autocomplete works in your IDE
  // - Null safety is explicit
  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] ?? 'No address',
      imageUrl: json['imageUrl'] ?? '',
      issueType: json['issueType'] ?? 'OTHER',
      severity: json['severity'] ?? 'MEDIUM',
      urgencyScore: json['urgencyScore'] ?? 5,
      responsibleDepartment: json['responsibleDepartment'] ?? 'MUNICIPAL_CORPORATION',
      citizenAdvisory: json['citizenAdvisory'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'REPORTED',
      upvoteCount: json['upvoteCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }

  // Helper for UI — converts "BROKEN_LIGHT" to "Broken Light"
  String get displayIssueType => issueType
      .split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  // Helper for color coding by severity
  // Returns a color description your UI can use
  String get severityColor {
    switch (severity) {
      case 'CRITICAL': return 'red';
      case 'HIGH': return 'orange';
      case 'MEDIUM': return 'yellow';
      default: return 'green';
    }
  }
}