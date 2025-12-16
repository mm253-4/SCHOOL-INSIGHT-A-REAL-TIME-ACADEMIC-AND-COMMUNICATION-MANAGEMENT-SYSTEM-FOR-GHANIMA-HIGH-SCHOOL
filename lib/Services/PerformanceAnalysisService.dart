import 'package:classinsight/Services/Database_Service.dart';

class ImprovementSuggestion {
  final String subject;
  final String examType;
  final String suggestion;
  final String priority; // 'High', 'Medium', 'Low'
  final double currentScore;
  final double targetScore;
  final String term; // Term key (e.g., "2025_class 5-Yellow_Term 1")

  ImprovementSuggestion({
    required this.subject,
    required this.examType,
    required this.suggestion,
    required this.priority,
    required this.currentScore,
    required this.targetScore,
    required this.term,
  });
}

class PerformanceAnalysisService {
  // Calculate percentage from marks string (e.g., "45/50" -> 90.0)
  static double parseMarksToPercentage(String marks) {
    if (marks.isEmpty || marks == '-') return 0.0;
    
    try {
      final regex = RegExp(r'(\d+)/(\d+)');
      final match = regex.firstMatch(marks);
      if (match != null) {
        final obtained = int.tryParse(match.group(1) ?? '0') ?? 0;
        final total = int.tryParse(match.group(2) ?? '1') ?? 1;
        if (total > 0) {
          return (obtained / total) * 100;
        }
      }
    } catch (e) {
      print('Error parsing marks: $e');
    }
    return 0.0;
  }

