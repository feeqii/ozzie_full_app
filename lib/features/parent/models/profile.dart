class ParentProfile {
  const ParentProfile({
    required this.id,
    this.displayName,
    this.pinHash,
  });

  final String id;
  final String? displayName;
  final String? pinHash;

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      pinHash: json['pin_hash'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'pin_hash': pinHash,
    };
  }
}
