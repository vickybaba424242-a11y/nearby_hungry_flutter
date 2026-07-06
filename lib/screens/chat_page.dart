import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../active_chat.dart';
import '../chat/services/location_service.dart';
import '../chat/widgets/location_bubble.dart';
import '../chat/payment/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  final String chefId;
  final String customerId;
  final String? chefName;
  final bool isAdmin;

  const ChatPage({
    super.key,
    required this.chefId,
    required this.customerId,
    this.chefName,
    this.isAdmin = false,
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

  final Color homeBg = const Color(0xFFF8F7F4);

  late final String currentUserId;

  late final String chatId;

  static const String supportNumber = "918287746086";

  bool get isCustomer => currentUserId == widget.customerId;
  StreamSubscription<DocumentSnapshot>? _hiddenSub;

  final List<String> _recentUserMessages = [];

  static const int _maxTrackedMessages = 10;

  bool _showAttachmentMenu = false;

  Future<void> _openSupportWhatsApp() async {
    final Uri uri = Uri.parse(
      "https://api.whatsapp.com/send?phone=$supportNumber&text=${Uri.encodeComponent("Hi Nearby Hungry Support, I want to place an order.")}",
    );

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to open WhatsApp."),
        ),
      );
    }
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
      ),
    );
  }

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
    ActiveChat.chatId = chatId;

    if (!widget.isAdmin) {
      _markAsRead();
    }

    _listenHiddenChat();
  }

  @override
  void dispose() {

    ActiveChat.chatId = null;
    _controller.dispose();

    _scrollController.dispose();

    _hiddenSub?.cancel();

    super.dispose();
  }

  Future<void> _markAsRead() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;
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
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Message Not Sent'),
          content: const Text(
            'Your message appears to contain contact information or an attempt to share personal details.\n\n'
                'To keep everyone safe, Nearby Hungry does not allow sharing:\n'
                '• Phone numbers\n'
                '• Email addresses\n'
                '• WhatsApp, Telegram or social media IDs\n'
                '• Other personal contact details\n\n'
                'Menu items, prices, and food details are allowed.\n\n'
                'Please remove any contact information and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
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

  Future<void> _shareCurrentLocation() async {
    final shouldShare = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Share Location"),
        content: const Text(
          "Do you want to share your current location with the other user?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Share"),
          ),
        ],
      ),
    );

    if (shouldShare != true) return;

    final otherUserId =
    currentUserId == widget.chefId
        ? widget.customerId
        : widget.chefId;

    try {
      await LocationService.shareLocation(
        chatId: chatId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
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
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        scrolledUnderElevation: 0,

        leading: const BackButton(
          color: Colors.black,
        ),

        titleSpacing: 0,

        title: FutureBuilder<DocumentSnapshot>(
          future: _db.collection('users').doc(
            widget.isAdmin
                ? widget.customerId
                : currentUserId == widget.chefId
                ? widget.customerId
                : widget.chefId,
          ).get(),
          builder: (context, snapshot) {
            String userName = "User";
            String? image;

            if (snapshot.hasData &&
                snapshot.data!.exists) {
              final data =
              snapshot.data!.data()
              as Map<String, dynamic>;

              userName =
                  data['username'] ??
                      data['name'] ??
                      "User";

              image = data['profileImage'];
            }

            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                  image != null
                      ? NetworkImage(image)
                      : null,
                  child: image == null
                      ? const Icon(Icons.person)
                      : null,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Chat",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 10,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.home_rounded,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.of(context).popUntil(
                        (route) => route.isFirst,
                  );
                },
              ),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/chat_background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          ),

          Column(
            children: [

              if (!widget.isAdmin)
                if (isCustomer)
                  _buildSupportMessage()
                else
                  _buildChefMessage(),

              Expanded(
                child: _buildMessages(),
              ),

              if (!widget.isAdmin)
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

            bool isMe;

            if (widget.isAdmin) {
              isMe = data['senderId'] == widget.chefId;
            } else {
              isMe = data['senderId'] == currentUserId;
            }

            // seen update
            if (!widget.isAdmin &&
                !isMe &&
                data['seen'] != true) {
              final user = FirebaseAuth.instance.currentUser;

              if (user != null) {
                docs[index].reference.update({
                  'seen': true,
                }).catchError((e) {
                  debugPrint('Seen update failed: $e');
                });
              }
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
                        if (data['type'] == 'location')
                          LocationBubble(
                            latitude: (data['latitude'] as num).toDouble(),
                            longitude: (data['longitude'] as num).toDouble(),
                            address: data['address'] ?? '',
                            isMe: isMe,
                            timestamp: data['timestamp'],
                          )
                        else if (data['type'] == 'image')
                          ImageBubble(
                            imageUrl: data['imageUrl'],
                            isMe: isMe,
                            timestamp: data['timestamp'],
                          )
                        else
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

  Widget _buildSupportMessage() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.support_agent,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Text(
                "Nearby Hungry",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            "If you want to place your order faster, contact the Nearby Hungry Team on WhatsApp.",
            style: TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 12),

          InkWell(
            onTap: _openSupportWhatsApp,
            child: const Text(
              "📱 +91 82877 46086",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChefMessage() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(
                Icons.restaurant,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text(
                "Important for Chefs",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          SizedBox(height: 6),

          Text(
            "Before you start preparing the order:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 4),

          Text(
            "⚠️ Before preparing the order, ask the customer to complete the payment and share the payment screenshot.\n"
                "Your payment will be released by Nearby Hungry after successful delivery.\n"
                "Note: Payment and screenshot options are available only for customers.",
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return SafeArea(
      child: Container(
        color: Colors.transparent,

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
                    IconButton(
                      icon: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                      onPressed: _shareCurrentLocation,
                    ),
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Payment button
                    // Payment button (Customer only)
                    if (_showAttachmentMenu && isCustomer)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildAttachmentButton(
                          icon: Icons.payment,
                          color: Colors.blue,
                          onTap: () async {
                            setState(() => _showAttachmentMenu = false);

                            await PaymentService.openUPI(
                              context,
                              isCustomer: isCustomer,
                              chatId: chatId,
                              senderId: currentUserId,
                            );
                          },
                        ),
                      ),

                    // Location button
                    if (_showAttachmentMenu)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildAttachmentButton(
                          icon: Icons.location_on,
                          color: Colors.green,
                          onTap: () {
                            setState(() => _showAttachmentMenu = false);
                            _shareCurrentLocation();
                          },
                        ),
                      ),

                    // Plus button
                    _buildAttachmentButton(
                      icon: _showAttachmentMenu ? Icons.close : Icons.add,
                      color: Colors.orange,
                      onTap: () {
                        setState(() {
                          _showAttachmentMenu = !_showAttachmentMenu;
                        });
                      },
                    ),
                  ],
                ),

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

                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget
{
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

          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(
                isMe ? 18 : 4),
            bottomRight: Radius.circular(
                isMe ? 4 : 18),
          ),
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

class ImageBubble extends StatelessWidget {
  final String imageUrl;
  final bool isMe;
  final dynamic timestamp;

  const ImageBubble({
    super.key,
    required this.imageUrl,
    required this.isMe,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
      isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullImagePage(imageUrl: imageUrl),
                ),
              );
            },
            child: Image.network(
              imageUrl,
              width: 220,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class FullImagePage extends StatelessWidget {
  final String imageUrl;

  const FullImagePage({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

class PhoneNumberFilter {
  static bool containsPhoneNumber(String text) {
    final lower = text.toLowerCase();

    // Email detection
    if (RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    ).hasMatch(text)) {
      return true;
    }

    // Digits only
    // Detect real Indian phone numbers
    final phoneRegex = RegExp(
      r'(?<!\d)(?:\+91[- ]?)?[6-9]\d{9}(?!\d)',
    );

    if (phoneRegex.hasMatch(text)) {
      return true;
    }

    // Number words
    const numberWords = [
      'zero','one','two','three','four',
      'five','six','seven','eight','nine'
    ];

    int count = 0;

    for (final word in lower.split(RegExp(r'\s+'))) {
      if (numberWords.contains(word)) {
        count++;
      }
    }

    if (count >= 5) {
      return true;
    }

    const blockedWords = [
      'whatsapp',
      'call me',
      'phone',
      'mobile',
      'contact me',
      'telegram',
      'instagram',
      'dm me',
      'reach me',
      'text me',
      'gmail',
      'email',
      'snapchat',
      'facebook',
      'my number',
      'contact number',
    ];

    return blockedWords.any(
          (word) => lower.contains(word),
    );
  }

  static bool containsPhoneNumberAcrossMessages(
      List<String> messages,
      ) {
    final combined = messages.join(' ').toLowerCase();

    return containsPhoneNumber(combined);
  }
}