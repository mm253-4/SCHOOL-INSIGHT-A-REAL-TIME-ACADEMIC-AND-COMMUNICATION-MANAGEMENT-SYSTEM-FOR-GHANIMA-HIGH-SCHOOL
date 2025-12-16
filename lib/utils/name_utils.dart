String formatTeacherTitle(String name, String gender) {
  final trimmedName = name.trim();
  final lowerName = trimmedName.toLowerCase();
  // Avoid double prefix if already formatted
  if (lowerName.startsWith('mr.') ||
      lowerName.startsWith('mrs.') ||
      lowerName.startsWith('ms.')) {
    return trimmedName;
  }

  final normalizedGender = gender.trim().toLowerCase();
  if (normalizedGender.startsWith('m')) {
    return 'Mr. $trimmedName';
  }
  if (normalizedGender.startsWith('f')) {
    return 'Mrs. $trimmedName';
  }
  return trimmedName;
}


