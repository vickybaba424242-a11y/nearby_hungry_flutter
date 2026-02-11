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

  static const Color homeBg = Color(0xFFFFE0B2);

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

    return Scaffold(
      backgroundColor: homeBg,
      appBar: AppBar(
        backgroundColor: homeBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
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
            return const Center(
              child: Text(
                'No chats now',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            itemCount: visibleDocs.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 76),
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

              final otherUserId = participants.firstWhere(
                    (e) => e != currentUserId,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox();

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
        String name = 'User';
        String? image;

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          name = data['username'] ?? 'User';
          image = data['profileImage'];
        }

        return InkWell(
          onTap: () => onTap(name),
          child: Container(
            color: Colors.transparent,
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage:
                  image != null ? NetworkImage(image) : null,
                  child:
                  image == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                              : Colors.grey[600],
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lastMessageTime != null)
                      Text(
                        _formatTime(lastMessageTime!.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
