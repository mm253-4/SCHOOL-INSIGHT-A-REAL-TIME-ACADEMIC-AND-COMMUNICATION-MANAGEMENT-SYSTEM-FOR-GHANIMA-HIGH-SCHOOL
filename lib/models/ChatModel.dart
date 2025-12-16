class Chat {
  final String chatId;
  final String schoolId;
  final String teacherId;
  final String teacherName;
  final String parentId;
  final String parentName;
  final String studentId;
  final String studentName;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;

  Chat({
    required this.chatId,
    required this.schoolId,
    required this.teacherId,
    required this.teacherName,
    required this.parentId,
    required this.parentName,
    required this.studentId,
    required this.studentName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      chatId: map['chatId'] as String,
      schoolId: map['schoolId'] as String,
      teacherId: map['teacherId'] as String,
      teacherName: map['teacherName'] as String? ?? '',
      parentId: map['parentId'] as String,
      parentName: map['parentName'] as String? ?? '',
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String? ?? '',
      lastMessage: map['lastMessage'] as String?,
      lastMessageTime: map['lastMessageTime'] as String?,
      unreadCount: (map['unreadCount'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'schoolId': schoolId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'parentId': parentId,
      'parentName': parentName,
      'studentId': studentId,
      'studentName': studentName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
    };
  }
}

class Message {
  final String messageId;
  final String chatId;
  final String senderId;
  final String senderType; // 'teacher' or 'parent'
  final String senderName;
  final String message;
  final String timestamp;
  final bool isRead;

  Message({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderType,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageId: map['messageId'] as String,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      senderType: map['senderType'] as String,
      senderName: map['senderName'] as String? ?? '',
      message: map['message'] as String,
      timestamp: map['timestamp'] as String,
      isRead: (map['isRead'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'senderType': senderType,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead ? 1 : 0,
    };
  }
}

class GroupChat {
  final String chatId;
  final String schoolId;
  final String teacherId;
  final String teacherName;
  final String className;
  final String subjectName;
  final String groupName;
  final String? lastMessage;
  final String? lastMessageTime;
  final String createdAt;
  final int unreadCount;

  GroupChat({
    required this.chatId,
    required this.schoolId,
    required this.teacherId,
    required this.teacherName,
    required this.className,
    required this.subjectName,
    required this.groupName,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
    this.unreadCount = 0,
  });

  factory GroupChat.fromMap(Map<String, dynamic> map) {
    return GroupChat(
      chatId: map['chatId'] as String,
      schoolId: map['schoolId'] as String,
      teacherId: map['teacherId'] as String,
      teacherName: map['teacherName'] as String? ?? '',
      className: map['className'] as String,
      subjectName: map['subjectName'] as String,
      groupName: map['groupName'] as String,
      lastMessage: map['lastMessage'] as String?,
      lastMessageTime: map['lastMessageTime'] as String?,
      createdAt: map['createdAt'] as String,
      unreadCount: (map['unreadCount'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'schoolId': schoolId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'className': className,
      'subjectName': subjectName,
      'groupName': groupName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'createdAt': createdAt,
      'unreadCount': unreadCount,
    };
  }
}

class GroupChatParticipant {
  final int id;
  final String chatId;
  final String participantId;
  final String participantType; // 'teacher', 'student', or 'parent'
  final String participantName;
  final int unreadCount;
  final String joinedAt;

  GroupChatParticipant({
    required this.id,
    required this.chatId,
    required this.participantId,
    required this.participantType,
    required this.participantName,
    this.unreadCount = 0,
    required this.joinedAt,
  });

  factory GroupChatParticipant.fromMap(Map<String, dynamic> map) {
    return GroupChatParticipant(
      id: map['id'] as int,
      chatId: map['chatId'] as String,
      participantId: map['participantId'] as String,
      participantType: map['participantType'] as String,
      participantName: map['participantName'] as String? ?? '',
      unreadCount: (map['unreadCount'] as int?) ?? 0,
      joinedAt: map['joinedAt'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'participantId': participantId,
      'participantType': participantType,
      'participantName': participantName,
      'unreadCount': unreadCount,
      'joinedAt': joinedAt,
    };
  }
}

