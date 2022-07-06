import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/models/user_ride_request_information.dart';
import 'package:drivers_app/push_notification/notification_dialog_box.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PushNotificationSystem{
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future initializeCloudMessaging(BuildContext context)async{

    //1.Terminated
    //when the app is completely closed and opened directly from the push notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? remoteMessage){
      if(remoteMessage != null){
        //display ride request notification request - user information who request a ride

        readUserRideRequestInformation(remoteMessage.data["rideRequestId"], context);

      }
    });

    //2. ForeGround
    //when the app is opened and receive the push notification
    FirebaseMessaging.onMessage.listen((RemoteMessage? remoteMessage) {
      //display ride request notification request - user information who request a ride
      readUserRideRequestInformation(remoteMessage!.data["rideRequestId"], context);
    });

    //3. Background
    // When the app is running in the background and opened directly from the push notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage) {
      //display ride request notification request - user information who request a ride
      readUserRideRequestInformation(remoteMessage!.data["rideRequestId"], context);
    });
  }

  readUserRideRequestInformation(String rideRequestId, BuildContext context){
    FirebaseDatabase.instance.ref().child("All Ride Request").child(rideRequestId).once().then((snapData){
      if(snapData.snapshot.value != null){

        assetsAudioPlayer.open(Audio("music/music_notification.mp3"));
        assetsAudioPlayer.play();

        double originLat = double.parse((snapData.snapshot.value! as Map)["origin"]["latitude"].toString());
        double originLng = double.parse((snapData.snapshot.value! as Map)["origin"]["longitude"].toString());
        String originAddress = (snapData.snapshot.value! as Map)["originAddress"];

        String? rideRequestId = snapData.snapshot.key;

        double destinationLat = double.parse((snapData.snapshot.value! as Map)["destination"]["latitude"].toString());
        double destinationLng = double.parse((snapData.snapshot.value! as Map)["destination"]["longitude"].toString());
        String destinationAddress = (snapData.snapshot.value! as Map)["destinationAddress"];

        String userName = (snapData.snapshot.value! as Map)["userName"];
        userPhone = (snapData.snapshot.value! as Map)["userPhone"];

        UserRideRequestInformation userRideRequestInformation =UserRideRequestInformation();
        userRideRequestInformation.originLatLng = LatLng(originLat, originLng);
        userRideRequestInformation.destinationLatLng = LatLng(destinationLat, destinationLng);

        userRideRequestInformation.originAddress = originAddress;
        userRideRequestInformation.destinationAddress = destinationAddress;

        userRideRequestInformation.userName = userName;
        userRideRequestInformation.userPhone = userPhone;

        userRideRequestInformation.rideRequestId = rideRequestId;

        showDialog(
            context: context,
            builder: (BuildContext context) => NotificationDialogBox(
                userRideRequestInformation: userRideRequestInformation,
            ),);
      }
    });
  }


  Future generateAndGetToken()async{
    String? registrationToken = await messaging.getToken();

    FirebaseDatabase.instance.ref().child("drivers").child(currentFirebaseUser!.uid).child("token").set(registrationToken);
    messaging.subscribeToTopic("allDrivers");
    messaging.subscribeToTopic("allUsers");

  }
}