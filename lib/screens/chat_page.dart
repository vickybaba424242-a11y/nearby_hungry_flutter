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
import 'package:flutter/services.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

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

  bool _showSupportInfo = false;
  bool _showChefInfo = false;

  bool _automaticChefMessageChecked = false;

  static const String adminEmail =
      "nearbyhungry@gmail.com";

  bool get isAdminUser {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == adminEmail;
  }

  Future<void> _createOrder() async {
    print('===== CREATE ORDER START =====');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      if (!isCustomer) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only customers can create an order.'),
          ),
        );
        return;
      }

      final userDoc = await _db
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data() ?? {};

      final customerPhone =
      (userData['phone'] ??
          userData['phoneNumber'] ??
          '')
          .toString();

      final address =
      (userData['address'] ??
          userData['fullAddress'] ??
          '')
          .toString();

      final order = OrderModel(
        id: '',
        chatId: chatId,
        customerId: widget.customerId,
        chefId: widget.chefId,
        items: [
          OrderItem(
            postId: 'chat_order',
            foodName: 'Rajma Chawal',
            quantity: 1,
            price: 120,
          ),
        ],
        subtotal: 120,
        deliveryCharge: 30,
        total: 150,
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.pending,
        address: address,
        customerPhone: customerPhone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final orderId = await OrderService.createOrder(
        order: order,
      );

      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'type': 'order',
        'orderId': orderId,
        'senderId': currentUserId,
        'senderRole': 'customer',
        'sentByAdmin': false,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      });

      print('===== ORDER CREATED =====');
      print('ORDER ID: $orderId');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order sent to the chef.'),
        ),
      );
    } catch (e) {
      print('===== ORDER CREATION FAILED =====');
      print(e);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create order: $e'),
        ),
      );
    }
  }

  Future<void> _updateOrderStatus(
      String orderId,
      OrderStatus status,
      ) async {
    try {
      await _db
          .collection('orders')
          .doc(orderId)
          .update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order status updated to ${status.name}.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Order status update failed: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update order: $e',
          ),
        ),
      );
    }
  }

  Future<void> _markOrderPaid(String orderId) async {
    try {
      await _db
          .collection('orders')
          .doc(orderId)
          .update({
        'status': OrderStatus.paid.name,
        'paymentStatus': PaymentStatus.paid.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment marked as completed.'),
        ),
      );
    } catch (e) {
      debugPrint('Payment status update failed: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update payment: $e'),
        ),
      );
    }
  }

  Future<void> _deleteMessage(
      DocumentReference messageRef,
      ) async {

    if (!isAdminUser) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Message"),
        content: const Text(
            "Do you want to delete this message?"),
        actions: [

          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text("Delete"),
          ),

        ],
      ),
    );


    if (confirm == true) {

      await messageRef.delete();

    }
  }

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

    final otherUserId = widget.isAdmin
        ? widget.customerId
        : currentUserId == widget.chefId
        ? widget.customerId
        : widget.chefId;

    final msg = {
      'senderId': widget.isAdmin
          ? widget.chefId
          : currentUserId,

      'senderRole': widget.isAdmin
          ? 'chef'
          : (isCustomer ? 'customer' : 'chef'),

      'sentByAdmin': widget.isAdmin,

      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,

      'replyText': replyingToMessage?['text'],
      'replySenderId': replyingToMessage?['senderId'],
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

    final otherUserId = widget.customerId;

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
                        if (data['type'] == 'order')
                          OrderBubble(
                            orderId: data['orderId'] ?? '',
                            isMe: isMe,
                          )
                        else if (data['type'] == 'location')
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
                            GestureDetector(
                              onLongPress: isAdminUser
                                  ? () {
                                _deleteMessage(
                                  docs[index].reference,
                                );
                              }
                                  : null,
                              child: MessageBubble(
                                text: data['text'] ?? '',
                                replyText: data['replyText'],
                                isMe: isMe,
                                timestamp: data['timestamp'],
                                seen: data['seen'] == true,
                              ),
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
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.orange.shade200,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _showSupportInfo = !_showSupportInfo;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.support_agent,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Need help with your order?",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _showSupportInfo
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_showSupportInfo)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                0,
                12,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  const Text(
                    "To place your order faster, contact the Nearby Hungry Team on WhatsApp.\n"
                        "And to make a payment, tap the ➕ icon and select the Payment option 💳.",
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  InkWell(
                    onTap: _openSupportWhatsApp,
                    child: const Text(
                      "📱 +91 82877 46086",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChefMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.green.shade200,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _showChefInfo = !_showChefInfo;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Important for Chefs",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _showChefInfo
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_showChefInfo)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                0,
                12,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1),
                  SizedBox(height: 8),

                  Text(
                    "⚠️ Before preparing the order, ask the customer to complete "
                        "the payment and share the payment screenshot.\n"
                        "Payment will be released by Nearby Hungry after successful "
                        "delivery.\n"
                        "Note: Payment & screenshot options are for customers only.",
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
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

class OrderBubble extends StatelessWidget {
  final String orderId;
  final bool isMe;

  const OrderBubble({
    super.key,
    required this.orderId,
    required this.isMe,
  });

  Future<void> _updateStatus(
      BuildContext context,
      OrderStatus status,
      ) async {
    try {
      final db = FirebaseFirestore.instance;

      // Get order
      final orderDoc = await db
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData =
      orderDoc.data() as Map<String, dynamic>;

      final chatId = orderData['chatId']?.toString();
      final chefId = orderData['chefId']?.toString();
      final customerId =
      orderData['customerId']?.toString();

      final total =
          (orderData['total'] as num?)?.toDouble() ?? 0;

      if (chatId == null || chatId.isEmpty) {
        throw Exception('Chat ID not found');
      }

      if (chefId == null || chefId.isEmpty) {
        throw Exception('Chef ID not found');
      }

      if (customerId == null || customerId.isEmpty) {
        throw Exception('Customer ID not found');
      }

      // ----------------------------------------
      // 1. UPDATE ORDER STATUS
      // ----------------------------------------

      await db
          .collection('orders')
          .doc(orderId)
          .update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ----------------------------------------
      // 2. SEND PAYMENT MESSAGE ONLY AFTER
      //    CHEF ACCEPTS THE ORDER
      // ----------------------------------------

      if (status == OrderStatus.accepted) {
        final paymentMessage =
            '✅ Your order has been accepted by the chef.\n\n'
            '💳 Please complete the payment of '
            '₹${total.toStringAsFixed(0)} '
            'to confirm your order.\n\n'
            'After making the payment, tap "I Have Paid" '
            'on the order.';

        await db
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'type': 'payment_request',
          'text': paymentMessage,
          'orderId': orderId,
          'amount': total,
          'senderId': chefId,
          'senderRole': 'chef',
          'sentByAdmin': false,
          'timestamp': FieldValue.serverTimestamp(),
          'seen': false,
        });

        // Update chat preview
        await db
            .collection('chats')
            .doc(chatId)
            .set({
          'chefId': chefId,
          'customerId': customerId,
          'participants': [
            chefId,
            customerId,
          ],
          'lastMessage': paymentMessage,
          'lastMessageTime':
          FieldValue.serverTimestamp(),
          'unreadCount_$customerId':
          FieldValue.increment(1),
        }, SetOptions(merge: true));
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == OrderStatus.accepted
                ? 'Order accepted. Payment request sent.'
                : 'Order updated to ${status.name}.',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Order status update failed: $e',
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update order: $e',
          ),
        ),
      );
    }
  }

  Future<void> _markPaid(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': OrderStatus.paid.name,
        'paymentStatus': PaymentStatus.paid.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment marked as completed.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update payment: $e',
          ),
        ),
      );
    }
  }

  Future<void> _openPayment(
      BuildContext context,
      OrderModel order,
      ) async {
    try {
      await PaymentService.openUPI(
        context,
        isCustomer: true,
        chatId: order.chatId,
        senderId: order.customerId,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open payment: $e',
          ),
        ),
      );
    }
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(
      BuildContext context,
      OrderModel order,
      ) {
    final actions = <Widget>[];

    /*
     * CHEF ACTIONS
     */

    if (!isMe && order.status == OrderStatus.pending) {
      actions.add(
        _actionButton(
          text: 'Accept Order',
          icon: Icons.check_circle,
          color: Colors.green,
          onPressed: () {
            _updateStatus(
              context,
              OrderStatus.accepted,
            );
          },
        ),
      );

      actions.add(
        const SizedBox(height: 8),
      );

      actions.add(
        _actionButton(
          text: 'Reject Order',
          icon: Icons.cancel,
          color: Colors.red,
          onPressed: () {
            _updateStatus(
              context,
              OrderStatus.rejected,
            );
          },
        ),
      );
    }

    if (!isMe &&
        (order.status == OrderStatus.accepted ||
            order.status == OrderStatus.paid)) {
      actions.add(
        _actionButton(
          text: 'Start Preparing',
          icon: Icons.restaurant,
          color: Colors.deepOrange,
          onPressed: () {
            _updateStatus(
              context,
              OrderStatus.preparing,
            );
          },
        ),
      );
    }

    if (!isMe &&
        order.status == OrderStatus.preparing) {
      actions.add(
        _actionButton(
          text: 'Mark Picked Up',
          icon: Icons.delivery_dining,
          color: Colors.blue,
          onPressed: () {
            _updateStatus(
              context,
              OrderStatus.pickedUp,
            );
          },
        ),
      );
    }

    if (!isMe &&
        order.status == OrderStatus.pickedUp) {
      actions.add(
        _actionButton(
          text: 'Mark Delivered',
          icon: Icons.check_circle,
          color: Colors.green,
          onPressed: () {
            _updateStatus(
              context,
              OrderStatus.delivered,
            );
          },
        ),
      );
    }

    /*
     * CUSTOMER ACTIONS
     */

    if (isMe &&
        order.status == OrderStatus.accepted &&
        order.paymentStatus == PaymentStatus.pending) {
      actions.add(
        _actionButton(
          text: 'Pay ₹${order.total.toStringAsFixed(0)}',
          icon: Icons.payment,
          color: Colors.blue,
          onPressed: () {
            _openPayment(
              context,
              order,
            );
          },
        ),
      );
    }

    /*
     * CUSTOMER PAYMENT CONFIRMATION
     *
     * This button is intentionally separate from opening UPI.
     * Opening UPI does NOT automatically mean payment succeeded.
     */

    if (isMe &&
        order.status == OrderStatus.accepted &&
        order.paymentStatus == PaymentStatus.pending) {
      actions.add(
        const SizedBox(height: 8),
      );

      actions.add(
        _actionButton(
          text: 'I Have Paid',
          icon: Icons.verified,
          color: Colors.green,
          onPressed: () {
            _markPaid(context);
          },
        ),
      );
    }

    /*
     * CUSTOMER DELIVERY CONFIRMATION
     */

    if (isMe &&
        order.status == OrderStatus.pickedUp) {
      actions.add(
        _actionButton(
          text: 'Confirm Delivery',
          icon: Icons.check_circle,
          color: Colors.green,
          onPressed: () {
            _updateStatus(
              context,
              OrderStatus.delivered,
            );
          },
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderModel?>(
      stream: OrderService.listenToOrder(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Align(
            alignment:
            isMe
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final order = snapshot.data;

        if (order == null) {
          return Align(
            alignment:
            isMe
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(14),
              ),
              child: const Text(
                'Order is no longer available.',
              ),
            ),
          );
        }

        final actions =
        _buildActions(context, order);

        return Align(
          alignment:
          isMe
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            width: 320,
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  Colors.black.withOpacity(0.06),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'ORDER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                    _statusChip(order.status),
                  ],
                ),

                const SizedBox(height: 12),

                ...order.items.map(
                      (item) => Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.foodName} × ${item.quantity}',
                            style:
                            const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(),

                _priceRow(
                  'Subtotal',
                  order.subtotal,
                ),

                _priceRow(
                  'Delivery',
                  order.deliveryCharge,
                ),

                const SizedBox(height: 4),

                _priceRow(
                  'Total',
                  order.total,
                  bold: true,
                ),

                const SizedBox(height: 10),

                Text(
                  _statusText(order.status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    _statusColor(
                      order.status,
                    ),
                  ),
                ),

                if (order.paymentStatus ==
                    PaymentStatus.paid) ...[
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 17,
                        color: Colors.green,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Payment completed',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...actions,
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _priceRow(
      String title,
      double amount, {
        bool bold = false,
      }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight:
                bold
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight:
              bold
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
      OrderStatus status,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
        _statusColor(status)
            .withOpacity(0.12),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          fontSize: 11,
          fontWeight:
          FontWeight.bold,
          color:
          _statusColor(status),
        ),
      ),
    );
  }

  String _statusText(
      OrderStatus status,
      ) {
    switch (status) {
      case OrderStatus.pending:
        return '⏳ Waiting for chef';

      case OrderStatus.accepted:
        return '✅ Chef accepted the order';

      case OrderStatus.modified:
        return '✏️ Order modified';

      case OrderStatus.rejected:
        return '❌ Order rejected';

      case OrderStatus.paid:
        return '💳 Payment completed';

      case OrderStatus.preparing:
        return '👨‍🍳 Order is being prepared';

      case OrderStatus.pickedUp:
        return '🛵 Order picked up';

      case OrderStatus.delivered:
        return '🎉 Order delivered';

      case OrderStatus.cancelled:
        return '❌ Order cancelled';
    }
  }

  Color _statusColor(
      OrderStatus status,
      ) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;

      case OrderStatus.accepted:
        return Colors.green;

      case OrderStatus.modified:
        return Colors.blue;

      case OrderStatus.rejected:
        return Colors.red;

      case OrderStatus.paid:
        return Colors.green;

      case OrderStatus.preparing:
        return Colors.deepOrange;

      case OrderStatus.pickedUp:
        return Colors.blue;

      case OrderStatus.delivered:
        return Colors.green;

      case OrderStatus.cancelled:
        return Colors.red;
    }
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

            GestureDetector(
              onLongPress: () {
                Clipboard.setData(
                  ClipboardData(text: text),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Message copied"),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ),

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