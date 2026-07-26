import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AdminChatPage extends StatefulWidget {

  final String customerId;
  final String customerName;


  const AdminChatPage({
    super.key,
    required this.customerId,
    required this.customerName,
  });


  @override
  State<AdminChatPage> createState() =>
      _AdminChatPageState();

}



class _AdminChatPageState
    extends State<AdminChatPage> {


  @override
  Widget build(BuildContext context) {


    final adminId =
        FirebaseAuth.instance.currentUser!.uid;


    return ChatPage(

      chefId: adminId,

      customerId: widget.customerId,

      chefName: widget.customerName,

      isAdmin: true,

    );


  }

}