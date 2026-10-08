import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _currentUserEmail;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    final userData = await userService.value.getUserData();
    if (!mounted) return;
    setState(() {
      _currentUserEmail = userData['email'];
    });
    await _chatService.registerUser({
      'uid': userData['uid'],
      'email': userData['email'] ?? '',
      'firstName': userData['firstName'] ?? '',
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20.h),
          // ENHANCEMENT 2: Search bar at the top of the chat list.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 23.w),
            child: TextField(
              controller: _searchChatController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15.sp),
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
                suffixIcon: (_searchChatController.text.isNotEmpty)
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          setState(() {
                            _searchChatController.clear();
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8.w),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // ENHANCEMENT 1: Display all registered users in the chat list.
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: Center(
                    child: CustomText(
                      text: 'Error loading users',
                      fontSize: 16.sp,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: Center(
                    child: CustomText(
                      text: 'No users found',
                      fontSize: 16.sp,
                    ),
                  ),
                );
              }

              final users = snapshot.data!.where((user) {
                final email = (user['email'] ?? '').toString();
                final name = (user['firstName'] ?? '').toString();
                final query = _searchText.toLowerCase();
                final isCurrentUser = email.toLowerCase() ==
                    (_currentUserEmail ?? '').toLowerCase();
                if (isCurrentUser) return false;
                if (query.isEmpty) return true;
                // ENHANCEMENT 2: Filter users by first name or email.
                return name.toLowerCase().contains(query) ||
                    email.toLowerCase().contains(query);
              }).toList();

              if (users.isEmpty) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: Center(
                    child: CustomText(
                      text: 'No messages found...',
                      fontSize: 16.sp,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 72.w,
                  color: const Color(0xFFE4E6EB),
                ),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final firstName = (user['firstName'] ?? 'Unknown').toString();
                  final initial = firstName.isNotEmpty
                      ? firstName[0].toUpperCase()
                      : '?';
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            currentUserEmail: _currentUserEmail!,
                            tappedUser: user,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26.r,
                            backgroundColor: const Color(0xFF0084FF),
                            child: CustomText(
                              text: initial,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: firstName,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                SizedBox(height: 2.h),
                                CustomText(
                                  text: user['email'] ?? 'No email',
                                  fontSize: 13.sp,
                                  color: const Color(0xFF65676B),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    ),
    );
  }
}
