import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_customer_feed_screen.dart';
import 'admin_chat_page.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {

  final TextEditingController _searchController =
  TextEditingController();

  String searchText = "";
  String enteredText = "";
  bool hasText = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Customers"),
        backgroundColor: const Color(0xFFF94449),
      ),


      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),


        builder: (context, snapshot) {


          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(),
            );

          }



          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {

            return const Center(
              child: Text("No customers found"),
            );

          }



          final customers =
          snapshot.data!.docs.where((doc) {


            final data =
            doc.data() as Map<String, dynamic>;


            final username =
            (data['username'] ?? "")
                .toString()
                .toLowerCase();


            final email =
            (data['email'] ?? "")
                .toString()
                .toLowerCase();



            return username.contains(searchText) ||
                email.contains(searchText);


          }).toList();



          return Column(

            children: [


              Padding(

                padding: const EdgeInsets.all(12),

                child: TextField(

                  controller: _searchController,

                  decoration: InputDecoration(

                    hintText: "Search customer...",

                    prefixIcon: const Icon(Icons.search),

                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {

                            setState(() {

                              searchText =
                                  enteredText.toLowerCase();

                            });

                          },
                        ),


                        if (hasText)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {

                              _searchController.clear();

                              setState(() {

                                enteredText = "";
                                searchText = "";

                              });

                            },
                          ),

                      ],
                    ),

                    border: OutlineInputBorder(

                      borderRadius:
                      BorderRadius.circular(12),

                    ),

                  ),


                  onChanged: (value) {

                    enteredText = value;

                    hasText = value.isNotEmpty;

                  },

                ),

              ),



              Expanded(

                child: customers.isEmpty

                    ? const Center(
                  child: Text(
                    "No customer found",
                  ),
                )


                    : ListView.builder(

                  itemCount:
                  customers.length,


                  itemBuilder:
                      (context, index) {


                    final data =
                    customers[index].data()
                    as Map<String, dynamic>;



                    return ListTile(


                      leading: CircleAvatar(

                        child: Text(
                          _getFirstLetter(data),
                        ),

                      ),



                      title: Text(

                        data['username'] ??
                            "Unknown User",

                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),

                      ),



                      subtitle: Text(

                        data['email'] ?? "",

                      ),



                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          IconButton(
                            icon: const Icon(
                              Icons.chat,
                              color: Colors.green,
                            ),

                            tooltip: "Chat with customer",

                            onPressed: () {

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminChatPage(
                                    customerId: customers[index].id,
                                    customerName:
                                    data['username'] ??
                                        "Unknown User",
                                  ),
                                ),
                              );

                            },

                          ),


                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                          ),

                        ],
                      ),



                      onTap: () {


                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) =>
                                AdminCustomerFeedScreen(

                                  customerId:
                                  customers[index].id,


                                  customerName:
                                  data['username'] ??
                                      "Unknown User",


                                  latitude:
                                  data['latitude'],


                                  longitude:
                                  data['longitude'],

                                ),

                          ),

                        );


                      },


                    );


                  },

                ),

              ),

            ],

          );


        },

      ),

    );

  }



  String _getFirstLetter(
      Map<String, dynamic> data) {


    final name =
    (data['username'] ?? '')
        .toString()
        .trim();



    if (name.isNotEmpty) {

      return name[0]
          .toUpperCase();

    }



    final email =
    (data['email'] ?? '')
        .toString()
        .trim();



    if (email.isNotEmpty) {

      return email[0]
          .toUpperCase();

    }



    return "U";

  }

}