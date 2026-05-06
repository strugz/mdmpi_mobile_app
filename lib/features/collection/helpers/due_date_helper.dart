enum DueBucket {
  all,
  le30,
  b31_60,
  b61_90,
  b91_120,
  ge121,
}

class DueDateHelper {
  static const Map<DueBucket, String> labels = {
    DueBucket.le30: '<=30',
    DueBucket.b31_60: '31-60',
    DueBucket.b61_90: '61-90',
    DueBucket.b91_120: '91-120',
    DueBucket.ge121: '>=121',
  };

  static DueBucket? fromLabel(String label) {
    if (label == 'All') return DueBucket.all;
    return labels.entries.firstWhere(
      (e) => e.value == label,
      orElse: () => MapEntry(DueBucket.all, 'All'),
    ).key;
  }

  static String labelFor(DueBucket bucket) => labels[bucket] ?? 'All';

  static bool inBucket(int daysPast, DueBucket bucket) {
    if (bucket == DueBucket.all) return true;
    switch (bucket) {
      case DueBucket.le30:
        return daysPast > 0 && daysPast <= 30;
      case DueBucket.b31_60:
        return daysPast >= 31 && daysPast <= 60;
      case DueBucket.b61_90:
        return daysPast >= 61 && daysPast <= 90;
      case DueBucket.b91_120:
        return daysPast >= 91 && daysPast <= 120;
      case DueBucket.ge121:
        return daysPast >= 121;
      default:
        return false;
    }
  }

  /// Convenience: list of labels including 'All' as first item
  static List<String> get labelsWithAll => ['All', ...labels.values];
}


