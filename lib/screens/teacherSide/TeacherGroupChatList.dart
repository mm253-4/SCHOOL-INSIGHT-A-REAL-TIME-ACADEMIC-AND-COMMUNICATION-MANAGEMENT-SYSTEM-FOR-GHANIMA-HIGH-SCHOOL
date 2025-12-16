import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/ChatModel.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TeacherGroupChatListController extends GetxController {
  final Teacher teacher;
  final School school;
  
  RxList<GroupChat> groupChats = <GroupChat>[].obs;
  RxBool isLoading = true.obs;
  
  TeacherGroupChatListController(this.teacher, this.school);
  
  @override
  void onInit() {
    super.onInit();
    loadGroupChats();
    // Refresh group chats periodically
    Stream.periodic(Duration(seconds: 5)).listen((_) {
      loadGroupChats();
    });
  }
  
  Future<void> loadGroupChats() async {
    try {
      final chatList = await Database_Service.getTeacherGroupChats(
        school.schoolId,
        teacher.empID,
      );
      groupChats.assignAll(chatList);
    } catch (e) {
      print('Error loading group chats: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  String formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return DateFormat('HH:mm').format(date);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(date);
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return timestamp;
    }
  }
}

class TeacherGroupChatListScreen extends StatelessWidget {
  TeacherGroupChatListScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final List<dynamic>? args = Get.arguments as List<dynamic>?;
    if (args == null || args.length < 2) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.appLightBlue,
          title: Text('Group Chats', style: Font_Styles.labelHeadingLight(context)),
        ),
        body: Center(
          child: Text('Error: Missing required arguments', style: Font_Styles.labelHeadingRegular(context)),
        ),
      );
    }
    final Teacher teacher = args[0] as Teacher;
    final School school = args[1] as School;
    
    final TeacherGroupChatListController controller = Get.put(TeacherGroupChatListController(teacher, school));
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Group Chats', style: Font_Styles.labelHeadingLight(context)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.group_add, color: Colors.black),
            onPressed: () {
              Get.toNamed('/CreateGroupChat', arguments: [teacher, school]);
            },
            tooltip: 'Create New Group Chat',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.groupChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'No group chats yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  'Create a group chat to start communicating with your class',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed('/CreateGroupChat', arguments: [teacher, school]);
                  },
                  icon: Icon(Icons.group_add),
                  label: Text('Create Group Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appDarkBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: controller.groupChats.length,
          itemBuilder: (context, index) {
            final groupChat = controller.groupChats[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.appOrange,
                  child: Icon(Icons.group, color: Colors.white),
                ),
                title: Text(
                  groupChat.groupName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${groupChat.className} - ${groupChat.subjectName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (groupChat.lastMessage != null)
                      Text(
                        groupChat.lastMessage!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      controller.formatTime(groupChat.lastMessageTime),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (groupChat.unreadCount > 0)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          groupChat.unreadCount.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Get.toNamed('/TeacherGroupChat', arguments: [groupChat, teacher, school]);
                },
              ),
            );
          },
        );
      }),
    );
  }
}

