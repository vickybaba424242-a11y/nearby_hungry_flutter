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

  final TextEditingController _controller =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  Map<String, dynamic>? replyingToMessage;

  DocumentReference? replyingToMessageRef;

  final Color homeBg =
  const Color(0xFFFFE0B2);

  late final String currentUserId;

  late final String chatId;

  StreamSubscription<DocumentSnapshot>? _hiddenSub;

  final List<String> _recentUserMessages = [];

  static const int _maxTrackedMessages = 10;

  @override
  void initState() {
    super.initState();

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    currentUserId = user.uid;

    final a = widget.chefId;
    final b = widget.customerId;

    chatId =
    a.compareTo(b) < 0
        ? '${a}_$b'
        : '${b}_$a';

    _markAsRead();

    _listenHiddenChat();
  }

  @override
  void dispose() {
    _controller.dispose();

    _scrollController.dispose();

    _hiddenSub?.cancel();

    super.dispose();
  }

  Future<void> _markAsRead() async {
    await _db.collection('chats').doc(chatId).set({
      'unreadCount_$currentUserId': 0,
      'isRead_$currentUserId': true,
    }, SetOptions(merge: true));
  }

  void _listenHiddenChat() {
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
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

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
        _recentUserMessages);

    if (isSingleBlocked || isMultiBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sharing phone numbers is not allowed.',
          ),
        ),
      );

      _recentUserMessages.clear();

      return;
    }

    _controller.clear();

    final otherUserId =
    currentUserId == widget.chefId
        ? widget.customerId
        : widget.chefId;

    final msg = {
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,

      // reply feature
      'replyText':
      replyingToMessage?['text'],

      'replySenderId':
      replyingToMessage?['senderId'],
    };

    final updates = {
      'chefId': widget.chefId,

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
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:
        Color(0xFFFFE0B2),

        statusBarIconBrightness:
        Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: homeBg,

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
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/chat_background.jpg',

              fit: BoxFit.cover,
            ),
          ),

          Column(
            children: [
              Expanded(
                child: _buildMessages(),
              ),

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
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
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
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;

  final String? replyText;

  final bool isMe;

  final dynamic timestamp;

  final bool seen;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.seen,
    this.replyText,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
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
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

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

    final minute =
    dt.minute
        .toString()
        .padLeft(2, '0');

    final ampm =
    dt.hour >= 12 ? 'PM' : 'AM';

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