import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
<<<<<<< HEAD

  final TextEditingController _controller =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  Map<String, dynamic>? replyingToMessage;

  DocumentReference? replyingToMessageRef;

  final Color homeBg =
  const Color(0xFFFFE0B2);

  late final String currentUserId;

=======
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Color homeBg = const Color(0xFFFFE0B2);

  late final String currentUserId;
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
  late final String chatId;

  StreamSubscription<DocumentSnapshot>? _hiddenSub;

  final List<String> _recentUserMessages = [];
<<<<<<< HEAD

=======
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
  static const int _maxTrackedMessages = 10;

  @override
  void initState() {
    super.initState();

<<<<<<< HEAD
    final user =
        FirebaseAuth.instance.currentUser;

=======
    final user = FirebaseAuth.instance.currentUser;
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
    if (user == null) {
      throw Exception('User not logged in');
    }

    currentUserId = user.uid;

    final a = widget.chefId;
    final b = widget.customerId;
<<<<<<< HEAD

    chatId =
    a.compareTo(b) < 0
        ? '${a}_$b'
        : '${b}_$a';

    _markAsRead();

=======
    chatId = a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';

    _markAsRead();
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
    _listenHiddenChat();
  }

  @override
  void dispose() {
    _controller.dispose();
<<<<<<< HEAD

    _scrollController.dispose();

    _hiddenSub?.cancel();

=======
    _scrollController.dispose();
    _hiddenSub?.cancel();
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
    super.dispose();
  }

  Future<void> _markAsRead() async {
    await _db.collection('chats').doc(chatId).set({
      'unreadCount_$currentUserId': 0,
      'isRead_$currentUserId': true,
    }, SetOptions(merge: true));
  }

  void _listenHiddenChat() {
<<<<<<< HEAD
    _hiddenSub =
        _db
            .collection('chats')
            .doc(chatId)
            .snapshots()
            .listen((doc) {
          if (!doc.exists) return;

          final data = doc.data();

          final hiddenFor = data?['hiddenFor'];

          if (hiddenFor is List &&
              hiddenFor.contains(currentUserId)) {
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        });
=======
    _hiddenSub = _db.collection('chats').doc(chatId).snapshots().listen((doc) {
      if (!doc.exists) return;

      final data = doc.data();
      final hiddenFor = data?['hiddenFor'];

      if (hiddenFor is List && hiddenFor.contains(currentUserId)) {
        if (mounted) Navigator.of(context).pop();
      }
    });
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
<<<<<<< HEAD

    if (text.isEmpty) return;

    _recentUserMessages.add(text);

    if (_recentUserMessages.length >
        _maxTrackedMessages) {
      _recentUserMessages.removeAt(0);
    }

    final isSingleBlocked =
    PhoneNumberFilter.containsPhoneNumber(
        text);

    final isMultiBlocked =
    PhoneNumberFilter
        .containsPhoneNumberAcrossMessages(
=======
    if (text.isEmpty) return;

    _recentUserMessages.add(text);
    if (_recentUserMessages.length > _maxTrackedMessages) {
      _recentUserMessages.removeAt(0);
    }

    final isSingleBlocked = PhoneNumberFilter.containsPhoneNumber(text);
    final isMultiBlocked =
    PhoneNumberFilter.containsPhoneNumberAcrossMessages(
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
        _recentUserMessages);

    if (isSingleBlocked || isMultiBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
        const SnackBar(
          content: Text(
            'Sharing phone numbers is not allowed.',
          ),
        ),
      );

      _recentUserMessages.clear();

=======
        const SnackBar(content: Text('Sharing phone numbers is not allowed.')),
      );
      _recentUserMessages.clear();
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
      return;
    }

    _controller.clear();

    final otherUserId =
<<<<<<< HEAD
    currentUserId == widget.chefId
        ? widget.customerId
        : widget.chefId;
=======
    currentUserId == widget.chefId ? widget.customerId : widget.chefId;
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f

    final msg = {
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
<<<<<<< HEAD

      // reply feature
      'replyText':
      replyingToMessage?['text'],

      'replySenderId':
      replyingToMessage?['senderId'],
=======
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
    };

    final updates = {
      'chefId': widget.chefId,
<<<<<<< HEAD

      'customerId': widget.customerId,

      'participants': [
        widget.chefId,
        widget.customerId,
      ],

      'lastMessage': text,

      'lastMessageTime':
      FieldValue.serverTimestamp(),

      'hiddenFor':
      FieldValue.arrayRemove([
        currentUserId,
      ]),

      'unreadCount_$otherUserId':
      FieldValue.increment(1),

=======
      'customerId': widget.customerId,
      'participants': [widget.chefId, widget.customerId],
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'hiddenFor': FieldValue.arrayRemove([currentUserId]),
      'unreadCount_$otherUserId': FieldValue.increment(1),
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
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
<<<<<<< HEAD

    setState(() {
      replyingToMessage = null;

      replyingToMessageRef = null;
    });

    Future.delayed(
      const Duration(milliseconds: 100),
          () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration:
            const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );
=======
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
<<<<<<< HEAD
        statusBarColor:
        Color(0xFFFFE0B2),

        statusBarIconBrightness:
        Brightness.dark,
=======
        statusBarColor: Color(0xFFFFE0B2),
        statusBarIconBrightness: Brightness.dark,
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
      ),
    );

    return Scaffold(
      backgroundColor: homeBg,
<<<<<<< HEAD

      appBar: AppBar(
        backgroundColor: homeBg,

        elevation: 0,

        automaticallyImplyLeading: true,

        title: FutureBuilder<DocumentSnapshot>(
          future: _db.collection('users').doc(
            currentUserId == widget.chefId
                ? widget.customerId
                : widget.chefId,
          ).get(),

          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text("User");
            }

            final data =
            snapshot.data!.data()
            as Map<String, dynamic>?;

            final userName =
                data?['username'] ??
                    data?['name'] ??
                    data?['displayName'] ??
                    widget.chefName ??
                    "User";

            return Text(
              userName.toString(),
            );
          },
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.home),

            onPressed: () {
              Navigator.of(context)
                  .popUntil(
                    (route) => route.isFirst,
              );
=======
      appBar: AppBar(
        backgroundColor: homeBg,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: Text(
          (widget.chefName != null && widget.chefName!.trim().isNotEmpty)
              ? widget.chefName!
              : "User",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
            },
          ),
        ],
      ),
