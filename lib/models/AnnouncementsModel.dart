class Announcement {
  String? announcementBy;
  DateTime? announcementDate;
  String? announcementDescription;
  String? studentID;
  bool? adminAnnouncement;
  DateTime? deadline;
  String? timeline;

  Announcement({
    this.announcementBy,
    this.announcementDate,
    this.announcementDescription,
    this.studentID,
    this.adminAnnouncement,
    this.deadline,
    this.timeline,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      announcementBy: json['AnnouncementBy'] ?? '',
      announcementDate: json['AnnouncementDate'] != null
          ? DateTime.tryParse(json['AnnouncementDate'].toString())
          : null,
      announcementDescription: json['AnnouncementDescription'] ?? '',
      studentID: json['StudentID'] ?? '',
      adminAnnouncement: json['AdminAnnouncement'] ?? false,
      deadline: json['Deadline'] != null
          ? DateTime.tryParse(json['Deadline'].toString())
          : null,
      timeline: json['Timeline'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AnnouncementBy': announcementBy,
      'AnnouncementDate': announcementDate?.toIso8601String(),
      'AnnouncementDescription': announcementDescription,
      'StudentID': studentID,
      'AdminAnnouncement': adminAnnouncement,
      'Deadline': deadline?.toIso8601String(),
      'Timeline': timeline,
    };
  }
}