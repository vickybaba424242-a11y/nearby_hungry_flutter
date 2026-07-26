import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

import '../models/post.dart';
import '../widgets/post_card.dart';
import 'post_detail_page.dart';


class AdminCustomerFeedScreen extends StatefulWidget {

  final String customerId;
  final String customerName;
  final dynamic latitude;
  final dynamic longitude;


  const AdminCustomerFeedScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.latitude,
    required this.longitude,
  });


  @override
  State<AdminCustomerFeedScreen> createState() =>
      _AdminCustomerFeedScreenState();

}



class _AdminCustomerFeedScreenState
    extends State<AdminCustomerFeedScreen> {


  StreamSubscription? _subscription;

  List<Post> posts = [];

  bool loading = true;



  @override
  void initState() {
    super.initState();
    _loadCustomerNearbyPosts();
  }



  @override
  void dispose() {

    _subscription?.cancel();

    super.dispose();

  }




  void _loadCustomerNearbyPosts() {


    if(widget.latitude == null ||
        widget.longitude == null){

      setState(() {
        loading = false;
      });

      return;

    }



    final center = GeoFirePoint(

      GeoPoint(
        (widget.latitude as num).toDouble(),
        (widget.longitude as num).toDouble(),
      ),

    );



    final geoCollection =
    GeoCollectionReference(
        FirebaseFirestore.instance.collection('posts')
    );



    _subscription =
        geoCollection.subscribeWithin(

          center: center,

          radiusInKm: 5,

          field: 'position',


          geopointFrom: (data){


            final pos = data['position'];


            if(pos is Map &&
                pos['geopoint'] is GeoPoint){

              return pos['geopoint'] as GeoPoint;

            }


            return const GeoPoint(0,0);

          },


          strictMode: true,

        )

            .listen((snapshot){


          final nearbyPosts = <Post>[];


          for(final doc in snapshot){


            final data = doc.data();


            if(data == null) continue;


            final post =
            Post.fromMap(
                data,
                doc.id
            );


            // remove customer's own post
            if(post.creatorId ==
                widget.customerId){

              continue;

            }


            nearbyPosts.add(post);


          }



          nearbyPosts.sort(

                (a,b)=>
                b.timestamp!.compareTo(
                    a.timestamp!
                ),

          );



          setState(() {

            posts = nearbyPosts;

            loading = false;

          });



        });


  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(

        backgroundColor:
        const Color(0xFFF94449),


        title: Text(
          "${widget.customerName}'s Feed",
        ),

      ),



      body: loading

          ? const Center(
        child: CircularProgressIndicator(),
      )


          : posts.isEmpty

          ? const Center(
        child: Text(
            "No nearby posts found"
        ),
      )


          : ListView.builder(

        itemCount: posts.length,


        itemBuilder: (context,index){


          final post = posts[index];


          return PostCard(

            post: post,

            isOwnPost: false,


            timeText:
            post.timestamp != null
                ? post.timestamp!
                .toDate()
                .toString()
                : "",


            expireText: null,


            onViewPressed: (){


              showModalBottomSheet(

                context: context,

                isScrollControlled: true,

                builder: (_) =>
                    PostDetailPage(
                      postId: post.id,
                    ),

              );


            },


            onChatPressed: () {},


            onOptionsPressed: () {},

          );


        },

      ),

    );


  }

}