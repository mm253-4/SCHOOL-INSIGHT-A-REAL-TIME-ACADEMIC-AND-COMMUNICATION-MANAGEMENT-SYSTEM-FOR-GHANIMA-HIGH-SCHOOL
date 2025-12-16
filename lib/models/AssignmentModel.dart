class Assignment {
  String? id;
  String? schoolId;
  String? teacherId;
  String? teacherName;
  String? className;
  String? subject;
  String? title;
  String? description;
  DateTime? dueDate;
  DateTime? postedDate;
  String? attachmentUrl; // For future file uploads
  String? documentPath; // Path to uploaded document (PDF, DOC, etc.)
  String? imagePath; // Path to uploaded image
  List<String>? assignedClasses; // For multiple class assignments

  Assignment({
    this.id,
    this.schoolId,
    this.teacherId,
    this.teacherName,
    this.className,
    this.subject,
    this.title,
    this.description,
    this.dueDate,
    this.postedDate,
    this.attachmentUrl,
    this.documentPath,
    this.imagePath,
    this.assignedClasses,
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id']?.toString(),
      schoolId: map['schoolId']?.toString(),
      teacherId: map['teacherId']?.toString(),
      teacherName: map['teacherName']?.toString(),
      className: map['className']?.toString(),
      subject: map['subject']?.toString(),
      title: map['title']?.toString(),
      description: map['description']?.toString(),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      postedDate: map['postedDate'] != null ? DateTime.parse(map['postedDate']) : null,
      attachmentUrl: map['attachmentUrl']?.toString(),
      documentPath: map['documentPath']?.toString(),
      imagePath: map['imagePath']?.toString(),
      assignedClasses: map['assignedClasses'] != null 
          ? List<String>.from(map['assignedClasses']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'className': className,
      'subject': subject,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'postedDate': postedDate?.toIso8601String(),
      'attachmentUrl': attachmentUrl,
      'documentPath': documentPath,
      'imagePath': imagePath,
      'assignedClasses': assignedClasses,
    };
  }
}

