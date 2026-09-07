import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';


class AdminPostLocationPicker extends StatefulWidget {

  const AdminPostLocationPicker({super.key});

  @override
  State<AdminPostLocationPicker> createState() =>
      _AdminPostLocationPickerState();
}


class _AdminPostLocationPickerState
    extends State<AdminPostLocationPicker> {


  final TextEditingController controller =
  TextEditingController();


  final FlutterGooglePlacesSdk places =
  FlutterGooglePlacesSdk(
      "AIzaSyC_fskYCZEOJyS_67Yxa-N-qZA7EuQPhYY"
  );


  List<AutocompletePrediction> results=[];


  Future<void> search(String value) async {


    if(value.trim().isEmpty){

      setState(() {
        results=[];
      });

      return;

    }


    final response =
    await places.findAutocompletePredictions(
      value,
      countries:["IN"],
    );


    setState(() {

      results=response.predictions;

    });


  }



  Future<void> selectPlace(
      AutocompletePrediction place
      ) async {


    final detail =
    await places.fetchPlace(
        place.placeId,
        fields:[
          PlaceField.Location
        ]
    );


    final location =
        detail.place?.latLng;


    if(location==null)return;


    Navigator.pop(
        context,
        {

          "latitude":location.lat,

          "longitude":location.lng,

          "address":
          "${place.primaryText}, ${place.secondaryText}"

        }

    );


  }



  @override
  Widget build(BuildContext context){

    return Scaffold(

      appBar:AppBar(
        title:
        const Text(
            "Select Post Location"
        ),
      ),


      body:Column(

        children:[


          Padding(
            padding:
            const EdgeInsets.all(12),

            child:TextField(

              controller:controller,

              onChanged:search,


              decoration:
              const InputDecoration(

                  hintText:
                  "Search area / sector",

                  prefixIcon:
                  Icon(Icons.location_on)

              ),

            ),

          ),



          Expanded(

            child:
            ListView.builder(

              itemCount:
              results.length,


              itemBuilder:(context,index){

                final place=results[index];


                return ListTile(

                  title:
                  Text(place.primaryText),

                  subtitle:
                  Text(place.secondaryText),


                  onTap:(){

                    selectPlace(place);

                  },


                );

              },

            ),

          )



        ],


      ),


    );

  }


}