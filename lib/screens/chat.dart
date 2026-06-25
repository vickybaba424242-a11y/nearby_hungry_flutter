import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String chefId;
  final String customerId;
  final String? chefName;

  const ChatPage({
    super.key,
    required this.chefId,
    required this.customerId,
    this.chefName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();

  late final String currentUserId;
  late final String chatId;

  // ---- phone number tracking (same idea as Android) ----
  final List<String> _recentUserMessages = [];
  static const int _maxTrackedMessages = 10;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    currentUserId = user.uid;

    final a = widget.chefId;
    final b = widget.customerId;
    chatId = a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';

    _markAsRead();
    _listenHiddenChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    await _db.collection('chats').doc(chatId).set({
      'unreadCount_$currentUserId': 0,
      'isRead_$currentUserId': true,
    }, SetOptions(merge: true));
  }

  void _listenHiddenChat() {
    _db.collection('chats').doc(chatId).snapshots().listen((doc) {
      if (!doc.exists) return;

      final hiddenFor = doc.data()?['hiddenFor'];
      if (hiddenFor is List && hiddenFor.contains(currentUserId)) {
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Track last messages
    _recentUserMessages.add(text);
    if (_recentUserMessages.length > _maxTrackedMessages) {
      _recentUserMessages.removeAt(0);
    }

    final isSingleBlocked = PhoneNumberFilter.containsPhoneNumber(text);
    final isMultiBlocked =
    PhoneNumberFilter.containsPhoneNumberAcrossMessages(
        _recentUserMessages);

    if (isSingleBlocked || isMultiBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing phone numbers is not allowed.')),
      );
      _recentUserMessages.clear();
      return;
    }

    _controller.clear();

    final otherUserId = currentUserId == widget.chefId
        ? widget.customerId
        : widget.chefId;

    final msg = {
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    };

    final updates = {
      'chefId': widget.chefId,
      'customerId': widget.customerId,
      'participants': [widget.chefId, widget.customerId],
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'hiddenFor': FieldValue.arrayRemove([currentUserId]),
      'unreadCount_$otherUserId': FieldValue.increment(1),
      'unreadCount_$currentUserId': 0,
    };

    await _db
        .collection('chats')
        .doc(chatId)
        .set(updates, SetOptions(merge: true));

    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chefName ?? 'Chat'),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sevenDaysAgo =
        DateTime.now().subtract(const Duration(days: 7));

        final docs = snapshot.data!.docs.where((d) {
          final ts = (d.data() as Map<String, dynamic>)['timestamp'];
          if (ts == null) return false;
          final dt = (ts as Timestamp).toDate();
          return dt.isAfter(sevenDaysAgo);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isMe = data['senderId'] == currentUserId;

            return MessageBubble(
              text: data['text'] ?? '',
              isMe: isMe,
              timestamp: data['timestamp'],
              seen: data['seen'] == true,
            );
          },
        );
      },
    );
  }

  Widget _buildInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
            )
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final dynamic timestamp;
  final bool seen;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.seen,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(text),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatSmartDateTime(timestamp),
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Text(
                    seen ? '✓✓' : '✓',
                    style:
                    const TextStyle(fontSize: 10, color: Colors.green),
                  )
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatSmartDateTime(dynamic ts) {
    if (ts == null) return '';

    final DateTime dt = (ts as Timestamp).toDate();
    final now = DateTime.now();

    final bool isSameDay =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final bool isYesterday =
        yesterday.year == dt.year &&
            yesterday.month == dt.month &&
            yesterday.day == dt.day;

    final time = _formatTimeOnly(dt);

    if (isSameDay) {
      return 'Today • $time';
    } else if (isYesterday) {
      return 'Yesterday • $time';
    } else {
      return '${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)} • $time';
    }
  }

  String _formatTimeOnly(DateTime dt) {
    int hour = dt.hour % 12;
    if (hour == 0) hour = 12;

    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $ampm';
  }

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[m - 1];
  }
}

class PhoneNumberFilter {
  static final RegExp _phoneRegex =
  RegExp(r'(\+?\d[\d\s\-]{7,}\d)');

  static bool containsPhoneNumber(String text) {
    return _phoneRegex.hasMatch(text);
  }

  static bool containsPhoneNumberAcrossMessages(List<String> messages) {
    final combined = messages.join(' ');
    return _phoneRegex.hasMatch(combined);
  }
}

// ------------------------------
// Navigation helpers
// ------------------------------

Future<void> openChatFromPost({
  required BuildContext context,
  required String chefId,
  required String chefName,
  required String currentUserId,
}) async {
  final customerId = currentUserId;

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChatPage(
        chefId: chefId,
        customerId: customerId,
        chefName: chefName,
      ),
    ),
  );
}

Future<void> openChatFromInbox({
  required BuildContext context,
  required String chefId,
  required String customerId,
  required String chefName,
}) async {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChatPage(
        chefId: chefId,
        customerId: customerId,
        chefName: chefName,
      ),
    ),
  );
}
