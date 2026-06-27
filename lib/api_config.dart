class ApiConfig {
  // WHY localhost for now:
  // Backend runs on your machine during development
  // After deployment, change this ONE line to your Render URL
  // Everything else updates automatically
  static const String _baseUrl = 'http://10.0.2.2:8080';
  // NOTE: 10.0.2.2 = Android emulator's way to reach your PC's localhost
  // For physical device: use your PC's local IP like 192.168.1.5:8080
  // For web: use http://localhost:8080

  // Auth endpoints
  static const String login   = '$_baseUrl/api/auth/login';
  static const String signup  = '$_baseUrl/api/auth/signup';
  static const String getMe   = '$_baseUrl/api/auth/me';

  // Old report endpoints (keep for backward compatibility)
  static const String myReports = '$_baseUrl/api/reports/myreports';

  // NEW issue endpoints
  static const String submitIssue = '$_baseUrl/api/issues';
  static const String allIssues   = '$_baseUrl/api/issues/all';
  static const String myIssues    = '$_baseUrl/api/issues/mine';

  // Dynamic endpoints — built at runtime with issue ID
  // Usage: '${ApiConfig.issueBase}/42/upvote'
  static const String issueBase = '$_baseUrl/api/issues';
}