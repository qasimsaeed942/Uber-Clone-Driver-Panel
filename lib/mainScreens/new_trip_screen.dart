import 'dart:async';
import 'package:drivers_app/assistants/assistant_method.dart';
import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/widgets/fare_amount_collection_dialog.dart';
import 'package:drivers_app/widgets/progress_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_ride_request_information.dart';

class NewTripScreen extends StatefulWidget {

  UserRideRequestInformation? userRideRequestInformation;
  NewTripScreen({Key? key, this.userRideRequestInformation}) : super(key: key);

  @override
  _NewTripScreenState createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newTripGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  String? buttonTitle = "Arrived";
  String rideRequestStatus = "accepted";
  String durationFromOriginToDestination = "";
  bool isRequestDirectionDetails = false;

  double mapPadding = 0;
  BitmapDescriptor? iconAnimatedMarker;
  var geoLocator = Geolocator();
  Position? onlinedriverCurrentPosition;

  Set<Marker> setOfMarkers = Set<Marker>();
  Set<Circle> setOfCircle = Set<Circle>();
  Set<Polyline> setOfPolyline = Set<Polyline>();
  List<LatLng> polylinePositionCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();


  Future<void> drawPolyLineFromOriginToDestination(LatLng originLatLng, LatLng destinationLatLng) async
  {

    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(message: "Please wait...",),
    );

    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);

    Navigator.pop(context);

    print("These are points = ");
    print(directionDetailsInfo!.e_points);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResultList = pPoints.decodePolyline(directionDetailsInfo!.e_points!);

    polylinePositionCoordinates.clear();

    if(decodedPolyLinePointsResultList.isNotEmpty)
    {
      decodedPolyLinePointsResultList.forEach((PointLatLng pointLatLng)
      {
        polylinePositionCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    setOfPolyline.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.purpleAccent,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: polylinePositionCoordinates,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      setOfPolyline.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if(originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude)
    {
      boundsLatLng = LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    }
    else if(originLatLng.longitude > destinationLatLng.longitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    }
    else if(originLatLng.latitude > destinationLatLng.latitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    }
    else
    {
      boundsLatLng = LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newTripGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: const MarkerId("originID"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      setOfMarkers.add(originMarker);
      setOfMarkers.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: const CircleId("originID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationID"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      setOfCircle.add(originCircle);
      setOfCircle.add(destinationCircle);
    });
  }

  @override
  void initState() {
    super.initState();
    fetchFareAmount();
    saveAssignedDriversDetailsToUserRideRequest();
  }

  createDriverIconMarker()
  {
    if(iconAnimatedMarker == null)
    {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: const Size(1, 1));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/bike.png").then((value)
      {
        iconAnimatedMarker = value;
      });
    }
  }
  getDriversLocationUpdatesAtRealTime()
  {

    LatLng oldLatLng = LatLng(0, 0);
    streamSubscriptionDriverLivePosition = Geolocator.getPositionStream()
        .listen((Position position)
    {
      driverCurrentPosition = position;
      onlinedriverCurrentPosition = position;

      LatLng latLngLiveDriverPosition = LatLng(
        onlinedriverCurrentPosition!.latitude,
        onlinedriverCurrentPosition!.longitude,
      );

      Marker animatingMarker =Marker(
          markerId: MarkerId("AnimatedMarker"),
        position: latLngLiveDriverPosition,
        icon: iconAnimatedMarker!,
        infoWindow: InfoWindow(title: "This is your position"),
      );

      setState(() {
        CameraPosition cameraPosition = CameraPosition(target: latLngLiveDriverPosition,zoom: 16);
        newTripGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        setOfMarkers.removeWhere((element) => element.markerId.value == "AnimatedMarker");
        setOfMarkers.add(animatingMarker);

      });
      oldLatLng = latLngLiveDriverPosition;
      updateDurationTimeAtRealTime();

      //updating driver location at real time in Database
      Map driverLatLngDataMap =
      {
        "latitude": onlinedriverCurrentPosition!.latitude.toString(),
        "longitude": onlinedriverCurrentPosition!.longitude.toString(),
      };
      FirebaseDatabase.instance.ref().child("All Ride Request")
          .child(widget.userRideRequestInformation!.rideRequestId!)
          .child("driverLocation")
          .set(driverLatLngDataMap);

    });
  }
  updateDurationTimeAtRealTime() async
  {
    if(isRequestDirectionDetails == false)
    {
      isRequestDirectionDetails = true;

      if(onlinedriverCurrentPosition == null)
      {
        return;
      }

      var originLatLng = LatLng(
        onlinedriverCurrentPosition!.latitude,
        onlinedriverCurrentPosition!.longitude,
      ); //Driver current Location

      var destinationLatLng;

      if(rideRequestStatus == "accepted")
      {
        destinationLatLng = widget.userRideRequestInformation!.originLatLng; //user PickUp Location
      }
      else
      {
        destinationLatLng = widget.userRideRequestInformation!.destinationLatLng; //user DropOff Location
      }

      var directionInformation = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);

      if(directionInformation != null)
      {
        setState(() {
          durationFromOriginToDestination = directionInformation.duration_text!;
        });
      }

      isRequestDirectionDetails = false;
    }
  }



  @override
  Widget build(BuildContext context) {
    createDriverIconMarker();
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapPadding, top: 20),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            markers: setOfMarkers,
            circles: setOfCircle,
            polylines: setOfPolyline,
            onMapCreated: (GoogleMapController controller){
              _controllerGoogleMap.complete(controller);
              newTripGoogleMapController = controller;

              setState(() {
                mapPadding = 350;
              });

              var driverCurrentLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
              var userPickUpLatLng = widget.userRideRequestInformation!.originLatLng;

              drawPolyLineFromOriginToDestination(driverCurrentLatLng, userPickUpLatLng!);

              getDriversLocationUpdatesAtRealTime();
            },
          ),
          
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white30,
                      blurRadius: 18,
                      spreadRadius: 0.5,
                      offset: Offset(0.6,0.6),
                    ),
                  ]
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25,vertical: 20),
                  child: Column(
                    children:  [
                      Text(durationFromOriginToDestination,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.yellow,
                      ),
                      ),

                      const SizedBox(height: 8,),

                      const Divider(
                        thickness: 2,
                        height: 2,
                        color: Colors.yellow,
                      ),

                      Row(
                        children:  [
                           Text(
                             widget.userRideRequestInformation!.userName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.yellow,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Icon(Icons.phone_android,
                            color: Colors.grey,),
                          )
                        ],
                      ),

                      const SizedBox(height: 18,),
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


                      const SizedBox(height: 20,),

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

                      const SizedBox(height: 20,),

                      const Divider(
                        thickness: 2,
                        height: 2,
                        color: Colors.yellow,
                      ),

                      const SizedBox(height: 20,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                              onPressed: ()async{
                                //driver has arrived at user PickUp Location
                                if(rideRequestStatus == "accepted")
                                    {
                                  rideRequestStatus = "arrived";

                                  FirebaseDatabase.instance.ref()
                                      .child("All Ride Request")
                                      .child(widget.userRideRequestInformation!.rideRequestId!)
                                      .child("status")
                                      .set(rideRequestStatus);

                                  setState(() {
                                    buttonTitle = "Let's Go"; //start the trip
                                  });

                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext c)=> ProgressDialog(
                                      message: "Loading...",
                                    ),
                                  );

                                  await drawPolyLineFromOriginToDestination(
                                      widget.userRideRequestInformation!.originLatLng!,
                                      widget.userRideRequestInformation!.destinationLatLng!
                                  );

                                  Navigator.pop(context);
                                }
                                //user has already sit in the driver's car - start trip now
                                else if(rideRequestStatus == "arrived")
                                {
                                  rideRequestStatus = "ontrip";

                                  FirebaseDatabase.instance.ref()
                                      .child("All Ride Request")
                                      .child(widget.userRideRequestInformation!.rideRequestId!)
                                      .child("status")
                                      .set(rideRequestStatus);

                                  setState(() {
                                    buttonTitle = "End Trip"; //start the trip
                                  });
                                }
                                //driver has reached at user DropOff Location = End Trip now
                                else if(rideRequestStatus == "ontrip"){
                                  var currentDriverPositionLatLng = LatLng(
                                      onlinedriverCurrentPosition!.latitude,
                                      onlinedriverCurrentPosition!.longitude);

                                  var tripDirectionDetails = await  AssistantMethods.obtainOriginToDestinationDirectionDetails(
                                      currentDriverPositionLatLng,
                                      widget.userRideRequestInformation!.originLatLng!);
                                  showDialog(
                                    context: context,
                                    builder: (context) =>   ListView.builder(
                                        itemCount: dList.length,
                                        itemBuilder: (BuildContext context, int index){
                                         endTripNow(dList[index]["bike_details"]["bike_fare"]);
                                          return Card(
                                            color: Colors.grey,
                                            elevation: 3,
                                            shadowColor: Colors.green,
                                            margin: const EdgeInsets.all(8),
                                            child: ListTile(
                                              leading: Padding(
                                                padding: const EdgeInsets.only(top: 20),
                                                child: Text(AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetails!,dList[index]["bike_details"]["bike_fare"]).toString(),
                                                  style:  const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),),
                                              ),
                                            ),
                                          );
                                        }

                                    ),
                                  );

                                //  Navigator.push(context, MaterialPageRoute(builder: (e)=> FareAmountCollectionDialogue()));
                                }
                              },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.yellow,
                            ),
                              icon: const Icon(Icons.directions_bike,size: 25,color: Colors.blueGrey,),
                              label: Text(buttonTitle!,
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),),
                 ElevatedButton.icon(
                  onPressed: ()
                  {
                    launch(('tel://$userPhone'));
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
                  ),
                  icon: const Icon(
                    Icons.phone_android,
                    color: Colors.black54,
                    size: 22,
                  ),
                  label: const Text(
                    "Call Passenger",
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                        ],
                      ),

                    ],
                  ),
                ),
              ))
        ],
      ),
    );
  }

    endTripNow(int fare) async{
      //get the tripDirectionDetails = distance Traveled
      // showDialog(
      //   context: context,
      //   builder: (BuildContext context) => ProgressDialog(message: "Please wait...",),
      // );
        var currentDriverPositionLatLng = LatLng(
          onlinedriverCurrentPosition!.latitude,
          onlinedriverCurrentPosition!.longitude);

      var tripDirectionDetails = await  AssistantMethods.obtainOriginToDestinationDirectionDetails(
          currentDriverPositionLatLng,
          widget.userRideRequestInformation!.originLatLng!);

      //fare Amount
    int fareAmount =  AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetails!,fare);
    print(fareAmount);


     FirebaseDatabase.instance.ref().child("All Ride Request").child(widget.userRideRequestInformation!.rideRequestId!)
      .child("fareAmount").set(fareAmount);

      FirebaseDatabase.instance.ref().child("All Ride Request").child(widget.userRideRequestInformation!.rideRequestId!)
          .child("status").set("ended");

      streamSubscriptionDriverLivePosition!.cancel();

      Navigator.pop(context);

      showDialog(
          context: context,
          builder: (BuildContext c)=> FareAmountCollectionDialog(totalFareAmount: fareAmount,));

        saveFareAmountToDriverEarnings(fareAmount);


  }

  saveFareAmountToDriverEarnings(int totalFareAmount)
  {
    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("earnings")
        .once()
        .then((snap)
    {
      if(snap.snapshot.value != null) //earnings sub Child exists
          {
        //12
        double oldEarnings = double.parse(snap.snapshot.value.toString());
        double driverTotalEarnings = totalFareAmount + oldEarnings;

        FirebaseDatabase.instance.ref()
            .child("drivers")
            .child(currentFirebaseUser!.uid)
            .child("earnings")
            .set(driverTotalEarnings.toString());
      }
      else //earnings sub Child do not exists
          {
        FirebaseDatabase.instance.ref()
            .child("drivers")
            .child(currentFirebaseUser!.uid)
            .child("earnings")
            .set(totalFareAmount.toString());
      }
    });
  }

  fetchFareAmount(){
    DatabaseReference ref =  FirebaseDatabase.instance.ref().child("drivers");
    ref.child(currentFirebaseUser!.uid).once().then((dataSnapshot)
    {
      var driverKeyInfo = dataSnapshot.snapshot.value;
      dList.add(driverKeyInfo);
     // setState((){});
      print(driverKeyInfo);
      print(dList);
    });

  }

  saveAssignedDriversDetailsToUserRideRequest(){
    DatabaseReference databaseReference =FirebaseDatabase.instance.ref()
        .child("All Ride Request").child(widget.userRideRequestInformation!.rideRequestId!);

    Map driverLocationDataMap = {
      "latitude": driverCurrentPosition!.latitude.toString(),
      "longitude": driverCurrentPosition!.longitude.toString(),
    };

    databaseReference.child("driverLocation").set(driverLocationDataMap);
    databaseReference.child("status").set("accepted");
    databaseReference.child("driverId").set(onlineDriverdata.id);
    databaseReference.child("driverName").set(onlineDriverdata.name);
    databaseReference.child("driverPhone").set(onlineDriverdata.phone);
    databaseReference.child("bike_details").set(onlineDriverdata.bike_color.toString() + onlineDriverdata.bike_model.toString());

    DatabaseReference tripHistoryRef = FirebaseDatabase.instance.ref().child("drivers")
        .child(currentFirebaseUser!.uid).child("tripHistory");
    tripHistoryRef.child(widget.userRideRequestInformation!.rideRequestId!).set(true);
    }
  }



