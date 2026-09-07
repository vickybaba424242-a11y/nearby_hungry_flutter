import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/admin_customer_feed_screen.dart';
import '../screens/admin_chat_page.dart';
import 'package:cloud_functions/cloud_functions.dart';


class LocationSearchPage extends StatefulWidget {

  const LocationSearchPage({super.key});


  @override
  State<LocationSearchPage> createState() =>
      _LocationSearchPageState();

}
class _LocationSearchPageState
    extends State<LocationSearchPage> {
  final TextEditingController controller =
  TextEditingController();
  final FlutterGooglePlacesSdk places =
  FlutterGooglePlacesSdk(
      "AIzaSyC_fskYCZEOJyS_67Yxa-N-qZA7EuQPhYY"
  );
  List<AutocompletePrediction> results = [];
  double? selectedLatitude;
  double? selectedLongitude;
  String selectedLocation = "";
  List<QueryDocumentSnapshot> nearbyCustomers = [];
  bool searchingCustomers = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  Future<bool> sendMessageToCustomers(String message) async {
    print("Calling Cloud Function");

    try {
      final callable =
      FirebaseFunctions.instance.httpsCallable(
        "sendNearbyCustomerNotification",
      );

      final result = await callable.call({
        "latitude": selectedLatitude,
        "longitude": selectedLongitude,
        "radius": 5,
        "title": "Nearby Hungry",
        "body": message,
      });

      print("Function Response:");
      print(result.data);

      return true;
    } on FirebaseFunctionsException catch (e) {
      print("❌ Firebase Function Error");
      print("Code: ${e.code}");
      print("Message: ${e.message}");
      print("Details: ${e.details}");

      return false;
    } catch (e, st) {
      print("❌ Unknown Function Error: $e");
      print(st);

      return false;
    }
  }
  void showSendMessageDialog(){
    TextEditingController messageController =
    TextEditingController();
    showDialog(
      context: context,
      builder:(context){
        return AlertDialog(
          title:
          const Text(
            "Send Message To All Customers",
          ),
          content:
          TextField(
            controller:
            messageController,
            maxLines:
            5,
            decoration:
            const InputDecoration(
              hintText:
              "Enter your message",
              border:
              OutlineInputBorder(),
            ),
          ),
          actions:[
            TextButton(
              child:
              const Text("Cancel"),
              onPressed:(){
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child:
              const Text("Send"),
              onPressed: () async {
                final message = messageController.text.trim();

                if (message.isEmpty) {
                  return;
                }

                final success = await sendMessageToCustomers(message);

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Message sent successfully"
                          : "Failed to send message",
                    ),
                  ),
                );
              },
            )
          ],
        );
      },
    );
  }
  Future<void> searchLocation(String value) async {
    if(value.trim().isEmpty){
      setState(() {
        results = [];
      });
      return;
    }
    final response =
    await places.findAutocompletePredictions(
      value,
      countries: [
        "IN"
      ],
    );
    setState(() {
      results =
          response.predictions;
    });
  }
  Future<void> selectLocation(
      AutocompletePrediction place) async {
    final detail =
    await places.fetchPlace(
      place.placeId,
      fields: [
        PlaceField.Location,
      ],
    );
    if(detail.place?.latLng == null){
      return;
    }
    selectedLatitude =
        detail.place!.latLng!.lat;
    selectedLongitude =
        detail.place!.latLng!.lng;
    setState(() {
      selectedLocation =
      "${place.primaryText}, ${place.secondaryText}";
      controller.text =
          selectedLocation;
      results = [];
      searchingCustomers = true;
    });
    await loadNearbyCustomers();
  }
  Future<void> loadNearbyCustomers() async {
    if(selectedLatitude == null ||
        selectedLongitude == null){
      return;
    }
    final snapshot =
    await FirebaseFirestore.instance
        .collection("users")
        .get();
    List<QueryDocumentSnapshot> temp = [];
    for(var doc in snapshot.docs){
      final data =
      doc.data() as Map<String,dynamic>;
      if(data["latitude"] == null ||
          data["longitude"] == null){
        continue;
      }
      double userLat =
      double.parse(
          data["latitude"].toString()
      );
      double userLng =
      double.parse(
          data["longitude"].toString()
      );
      double distance =
      calculateDistance(
        selectedLatitude!,
        selectedLongitude!,
        userLat,
        userLng,
      );
      if(distance <= 5){
        temp.add(doc);
      }
    }
    setState(() {
      nearbyCustomers = temp;
      searchingCustomers = false;
    });
  }
  double calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2
      ){
    const earthRadius = 6371;
    double dLat =
        (lat2-lat1) *
            pi /
            180;
    double dLon =
        (lon2-lon1) *
            pi /
            180;
    double a =
        sin(dLat/2) *
            sin(dLat/2)
            +
            cos(lat1*pi/180) *
                cos(lat2*pi/180)
                *
                sin(dLon/2) *
                sin(dLon/2);
    double c =
        2 *
            atan2(
                sqrt(a),
                sqrt(1-a)
            );
    return earthRadius*c;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
            "Search Customer Location"
        ),
        backgroundColor:
        const Color(0xFFF94449),
        actions: [
          if(nearbyCustomers.isNotEmpty)
            IconButton(
              icon:
              const Icon(
                  Icons.campaign
              ),
              tooltip:
              "Send message to all",
              onPressed: (){
                showSendMessageDialog();
              },
            )
        ],
      ),
      body: Column(


        children: [



          Padding(

            padding:
            const EdgeInsets.all(12),


            child:
            TextField(

              controller:
              controller,


              onChanged:
              searchLocation,


              decoration:
              InputDecoration(


                hintText:
                "Search sector, area...",


                prefixIcon:
                const Icon(
                  Icons.location_on,
                  color: Colors.red,
                ),


                filled:
                true,


                fillColor:
                Colors.white,


                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(12),

                ),

              ),

            ),

          ),






          if(selectedLocation.isNotEmpty)

            Padding(

              padding:
              const EdgeInsets.symmetric(
                  horizontal:12
              ),

              child:
              Align(

                alignment:
                Alignment.centerLeft,


                child:
                Text(

                  "Customers near $selectedLocation",

                  style:
                  const TextStyle(

                    fontWeight:
                    FontWeight.bold,

                  ),

                ),

              ),

            ),





          Expanded(

            child:

            results.isNotEmpty


                ?

            ListView.builder(

              itemCount:
              results.length,


              itemBuilder:
                  (context,index){


                final place =
                results[index];



                return Card(

                  margin:
                  const EdgeInsets.symmetric(
                      horizontal:12,
                      vertical:5
                  ),


                  child:
                  ListTile(

                    leading:
                    const CircleAvatar(

                      child:
                      Icon(
                          Icons.location_on
                      ),

                    ),


                    title:
                    Text(
                      place.primaryText,
                      style:
                      const TextStyle(
                          fontWeight:
                          FontWeight.bold
                      ),
                    ),


                    subtitle:
                    Text(
                      place.secondaryText,
                    ),


                    onTap: (){

                      selectLocation(place);

                    },


                  ),

                );


              },


            )



                :



            searchingCustomers


                ?

            const Center(
              child:
              CircularProgressIndicator(),
            )



                :



            nearbyCustomers.isEmpty


                ?

            const Center(
              child:
              Text(
                "Select location to find customers",
              ),
            )



                :



            ListView.builder(

              itemCount:
              nearbyCustomers.length,


              itemBuilder:
                  (context,index){



                final data =
                nearbyCustomers[index]
                    .data()
                as Map<String,dynamic>;



                return Card(

                  margin:
                  const EdgeInsets.symmetric(
                      horizontal:12,
                      vertical:5
                  ),



                  child:
                  ListTile(


                    leading:
                    CircleAvatar(

                      child:
                      Text(
                        (data["username"] ??
                            "U")[0]
                            .toUpperCase(),
                      ),

                    ),



                    title:
                    Text(
                      data["username"] ??
                          "Unknown",
                      style:
                      const TextStyle(
                          fontWeight:
                          FontWeight.bold
                      ),
                    ),



                    subtitle:
                    Text(
                      data["email"] ?? "",
                    ),



                    trailing:
                    IconButton(

                      icon:
                      const Icon(
                          Icons.chat,
                          color:
                          Colors.green
                      ),


                      onPressed: (){


                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder:(_)=>
                                AdminChatPage(

                                  customerId:
                                  nearbyCustomers[index].id,

                                  customerName:
                                  data["username"] ??
                                      "Unknown",

                                ),

                          ),

                        );


                      },


                    ),




                    onTap: (){


                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:(_)=>
                              AdminCustomerFeedScreen(

                                customerId:
                                nearbyCustomers[index].id,


                                customerName:
                                data["username"] ??
                                    "Unknown",


                                latitude:
                                data["latitude"],


                                longitude:
                                data["longitude"],

                              ),

                        ),

                      );


                    },


                  ),

                );



              },

            ),


          )


        ],


      ),


    );

  }


}