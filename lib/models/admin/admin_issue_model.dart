class AdminIssueModel {
  final int id;
  final int userId;
  final String userType;
  final String type; // 'issue' or 'report'
  final String title;
  final String description;
  final String status; // 'pending', 'in_progress', 'resolved'
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional info
  final String? userName;
  final String? userEmail;

  AdminIssueModel({
    required this.id,
    required this.userId,
    required this.userType,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    this.adminResponse,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userEmail,
  });

  factory AdminIssueModel.fromJson(Map<String, dynamic> json) {
    return AdminIssueModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userType: json['user_type'] ?? '',
      type: json['type'] ?? 'issue',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      adminResponse: json['admin_response'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      userName: json['user_name'],
      userEmail: json['user_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_type': userType,
      'type': type,
      'title': title,
      'description': description,
      'status': status,
      'admin_response': adminResponse,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_name': userName,
      'user_email': userEmail,
    };
  }
}
