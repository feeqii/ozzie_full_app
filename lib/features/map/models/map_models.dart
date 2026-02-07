class MapState {
  const MapState({
    required this.childId,
    required this.activeCount,
    required this.slotsRemaining,
    required this.galaxies,
  });

  final String childId;
  final int activeCount;
  final int slotsRemaining;
  final List<GalaxyNode> galaxies;

  factory MapState.fromJson(Map<String, dynamic> json) {
    return MapState(
      childId: json['child_id'] as String? ?? '',
      activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
      slotsRemaining: (json['slots_remaining'] as num?)?.toInt() ?? 0,
      galaxies: (json['galaxies'] as List<dynamic>? ?? const [])
          .map((item) => GalaxyNode.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  SurahNode? findSurah(int surahId) {
    for (final galaxy in galaxies) {
      for (final surah in galaxy.surahs) {
        if (surah.id == surahId) return surah;
      }
    }
    return null;
  }
}

class GalaxyNode {
  const GalaxyNode({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.orderIndex,
    required this.unlocked,
    required this.completed,
    required this.surahs,
  });

  final int id;
  final String nameEn;
  final String? nameAr;
  final int orderIndex;
  final bool unlocked;
  final bool completed;
  final List<SurahNode> surahs;

  factory GalaxyNode.fromJson(Map<String, dynamic> json) {
    return GalaxyNode(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nameEn: json['name_en'] as String? ?? '',
      nameAr: json['name_ar'] as String?,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      unlocked: json['unlocked'] == true,
      completed: json['completed'] == true,
      surahs: (json['surahs'] as List<dynamic>? ?? const [])
          .map((item) => SurahNode.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum SurahStatus {
  notStarted,
  active,
  completed,
}

SurahStatus surahStatusFromApi(String? raw) {
  switch (raw) {
    case 'ACTIVE':
      return SurahStatus.active;
    case 'COMPLETED':
      return SurahStatus.completed;
    case 'NOT_STARTED':
    default:
      return SurahStatus.notStarted;
  }
}

class SurahNode {
  const SurahNode({
    required this.id,
    required this.orderIndex,
    required this.name,
    required this.translation,
    required this.ayahCount,
    required this.status,
    required this.activeSlot,
    required this.locked,
    required this.lockReason,
    required this.playable,
  });

  final int id;
  final int orderIndex;
  final String name;
  final String translation;
  final int? ayahCount;
  final SurahStatus status;
  final int? activeSlot;
  final bool locked;
  final String? lockReason;
  final bool playable;

  factory SurahNode.fromJson(Map<String, dynamic> json) {
    return SurahNode(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      ayahCount: (json['ayah_count'] as num?)?.toInt(),
      status: surahStatusFromApi(json['status'] as String?),
      activeSlot: (json['active_slot'] as num?)?.toInt(),
      locked: json['locked'] == true,
      lockReason: json['lock_reason'] as String?,
      playable: json['playable'] == true,
    );
  }

  bool get isActive => status == SurahStatus.active;
  bool get isCompleted => status == SurahStatus.completed;
}

