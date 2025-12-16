class AssignmentSubmission {
  String? id;
  String? assignmentId;
  String? schoolId;
  String? studentId;
  String? studentName;
  String? submissionText;
  String? imagePath; // Path to the image file
  String? documentPath; // Path to the document file (PDF, DOC, etc.)
  DateTime? submittedDate;
  String? status; // 'submitted', 'graded', etc.
  String? grade;
  String? feedback;

  AssignmentSubmission({
    this.id,
    this.assignmentId,
    this.schoolId,
    this.studentId,
    this.studentName,
    this.submissionText,
    this.imagePath,
    this.documentPath,
    this.submittedDate,
    this.status,
    this.grade,
    this.feedback,
  });

  factory AssignmentSubmission.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmission(
      id: map['id']?.toString(),
      assignmentId: map['assignmentId']?.toString(),
      schoolId: map['schoolId']?.toString(),
      studentId: map['studentId']?.toString(),
      studentName: map['studentName']?.toString(),
      submissionText: map['submissionText']?.toString(),
      imagePath: map['imagePath']?.toString(),
      documentPath: map['documentPath']?.toString(),
      submittedDate: map['submittedDate'] != null ? DateTime.parse(map['submittedDate']) : null,
      status: map['status']?.toString(),
      grade: map['grade']?.toString(),
      feedback: map['feedback']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'schoolId': schoolId,
      'studentId': studentId,
      'studentName': studentName,
      'submissionText': submissionText,
      'imagePath': imagePath,
      'documentPath': documentPath,
      'submittedDate': submittedDate?.toIso8601String(),
      'status': status,
      'grade': grade,
      'feedback': feedback,
    };
  }
}

