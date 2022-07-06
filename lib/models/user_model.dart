
import 'package:firebase_database/firebase_database.dart';

class UserModel{
  String? phone;
  String? name;
  String? id;
  String? email;

  UserModel({this.phone,this.id,this.name,this.email});

  UserModel.fromSnapShot(DataSnapshot snap){

    phone = (snap.value as dynamic)["phone"];
    name = (snap.value as dynamic)["name"];
    id = (snap.value as dynamic)["id"];
    email = (snap.value as dynamic)["email"];
  }
}