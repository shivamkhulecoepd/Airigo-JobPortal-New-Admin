// ─── Profile Data Model ───────────────────────────────────────────────────────
class ProfileData {
  String name;
  String title;
  String location;
  String avatarUrl;
  int level;
  int completionPercent;
  String bio;
  List<String> skills;
  double experienceYears;
  String? resumeFileName;
  String? email;
  String? phone;
  DateTime? dateOfBirth;
  String? qualification;
  DateTime? createdAt;

  ProfileData({
    required this.name,
    required this.title,
    required this.location,
    required this.avatarUrl,
    required this.level,
    required this.completionPercent,
    required this.bio,
    required this.skills,
    required this.experienceYears,
    this.resumeFileName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.qualification,
    this.createdAt,
  });
}