<<<<<<< HEAD

=======
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/chat_background.jpg',
<<<<<<< HEAD

              fit: BoxFit.cover,
            ),
          ),

          Column(
            children: [
              Expanded(
                child: _buildMessages(),
              ),

=======
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Expanded(child: _buildMessages()),
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
              _buildInput(),
            ],
          ),
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
<<<<<<< HEAD
          .orderBy(
        'timestamp',
        descending: true,
      )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Unable to load messages'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
=======
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load messages'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
<<<<<<< HEAD
          return const Center(
            child: Text('No messages yet'),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 6,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data =
            docs[index].data() as Map<String, dynamic>;

            final isMe =
                data['senderId'] == currentUserId;

            // seen update
            if (!isMe &&
                data['seen'] != true) {
              docs[index].reference.update({
                'seen': true,
              });
            }

            double dragDistance = 0;

            return StatefulBuilder(
              builder: (context, setItemState) {
                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setItemState(() {

                      // right swipe for other user
                      if (!isMe) {
                        dragDistance += details.delta.dx;

                        dragDistance =
                            dragDistance.clamp(0, 80);
                      }

                      // left swipe for own message
                      if (isMe) {
                        dragDistance += details.delta.dx;

                        dragDistance =
                            dragDistance.clamp(-80, 0);
                      }
                    });
                  },

                  onHorizontalDragEnd: (_) {

                    // trigger reply
                    if ((!isMe && dragDistance > 40) ||
                        (isMe && dragDistance < -40)) {

                      HapticFeedback.mediumImpact();

                      setState(() {
                        replyingToMessage = data;

                        replyingToMessageRef =
                            docs[index].reference;
                      });
                    }

                    // reset animation
                    setItemState(() {
                      dragDistance = 0;
                    });
                  },

                  child: Transform.translate(
                    offset: Offset(dragDistance, 0),

                    child: Stack(
                      alignment:
                      isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,

                      children: [

                        // reply icon
                        Positioned(
                          left: !isMe ? 10 : null,
                          right: isMe ? 10 : null,

                          child: Opacity(
                            opacity:
                            dragDistance.abs() / 80,

                            child: const Icon(
                              Icons.reply,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),

                        MessageBubble(
                          text: data['text'] ?? '',
                          replyText: data['replyText'],
                          isMe: isMe,
                          timestamp: data['timestamp'],
                          seen: data['seen'] == true,
                        ),
                      ],
                    ),
                  ),
                );
              },
=======
          return const Center(child: Text('No messages yet'));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.minScrollExtent,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isMe = data['senderId'] == currentUserId;

            return MessageBubble(
              text: data['text'] ?? '',
              isMe: isMe,
              timestamp: data['timestamp'],
              seen: data['seen'] == true,
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
            );
          },
        );
      },
    );
  }

  Widget _buildInput() {
    return SafeArea(
      child: Container(
        color: homeBg,
<<<<<<< HEAD

        padding:
        const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyingToMessage != null)
              Container(
                margin:
                const EdgeInsets.only(
                  bottom: 6,
                ),

                padding:
                const EdgeInsets.all(10),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),

                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [
                          const Text(
                            "Replying to",

                            style: TextStyle(
                              fontWeight:
                              FontWeight
                                  .bold,

                              fontSize: 12,
                            ),
                          ),

                          Text(
                            replyingToMessage![
                            'text'] ??
                                '',

                            maxLines: 2,

                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.close,
                      ),

                      onPressed: () {
                        setState(() {
                          replyingToMessage =
                          null;

                          replyingToMessageRef =
                          null;
                        });
                      },
                    )
                  ],
                ),
              ),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.end,

              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,

                    keyboardType:
                    TextInputType
                        .multiline,

                    minLines: 1,

                    maxLines: 5,

                    style: const TextStyle(
                      color: Colors.black,

                      fontSize: 15,
                    ),

                    cursorColor:
                    Colors.black,

                    decoration:
                    InputDecoration(
                      hintText:
                      'Type a message',

                      filled: true,

                      fillColor:
                      Colors.white,

                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          24,
                        ),

                        borderSide:
                        BorderSide.none,
                      ),

                      isDense: true,
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                IconButton(
                  icon:
                  const Icon(Icons.send),

                  onPressed:
                  _sendMessage,
                )
              ],
            ),
