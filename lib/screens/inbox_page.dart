import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? currentUserId;

  static const Color homeBg = Color(0xFFF94449); // off-white

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    currentUserId = user?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }
    final isAdmin =
        _auth.currentUser?.email?.toLowerCase() == "nearbyhungry@gmail.com";

    return Scaffold(
      backgroundColor: homeBg,
      appBar: AppBar(
        backgroundColor: homeBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: isAdmin
            ? _firestore
            .collection('chats')
            .snapshots()
            : _firestore
            .collection('chats')
            .where(
          'participants',
          arrayContains: currentUserId,
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("Inbox error: ${snapshot.error}");
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No chats now"));
          }

          final docs = snapshot.data!.docs.toList();

          // local sort (null-safe)
          docs.sort((a, b) {
            final ta =
            (a.data() as Map<String, dynamic>)['lastMessageTime']
            as Timestamp?;
            final tb =
            (b.data() as Map<String, dynamic>)['lastMessageTime']
            as Timestamp?;

            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });

          final visibleDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final hiddenFor =
                (data['hiddenFor'] as List?)?.cast<String>() ?? [];
            return !hiddenFor.contains(currentUserId);
          }).toList();

          if (visibleDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No messages yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            itemCount: visibleDocs.length,
            itemBuilder: (context, index) {
              final doc = visibleDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final chefId = data['chefId'] as String?;
              final customerId = data['customerId'] as String?;
              final participants =
                  (data['participants'] as List?)?.cast<String>() ?? [];

              if (chefId == null ||
                  customerId == null ||
                  participants.isEmpty) {
                return const SizedBox();
              }

              final lastMessage = data['lastMessage'] as String?;
              final ts = data['lastMessageTime'] as Timestamp?;

              final unreadKey = 'unreadCount_$currentUserId';

              int unreadCount = 0;
              final rawUnread = data[unreadKey];
              if (rawUnread is int) {
                unreadCount = rawUnread;
              }

              String otherUserId = '';

              if (isAdmin) {
                otherUserId = chefId; // show chef profile
              } else {
                otherUserId = participants.firstWhere(
                      (e) => e != currentUserId,
                  orElse: () => '',
                );
              }

              if (otherUserId.isEmpty) {
                return const SizedBox();
              }

              return _InboxTile(
                chefId: chefId,
                customerId: customerId,
                otherUserId: otherUserId,
                lastMessage: lastMessage,
                lastMessageTime: ts,
                unreadCount: unreadCount,
                onTap: (name) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        chefId: chefId,
                        customerId: customerId,
                        chefName: name,
                        isAdmin: isAdmin,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  final String chefId;
  final String customerId;
  final String otherUserId;
  final String? lastMessage;
  final Timestamp? lastMessageTime;
  final int unreadCount;
  final Function(String name) onTap;

  const _InboxTile({
    required this.chefId,
    required this.customerId,
    required this.otherUserId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot>(
      future: firestore.collection('users').doc(otherUserId).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 30,
                ),
                SizedBox(width: 12),
                Text("Loading..."),
              ],
            ),
          );
        }

        String name = "User";
        String? image;

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          name = (data['username'] ?? '').toString().trim();

          if (name.isEmpty) {
            name = "User";
          }

          image = data['profileImage'];
        }

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onTap(name),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                      image != null ? NetworkImage(image) : null,
                      child: image == null
                          ? const Icon(
                        Icons.person,
                        size: 30,
                      )
                          : null,
                    ),

                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        lastMessage ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: unreadCount > 0
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
                  children: [
                    if (lastMessageTime != null)
                      Text(
                        _formatTime(
                          lastMessageTime!.toDate(),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: unreadCount > 0
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),

                    const SizedBox(height: 8),

                    if (unreadCount > 0)
                      Container(
                        constraints:
                        const BoxConstraints(
                          minWidth: 22,
                        ),
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Text(
                          unreadCount > 99
                              ? '99+'
                              : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();

    if (now.year == date.year &&
        now.month == date.month &&
        now.day == date.day) {
      int hour = date.hour % 12;
      if (hour == 0) hour = 12;

      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = date.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $ampm';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
  }
}
