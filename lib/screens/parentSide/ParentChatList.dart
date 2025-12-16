import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/ChatModel.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ParentChatListController extends GetxController {
  final Student student;
  final School school;
  
  RxList<Chat> chats = <Chat>[].obs;
  RxBool isLoading = true.obs;
  
  ParentChatListController(this.student, this.school);
  
  @override
  void onInit() {
    super.onInit();
    loadChats();
    // Refresh chats periodically
    Stream.periodic(Duration(seconds: 5)).listen((_) {
      loadChats();
    });
  }
  
  Future<void> loadChats() async {
    try {
      final chatList = await Database_Service.getParentChats(
        school.schoolId,
        student.studentID,
      );
      chats.assignAll(chatList);
    } catch (e) {
      print('Error loading chats: $e');
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

class ParentChatListScreen extends StatelessWidget {
  ParentChatListScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final List<dynamic>? args = Get.arguments as List<dynamic>?;
    if (args == null || args.length < 2) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.appLightBlue,
          title: Text('Chats', style: Font_Styles.labelHeadingLight(context)),
        ),
        body: Center(
          child: Text('Error: Missing required arguments', style: Font_Styles.labelHeadingRegular(context)),
        ),
      );
    }
    final Student student = args[0] as Student;
    final School school = args[1] as School;
    
    final ParentChatListController controller = Get.put(ParentChatListController(student, school));
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Chats with Teachers', style: Font_Styles.labelHeadingLight(context)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment, color: Colors.black),
            onPressed: () {
              Get.toNamed('/ParentStartChat', arguments: [controller.student, controller.school]);
            },
            tooltip: 'Start New Chat',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'No chats yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  'Teachers will start chats with you here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: controller.chats.length,
          itemBuilder: (context, index) {
            final chat = controller.chats[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.appOrange,
                child: Text(
                  chat.teacherName[0].toUpperCase(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                chat.teacherName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About: ${chat.studentName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (chat.lastMessage != null)
                    Text(
                      chat.lastMessage!,
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
                    controller.formatTime(chat.lastMessageTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (chat.unreadCount > 0)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chat.unreadCount.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Get.toNamed('/ParentChat', arguments: [chat, controller.student, controller.school]);
              },
            );
          },
        );
      }),
    );
  }
}

