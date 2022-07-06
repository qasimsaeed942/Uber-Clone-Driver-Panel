
import 'dart:async';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:drivers_app/models/direction_details_info.dart';
import 'package:drivers_app/models/driver_data.dart';
import 'package:drivers_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

User? currentFirebaseUser;
UserModel? userModelCurrentInfo;
StreamSubscription<Position>? streamSubscriptionPosition;
StreamSubscription<Position>? streamSubscriptionDriverLivePosition;
AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();
Position? driverCurrentPosition;
String userPhone= "";
String  titleStarsRating = "Good";
DriverData onlineDriverdata = DriverData();
String? driverVehicleType = "";
List dList = []; //driver keys Info  list