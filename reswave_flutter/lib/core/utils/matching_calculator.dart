import 'dart:math';

/// ResWave Transparent Arithmetic Scoring Engine
/// Implements Section 4.3 & Section 7. No blackbox AI.
class MatchingCalculator {
  static const Map<String, double> domainWeights = {
    'subjects': 0.30,
    'problems': 0.25,
    'workStyles': 0.20,
    'skills': 0.15,
    'goals': 0.10,
  };

  /// Calculates domain questionnaire score (Section 4.3)
  static Map<String, dynamic> scoreDomain({
    required Map<String, List<String>> userAnswers,
    required Map<String, dynamic> domainTaxonomy,
    String? topicInMind,
  }) {
    final answeredKeys = <String>[];
    for (final key in domainWeights.keys) {
      final list = userAnswers[key] ?? [];
      final valid = list.where((x) => x.toLowerCase() != 'not sure' && x.toLowerCase() != 'skip');
      if (valid.isNotEmpty) {
        answeredKeys.add(key);
      }
    }

    // Exploratory baseline if fewer than 2 answered
    if (answeredKeys.length < 2) {
      return {
        'score': 50.0,
        'fitBand': 'Explore',
        'reasons': ['Broad exploratory suggestion based on foundational research areas'],
      };
    }

    // Proportional redistribution of weights
    final baseWeightSum = answeredKeys.fold(0.0, (sum, key) => sum + domainWeights[key]!);
    final normalizedWeights = {
      for (var k in answeredKeys) k: domainWeights[k]! / baseWeightSum
    };

    double totalScore = 0.0;
    final reasons = <String>[];

    // Helper for set overlap
    double overlapRatio(List<String> userList, List<dynamic>? domainList) {
      if (domainList == null || domainList.isEmpty || userList.isEmpty) return 0.0;
      final uSet = userList.map((e) => e.trim().toLowerCase()).toSet();
      final dSet = domainList.map((e) => e.toString().trim().toLowerCase()).toSet();
      final intersection = uSet.intersection(dSet);
      return intersection.length / uSet.length;
    }

    if (answeredKeys.contains('subjects')) {
      final ratio = overlapRatio(userAnswers['subjects']!, domainTaxonomy['subjectTags']);
      totalScore += ratio * normalizedWeights['subjects']!;
      if (ratio > 0) reasons.add('Matches your selected subject interests');
    }

    if (answeredKeys.contains('problems')) {
      final ratio = overlapRatio(userAnswers['problems']!, domainTaxonomy['problemTags']);
      totalScore += ratio * normalizedWeights['problems']!;
      if (ratio > 0) reasons.add('Aligns with problems you wish to address');
    }

    if (answeredKeys.contains('workStyles')) {
      final ratio = overlapRatio(userAnswers['workStyles']!, domainTaxonomy['workStyleTags']);
      totalScore += ratio * normalizedWeights['workStyles']!;
      if (ratio > 0) reasons.add('Fits your preferred day-to-day research style');
    }

    if (answeredKeys.contains('skills')) {
      final ratio = overlapRatio(userAnswers['skills']!, domainTaxonomy['skillTags']);
      totalScore += ratio * normalizedWeights['skills']!;
      if (ratio > 0) reasons.add('Applies skills you have or wish to develop');
    }

    if (answeredKeys.contains('goals')) {
      final ratio = overlapRatio(userAnswers['goals']!, domainTaxonomy['goalTags']);
      totalScore += ratio * normalizedWeights['goals']!;
      if (ratio > 0) reasons.add('Supports your stated academic milestones');
    }

    if (topicInMind != null && topicInMind.trim().length > 2) {
      final keywords = (domainTaxonomy['keywords'] as List<dynamic>? ?? []).map((e) => e.toString().toLowerCase());
      if (keywords.any((k) => topicInMind.toLowerCase().contains(k))) {
        totalScore = min(1.0, totalScore + 0.10);
        reasons.add('Relates directly to your topic keyword: $topicInMind');
      }
    }

    final finalPercentage = (totalScore * 100).roundToDouble();
    String fitBand = 'Explore';
    if (finalPercentage >= 65.0) {
      fitBand = 'Strong';
    } else if (finalPercentage >= 35.0) {
      fitBand = 'Possible';
    }

    return {
      'score': finalPercentage,
      'fitBand': fitBand,
      'reasons': reasons.isEmpty ? ['Foundational cross-disciplinary alignment'] : reasons,
    };
  }

  /// Calculates researcher discovery score (Section 7.1)
  static Map<String, dynamic> scoreResearcher({
    required List<String> queryTopics,
    required String? queryDomain,
    required List<String> candidateTopics,
    required String? candidateDomain,
    required bool candidateDiscoverable,
  }) {
    if (!candidateDiscoverable) {
      return {'score': 0.0, 'reasons': <String>[]};
    }

    double score = 0.0;
    final reasons = <String>[];

    // Topic overlap (35%)
    final qSet = queryTopics.map((e) => e.toLowerCase()).toSet();
    final cSet = candidateTopics.map((e) => e.toLowerCase()).toSet();
    if (qSet.isNotEmpty && cSet.isNotEmpty) {
      final inter = qSet.intersection(cSet);
      if (inter.isNotEmpty) {
        score += (inter.length / qSet.length) * 0.35;
        reasons.add('Shared topics: ${inter.join(", ")}');
      }
    }

    // Domain overlap (20%)
    if (queryDomain != null && queryDomain == candidateDomain) {
      score += 0.20;
      reasons.add('Same primary research domain ($queryDomain)');
    }

    // Baseline goal, experience & availability alignment (45%)
    score += 0.45;

    return {
      'score': (score * 100).roundToDouble(),
      'reasons': reasons,
    };
  }
}
