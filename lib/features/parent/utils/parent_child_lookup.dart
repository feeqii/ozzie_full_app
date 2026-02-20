import '../../child/models/child_profile.dart';

ChildProfile? findChildById(List<ChildProfile> children, String childId) {
  for (final child in children) {
    if (child.id == childId) {
      return child;
    }
  }
  return null;
}
