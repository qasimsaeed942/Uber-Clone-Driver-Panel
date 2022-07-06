import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:drivers_app/assistants/assistant_method.dart';
import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/mainScreens/new_trip_screen.dart';
import 'package:drivers_app/models/user_ride_request_information.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NotificationDialogBox extends StatefulWidget {
 UserRideRequestInformation? userRideRequestInformation;

 NotificationDialogBox({this.userRideRequestInformation});

  @override
  _NotificationDialogBoxState createState() => _NotificationDialogBoxState();
}

class _NotificationDialogBoxState extends State<NotificationDialogBox> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.only(top: 70,left: 40,right: 40,bottom: 135),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      elevation: 2,
      child: Container(
        margin: EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[800]
        ),
        child: Column(
          children: [
            Image.asset("images/logo1.jpg", width: 160,),
            const SizedBox(height: 2,),
            const Text("New Ride Request",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.grey
            ),
            ),
            const SizedBox(height: 10,),

            Divider(
              height: 3,
              thickness: 3,
            ),

            const SizedBox(height: 15,),
            Column(
              children: [
                Row(
                  children: [
                    Image.asset("images/origin.png",
                      width: 40,
                    height: 40,),
                    const SizedBox(width: 10,),
                    Expanded(
                      child: Container(
                        child: Text(
                          widget.userRideRequestInformation!.originAddress!,
                          style: const TextStyle(
                            fontSize: 16,
                              color: Colors.grey
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 20,),
                Row(
                  children: [
                    Image.asset("images/destination.png",
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 10,),
                    Expanded(
                      child: Container(
                        child: Text(
                          widget.userRideRequestInformation!.destinationAddress!,
                          style: const TextStyle(
                            fontSize: 16,
                              color: Colors.grey
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 50,),


                const Divider(
                  height: 3,
                  thickness: 3,
                ),


                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red
                      ),
                      onPressed: (){
                        assetsAudioPlayer.pause();
                        assetsAudioPlayer.stop();
                        assetsAudioPlayer = AssetsAudioPlayer();

                        //cancel the rideRequest
                        FirebaseDatabase.instance.ref()
                            .child("All Ride Request")
                            .child(widget.userRideRequestInformation!.rideRequestId!)
                            .remove().then((value)
                        {
                          FirebaseDatabase.instance.ref()
                              .child("drivers")
                              .child(currentFirebaseUser!.uid)
                              .child("newRideStatus")
                              .set("idle");
                        }).then((value)
                        {
                          FirebaseDatabase.instance.ref()
                              .child("drivers")
                              .child(currentFirebaseUser!.uid)
                              .child("tripHistory")
                              .child(widget.userRideRequestInformation!.rideRequestId!)
                              .remove();
                        }).then((value)
                        {
                          Fluttertoast.showToast(msg: "Ride Request has been Cancelled, Successfully. Restart App Now.");
                        });

                        Future.delayed(const Duration(milliseconds: 3000), ()
                        {
                          SystemNavigator.pop();
                        });
                    },
                        child: Text("Cancel".toUpperCase(),
                          style: TextStyle( fontSize: 14),
                        ),),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: Colors.green
                      ),
                      onPressed: (){
                        assetsAudioPlayer = AssetsAudioPlayer();
                        assetsAudioPlayer.pause();
                        assetsAudioPlayer.stop();

                        acceptRideRequest(context);

                      },
                      child: Text("Accept".toUpperCase(),
                        style: TextStyle( fontSize: 14),
                      ),),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  acceptRideRequest(BuildContext context) {
    String getRideRequestId = "";
    FirebaseDatabase.instance.ref().child("drivers").child(currentFirebaseUser!.uid).child("newRideStatus").once().then((value){
      if(value.snapshot.value != null){
        getRideRequestId = value.snapshot.value.toString();
      }else{
        Fluttertoast.showToast(msg: "This ride request does not exist.");
      }
      if(getRideRequestId == widget.userRideRequestInformation!.rideRequestId){
        FirebaseDatabase.instance.ref().child("drivers").child(currentFirebaseUser!.uid).child("newRideStatus").set("Accepted");

        AssistantMethods.pauseLiveLocationUpdate();

        //trip started now - send driver to the new trip screen
        Navigator.push(context, MaterialPageRoute(builder: (c)=> NewTripScreen(userRideRequestInformation: widget.userRideRequestInformation)));

      }else{
        Fluttertoast.showToast(msg: "This Ride Request do not exists");
      }
    });
  }
}
