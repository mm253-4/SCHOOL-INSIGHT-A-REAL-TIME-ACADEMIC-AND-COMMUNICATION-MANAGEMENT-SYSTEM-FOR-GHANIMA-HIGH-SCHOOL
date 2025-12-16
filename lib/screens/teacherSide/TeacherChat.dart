import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/ChatModel.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TeacherChatController extends GetxController {
  final Chat chat;
  final Teacher teacher;
  final School school;
  
  final TextEditingController messageController = TextEditingController();
  RxList<Message> messages = <Message>[].obs;
  RxBool isLoading = true.obs;
  final ScrollController scrollController = ScrollController();
  
  TeacherChatController(this.chat, this.teacher, this.school);
  
  @override
  void onInit() {
    super.onInit();
    loadMessages();
    markAsRead();
    // Refresh messages periodically
    Stream.periodic(Duration(seconds: 3)).listen((_) {
      loadMessages();
    });
  }
  
  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
  
  Future<void> loadMessages() async {
    try {
      final messageList = await Database_Service.getMessages(chat.chatId);
      messages.assignAll(messageList);
      if (scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    
    try {
      await Database_Service.sendMessage(
        chat.chatId,
        teacher.empID,
        'teacher',
        teacher.name,
        messageController.text.trim(),
      );
      
      messageController.clear();
      await loadMessages();
      
      // Scroll to bottom
      if (scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message');
    }
  }
  
  Future<void> markAsRead() async {
    await Database_Service.markMessagesAsRead(chat.chatId, 'teacher');
  }
  
  String formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return timestamp;
    }
  }
}

class TeacherChatScreen extends StatelessWidget {
  TeacherChatScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    try {
      final List<dynamic>? args = Get.arguments as List<dynamic>?;
      if (args == null || args.length < 3) {
        return Scaffold(
          appBar: AppBar(title: Text('Error')),
          body: Center(child: Text('Invalid arguments')),
        );
      }
      
      final Chat chat = args[0] as Chat;
      final Teacher teacher = args[1] as Teacher;
      final School school = args[2] as School;
      
      final TeacherChatController controller = Get.put(TeacherChatController(chat, teacher, school));
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chat.parentName.isNotEmpty ? chat.parentName : 'Parent',
              style: Font_Styles.labelHeadingLight(context),
            ),
            Text(
              chat.studentName,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.messages.isEmpty) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (controller.messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              
              return ListView.builder(
                controller: controller.scrollController,
                padding: EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isMe = message.senderType == 'teacher';
                  
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.appDarkBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            controller.formatTime(message.timestamp),
                            style: TextStyle(
                              color: isMe ? Colors.white70 : Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: AppColors.appDarkBlue),
                  onPressed: controller.sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    } catch (e) {
      print('Error in TeacherChatScreen: $e');
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading chat'),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

