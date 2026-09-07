import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ChefReviewsScreen extends StatefulWidget {

  final String chefId;
  final String chefName;


  const ChefReviewsScreen({
    super.key,
    required this.chefId,
    required this.chefName,
  });


  @override
  State<ChefReviewsScreen> createState() =>
      _ChefReviewsScreenState();

}



class _ChefReviewsScreenState
    extends State<ChefReviewsScreen> {


  int selectedRating = 0;
  bool hasExistingReview = false;

  final TextEditingController reviewController =
  TextEditingController();

  Future<DocumentSnapshot> getChefData() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.chefId)
        .get();
  }

  Future<void> updateChefRating() async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Get all ratings for this chef/restaurant
      final ratingsSnapshot = await firestore
          .collection('ratings')
          .where(
        'chefId',
        isEqualTo: widget.chefId,
      )
          .get();

      double averageRating = 0.0;
      int totalRatings = ratingsSnapshot.docs.length;

      if (totalRatings > 0) {
        double totalRating = 0.0;

        for (final doc in ratingsSnapshot.docs) {
          final data = doc.data();

          final ratingValue = data['rating'];

          if (ratingValue is num) {
            totalRating += ratingValue.toDouble();
          }
        }

        averageRating = totalRating / totalRatings;

        averageRating =
            double.parse(averageRating.toStringAsFixed(1));
      }

      debugPrint(
        "⭐ Chef/Restaurant ID: ${widget.chefId}",
      );

      debugPrint(
        "⭐ Average Rating: $averageRating",
      );

      debugPrint(
        "⭐ Total Ratings: $totalRatings",
      );

      // =====================================================
      // UPDATE USER PROFILE
      // =====================================================

      await firestore
          .collection('users')
          .doc(widget.chefId)
          .set(
        {
          'rating': averageRating,
          'totalRatings': totalRatings,
        },
        SetOptions(merge: true),
      );

      // =====================================================
      // UPDATE ALL POSTS
      // =====================================================

      final postsSnapshot = await firestore
          .collection('posts')
          .where(
        'creatorId',
        isEqualTo: widget.chefId,
      )
          .get();

      debugPrint(
        "📌 Posts found for provider: ${postsSnapshot.docs.length}",
      );

      for (final post in postsSnapshot.docs) {
        await post.reference.update({
          'rating': averageRating,
          'totalRatings': totalRatings,
        });

        debugPrint(
          "✅ Rating updated for post: ${post.id}",
        );
      }

      debugPrint(
        "✅ Rating update completed successfully",
      );
    } catch (e, stackTrace) {
      debugPrint(
        "❌ Rating update error: $e",
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    loadMyReview();
  }

  Future<void> loadMyReview() async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;


    final ratingId =
        "${widget.chefId}_${user.uid}";


    final doc =
    await FirebaseFirestore.instance
        .collection('ratings')
        .doc(ratingId)
        .get();


    if (doc.exists) {

      final data = doc.data()!;


      setState(() {

        selectedRating =
            data['rating'] ?? 0;


        reviewController.text =
            data['review'] ?? "";


        hasExistingReview = true;

      });

    }

  }



  Future<void> submitReview() async {


    final user =
        FirebaseAuth.instance.currentUser;



    if (user == null) {
      return;
    }



    if (selectedRating == 0) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select rating",
          ),
        ),
      );

      return;
    }



    if (reviewController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please write review",
          ),
        ),
      );

      return;
    }



    final ratingId =
        "${widget.chefId}_${user.uid}";


    await FirebaseFirestore.instance
        .collection('ratings')
        .doc(ratingId)
        .set({

      "chefId": widget.chefId,
      "userId": user.uid,
      "userName": user.displayName ?? "User",
      "rating": selectedRating,
      "review": reviewController.text.trim(),
      "createdAt": Timestamp.now(),

    }, SetOptions(merge: true));
    await updateChefRating();

    setState(() {
      hasExistingReview = true;
    });
    await loadMyReview();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
        Text(
          "Review submitted successfully",
        ),
      ),
    );

  }





  Widget buildStars() {


    return Row(

      mainAxisAlignment:
      MainAxisAlignment.center,


      children:

      List.generate(
        5,

            (index) {

          return IconButton(

            onPressed: () {


              setState(() {


                selectedRating =
                    index + 1;


              });


            },


            icon: Icon(

              index < selectedRating
                  ? Icons.star
                  : Icons.star_border,


              color:
              Colors.amber,


              size:
              35,

            ),

          );


        },

      ),

    );


  }





  @override
  Widget build(BuildContext context) {


    print(
        "Reviews Screen Chef ID: ${widget.chefId}"
    );


    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF94449),
        foregroundColor: Colors.white,
        title: Column(
          children: [
            Text(
              widget.chefName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "Customer Reviews",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),



      body: Column(

        children: [



          // WRITE REVIEW SECTION

          Card(

            margin:
            const EdgeInsets.all(12),


            child:

            Padding(

              padding:
              const EdgeInsets.all(12),


              child:

              Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,


                children: [


                  const Text(
                    "⭐ Rate Your Experience",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),



                  buildStars(),




                  TextField(
                    controller: reviewController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Tell others about the food...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.all(18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Colors.deepOrange,
                          width: 2,
                        ),
                      ),
                    ),
                  ),




                  const SizedBox(
                    height:10,
                  ),




                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: submitReview,
                      icon: const Icon(Icons.send_rounded),
                      label: Text(
                        hasExistingReview
                            ? "Update Review"
                            : "Submit Review",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF94449),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),


                ],

              ),

            ),

          ),



          const Divider(),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.reviews,
                  color: Color(0xFFF94449),
                ),
                SizedBox(width: 8),
                Text(
                  "Customer Reviews",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),



          Expanded(

            child:

            StreamBuilder<QuerySnapshot>(


              stream:

              FirebaseFirestore.instance

                  .collection('ratings')

                  .where(
                'chefId',
                isEqualTo:
                widget.chefId,
              )

                  .orderBy(
                'createdAt',
                descending:
                true,
              )

                  .snapshots(),




              builder:
                  (context, snapshot) {



                if (snapshot.connectionState ==
                    ConnectionState.waiting) {


                  return const Center(

                    child:
                    CircularProgressIndicator(),

                  );

                }




                final docs =
                    snapshot.data?.docs ?? [];





                if (docs.isEmpty) {


                  return const Center(

                    child:
                    Text(
                      "No reviews yet",
                    ),

                  );

                }





                return ListView.builder(


                  itemCount:
                  docs.length,



                  itemBuilder:
                      (context, index) {


                    final data =
                    docs[index];

                    final Timestamp timestamp = data['createdAt'];

                    final DateTime reviewDate = timestamp.toDate();

                    return Card(
                      elevation: 5,
                      color: Colors.white,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: [

                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.deepOrange,
                                  child: Text(
                                    data['userName']
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        data['userName'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),

                                      const SizedBox(height: 2),

                                      Text(
                                        "${reviewDate.day}/${reviewDate.month}/${reviewDate.year}",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [

                                      const Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 14,
                                      ),

                                      const SizedBox(width: 3),

                                      Text(
                                        "${data['rating']}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),

                              ],
                            ),

                            const SizedBox(height: 15),

                            Text(
                              data['review'],
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),

                          ],
                        ),
                      ),
                    );


                  },


                );


              },


            ),

          ),

        ],

      ),

    );

  }


}