  // Get grade based on percentage
  static String getGrade(double percentage) {
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  // Analyze student performance and generate improvement suggestions
  static List<ImprovementSuggestion> analyzePerformance(
    Map<String, Map<String, String>> resultMap,
    List<String> subjects,
    List<String> examTypes,
    String term,
  ) {
    List<ImprovementSuggestion> suggestions = [];

    for (var subject in subjects) {
      final subjectResults = resultMap[subject] ?? {};
      
      // Calculate average percentage for the subject
      List<double> percentages = [];
      Map<String, double> examScores = {};
      
      for (var examType in examTypes) {
        final marks = subjectResults[examType] ?? '-';
        final percentage = parseMarksToPercentage(marks);
        if (percentage > 0) {
          percentages.add(percentage);
          examScores[examType] = percentage;
        }
      }

      if (percentages.isEmpty) continue;

      final averageScore = percentages.reduce((a, b) => a + b) / percentages.length;
      final grade = getGrade(averageScore);

      // Focus on individual exam types only for low grades (D and F) - these need immediate attention
      for (var entry in examScores.entries) {
        final examType = entry.key;
        final score = entry.value;
        final examGrade = getGrade(score);

        // High priority suggestions for failing grades (F) - individual exam focus
        if (examGrade == 'F' || score < 40) {
          suggestions.add(ImprovementSuggestion(
            subject: subject,
            examType: examType,
            suggestion: '${subject} (${examType}): Scored ${score.toStringAsFixed(1)}%. Below passing. Needs immediate attention. Focus on fundamentals and extra practice.',
            priority: 'High',
            currentScore: score,
            targetScore: 50.0,
            term: term,
          ));
        }
        // High priority for D grades - individual exam focus
        else if (examGrade == 'D' || (score >= 40 && score < 50)) {
          suggestions.add(ImprovementSuggestion(
            subject: subject,
            examType: examType,
            suggestion: '${subject} (${examType}): Scored ${score.toStringAsFixed(1)}%. Needs improvement. Regular study and practice tests can help reach C grade.',
            priority: 'High',
            currentScore: score,
            targetScore: 60.0,
            term: term,
          ));
        }
      }

      // Subject-level encouragement - Focus on overall subject performance
      if (averageScore > 0) {
        final grade = getGrade(averageScore);
        
        if (grade == 'F' || averageScore < 40) {
          // High priority for failing subject
          suggestions.add(ImprovementSuggestion(
            subject: subject,
            examType: 'Subject Overall',
            suggestion: '${subject}: Grade ${grade} (${averageScore.toStringAsFixed(1)}%). Needs immediate attention. Focus on fundamentals and seek extra help.',
            priority: 'High',
            currentScore: averageScore,
            targetScore: 50.0,
            term: term,
          ));
        } else if (grade == 'D') {
          // High priority for D grade subject
          suggestions.add(ImprovementSuggestion(
            subject: subject,
            examType: 'Subject Overall',
            suggestion: '${subject}: Grade ${grade} (${averageScore.toStringAsFixed(1)}%). Needs improvement. Regular study and practice can help reach C grade.',
            priority: 'High',
            currentScore: averageScore,
            targetScore: 60.0,
            term: term,
          ));
        } else if (grade == 'C') {
          // Positive feedback for C grade subject
          suggestions.add(ImprovementSuggestion(
            subject: subject,
            examType: 'Subject Overall',
            suggestion: '${subject}: Grade ${grade} (${averageScore.toStringAsFixed(1)}%). Good work! Keep striving for higher grades.',
            priority: 'Low',
            currentScore: averageScore,
            targetScore: 65.0,
            term: term,
          ));
        } else if (grade == 'B') {
          // Positive feedback for B grade subject
          suggestions.add(ImprovementSuggestion(
            subject: subject,
            examType: 'Subject Overall',
            suggestion: '${subject}: Grade ${grade} (${averageScore.toStringAsFixed(1)}%). Excellent! Keep up the dedication to reach an A.',
            priority: 'Low',
            currentScore: averageScore,
            targetScore: 75.0,
            term: term,
          ));
        } else if (grade == 'A') {
          // Positive feedback for A grade subject
          suggestions.add(ImprovementSuggestion(
            subject: subject,
            examType: 'Subject Overall',
            suggestion: '${subject}: Grade ${grade} (${averageScore.toStringAsFixed(1)}%). Outstanding! Maintain this high standard.',
            priority: 'Low',
            currentScore: averageScore,
            targetScore: averageScore + 5.0,
            term: term,
          ));
        }
      }
    }

    // Sort suggestions by priority (High -> Medium -> Low) and then by score
    suggestions.sort((a, b) {
      final priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
      final priorityCompare = priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      if (priorityCompare != 0) return priorityCompare;
      return a.currentScore.compareTo(b.currentScore);
    });

    return suggestions;
  }

  // Generate term-level overall encouragement
  static ImprovementSuggestion? generateTermOverallEncouragement(
    Map<String, Map<String, String>> resultMap,
    List<String> subjects,
    List<String> examTypes,
    String term,
  ) {
    int totalExams = 0;
    double totalAverage = 0.0;
    int subjectsWithData = 0;

    for (var subject in subjects) {
      final subjectResults = resultMap[subject] ?? {};
      List<double> percentages = [];

      for (var examType in examTypes) {
        final marks = subjectResults[examType] ?? '-';
        final percentage = parseMarksToPercentage(marks);
        if (percentage > 0) {
          percentages.add(percentage);
          totalExams++;
        }
      }

      if (percentages.isNotEmpty) {
        final subjectAverage = percentages.reduce((a, b) => a + b) / percentages.length;
        totalAverage += subjectAverage;
        subjectsWithData++;
      }
    }

    if (subjectsWithData == 0) return null;

    final overallAverage = totalAverage / subjectsWithData;
    final grade = getGrade(overallAverage);

    String encouragement = '';
    String priority = 'Low';
    double targetScore = overallAverage + 5.0;

    if (grade == 'F' || overallAverage < 40) {
      encouragement = 'Term Overall: Grade ${grade} (${overallAverage.toStringAsFixed(1)}%). Needs immediate attention. Focus on all subjects and seek extra help.';
      priority = 'High';
      targetScore = 50.0;
    } else if (grade == 'D') {
      encouragement = 'Term Overall: Grade ${grade} (${overallAverage.toStringAsFixed(1)}%). Needs improvement. Consistent effort can help reach C grade.';
      priority = 'High';
      targetScore = 60.0;
    } else if (grade == 'C') {
      encouragement = 'Term Overall: Grade ${grade} (${overallAverage.toStringAsFixed(1)}%). Good work! Keep striving for higher grades.';
    } else if (grade == 'B') {
      encouragement = 'Term Overall: Grade ${grade} (${overallAverage.toStringAsFixed(1)}%). Excellent! Maintain dedication to reach an A.';
    } else if (grade == 'A') {
      encouragement = 'Term Overall: Grade ${grade} (${overallAverage.toStringAsFixed(1)}%). Outstanding! Continue to excel.';
    }

    if (encouragement.isEmpty) return null;

    return ImprovementSuggestion(
      subject: 'All Subjects',
      examType: 'Term Overall',
      suggestion: encouragement,
      priority: priority,
      currentScore: overallAverage,
      targetScore: targetScore,
      term: term,
    );
  }

  // Get overall performance summary
  static Map<String, dynamic> getPerformanceSummary(
    Map<String, Map<String, String>> resultMap,
    List<String> subjects,
    List<String> examTypes,
    String term,
  ) {
    int totalExams = 0;
    int passedExams = 0;
    int failedExams = 0;
    double totalAverage = 0.0;
    int subjectsWithData = 0;

    for (var subject in subjects) {
      final subjectResults = resultMap[subject] ?? {};
      List<double> percentages = [];

      for (var examType in examTypes) {
        final marks = subjectResults[examType] ?? '-';
        final percentage = parseMarksToPercentage(marks);
        if (percentage > 0) {
          percentages.add(percentage);
          totalExams++;
          if (percentage >= 40) {
            passedExams++;
          } else {
            failedExams++;
          }
        }
      }

      if (percentages.isNotEmpty) {
        final subjectAverage = percentages.reduce((a, b) => a + b) / percentages.length;
        totalAverage += subjectAverage;
        subjectsWithData++;
      }
    }

    final overallAverage = subjectsWithData > 0 ? totalAverage / subjectsWithData : 0.0;
    final passRate = totalExams > 0 ? (passedExams / totalExams) * 100 : 0.0;

    return {
      'overallAverage': overallAverage,
      'passRate': passRate,
      'totalExams': totalExams,
      'passedExams': passedExams,
      'failedExams': failedExams,
      'subjectsCount': subjectsWithData,
    };
  }
}

