class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.parentId,
    required this.name,
    this.avatarKey,
    this.birthYear,
    this.gender,
  });

  final String id;
  final String parentId;
  final String name;
  final String? avatarKey;
  final int? birthYear;
  final String? gender;

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String,
      parentId: json['parent_id'] as String,
      name: json['name'] as String,
      avatarKey: json['avatar_key'] as String?,
      birthYear: json['birth_year'] as int?,
      gender: json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'avatar_key': avatarKey,
      'birth_year': birthYear,
      'gender': gender,
    };
  }
}