=======
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                ),
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
            )
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
<<<<<<< HEAD

  final String? replyText;

  final bool isMe;

  final dynamic timestamp;

=======
  final bool isMe;
  final dynamic timestamp;
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
  final bool seen;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.seen,
<<<<<<< HEAD
    this.replyText,
=======
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
  });

  @override
  Widget build(BuildContext context) {
    return Align(
<<<<<<< HEAD
      alignment:
      isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: Container(
        margin:
        const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),

        padding:
        const EdgeInsets.all(10),

        constraints:
        const BoxConstraints(
          maxWidth: 280,
        ),

        decoration: BoxDecoration(
          color:
          isMe
              ? Colors.green[100]
              : Colors.grey[200],

          borderRadius:
          BorderRadius.circular(10),
        ),

        child: Column(
          crossAxisAlignment:
          isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,

          children: [
            if (replyText != null &&
                replyText!.isNotEmpty)
              Container(
                margin:
                const EdgeInsets.only(
                  bottom: 6,
                ),

                padding:
                const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: Colors.black12,

                  borderRadius:
                  BorderRadius.circular(
                    8,
                  ),
                ),

                child: Text(
                  replyText!,

                  style: const TextStyle(
                    fontSize: 12,

                    fontStyle:
                    FontStyle.italic,
                  ),
                ),
              ),

            Text(text),

            const SizedBox(height: 4),

            Row(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                Text(
                  _formatSmartDateTime(
                      timestamp),

                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),

                if (isMe) ...[
                  const SizedBox(width: 4),

                  Icon(
                    seen
                        ? Icons.done_all
                        : Icons.done,

                    size: 16,

                    color:
                    seen
                        ? Colors.blue
                        : Colors.grey,
                  ),
=======
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
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  String _formatSmartDateTime(
      dynamic ts) {
    if (ts == null) return '';

    final DateTime dt =
    (ts as Timestamp).toDate();

    final now = DateTime.now();

    final bool isSameDay =
        now.year == dt.year &&
            now.month == dt.month &&
            now.day == dt.day;

    final yesterday =
    now.subtract(
      const Duration(days: 1),
    );

    final bool isYesterday =
        yesterday.year == dt.year &&
            yesterday.month ==
                dt.month &&
            yesterday.day == dt.day;

    final time =
    _formatTimeOnly(dt);
=======
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
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f

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
<<<<<<< HEAD

    if (hour == 0) hour = 12;

    final minute =
    dt.minute
        .toString()
        .padLeft(2, '0');

    final ampm =
    dt.hour >= 12 ? 'PM' : 'AM';
=======
    if (hour == 0) hour = 12;

    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f

    return '$hour:$minute $ampm';
  }

  String _monthName(int m) {
    const months = [
<<<<<<< HEAD
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

=======
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
    return months[m - 1];
  }
}

class PhoneNumberFilter {
  static final RegExp _phoneRegex =
<<<<<<< HEAD
  RegExp(
    r'(\+?\d[\d\s\-]{7,}\d)',
  );

  static bool containsPhoneNumber(
      String text) {
    return _phoneRegex.hasMatch(text);
  }

  static bool
  containsPhoneNumberAcrossMessages(
      List<String> messages,
      ) {
    final combined =
    messages.join(' ');

    return _phoneRegex.hasMatch(
        combined);
  }
}
=======
  RegExp(r'(\+?\d[\d\s\-]{7,}\d)');

  static bool containsPhoneNumber(String text) {
    return _phoneRegex.hasMatch(text);
  }

  static bool containsPhoneNumberAcrossMessages(List<String> messages) {
    final combined = messages.join(' ');
    return _phoneRegex.hasMatch(combined);
  }
}
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
