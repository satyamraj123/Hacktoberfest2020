import 'package:asha_patient_app_flutter/Models/user.dart';
import 'package:asha_patient_app_flutter/screens/connectycube/callbackend.dart';
import 'package:asha_patient_app_flutter/services/firestoreServices.dart';
import 'package:connectycube_sdk/connectycube_chat.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

abstract class AuthBase {
  Future<FirebaseUser> currentUser();

  Future<void> updatePassword(String newPassword);

  Future<void> signUpWithEmailAndPassword(
      User user, String password, String confirmPassword,
      {Function goToInitScreen, Function switchLoading});

  Future<void> signInWithEmailAndPassword(String email, String password,
      {Function goToInitScreen, Function switchLoading});

  // void sendVerificationMail();

  Future<void> signOut(Function goToInitScreen);
}

class AuthService implements AuthBase {
  final _auth = FirebaseAuth.instance;

  @override
  Future<FirebaseUser> currentUser() async {
    final _currentUser = await _auth.currentUser();
    return _currentUser;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final _user = await currentUser();
    await _user.updatePassword(newPassword);
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password,
      {@required Function goToInitScreen,
      @required Function switchLoading}) async {
    switchLoading();
    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: 'Please fill up all the fields');
      switchLoading();
      return;
    }

    try {
      final _authResult = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      print(_authResult.user.email);
      switchLoading();
      goToInitScreen();
    } on PlatformException catch (e) {
      print(e.toString());
      switchLoading();

      switch (e.code) {
        case 'ERROR_WRONG_PASSWORD':
          Fluttertoast.showToast(msg: "Wrong Password!");
          break;
        case 'ERROR_USER_NOT_FOUND':
          Fluttertoast.showToast(
              msg: "This email is not linked to any account!");
          break;
        default:
          Fluttertoast.showToast(msg: "Authentication Problem!");
      }
    } catch (err) {
      print('other type of error in signing with email and password ');
      print(err.toString());
      switchLoading();
    }
  }

  @override
  Future<void> signUpWithEmailAndPassword(
      User user, String password, String confirmPassword,
      {Function goToInitScreen, Function switchLoading}) async {
    switchLoading();
    if (user.email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill up all the fields.");
      switchLoading();
      return;
    }

    if (user.phoneNumber.length != 13) {
      Fluttertoast.showToast(msg: "Mobile number should be of 10 digits");
      switchLoading();
      return;
    }

    if (!EmailValidator.validate(user.email)) {
      Fluttertoast.showToast(msg: "Please enter a valid email address.");
      switchLoading();
      return;
    }
    if (password != confirmPassword) {
      Fluttertoast.showToast(msg: "Passwords do not match.");
      switchLoading();
      return;
    }
    if (password.length < 6) {
      Fluttertoast.showToast(
          msg: "Password must be atleast 6 characters long.");
      switchLoading();
      return;
    }
    try {
      AuthResult _authResult = await _auth.createUserWithEmailAndPassword(
          email: user.email, password: password);
      FirebaseUser firebaseUser = _authResult.user;

      // firebaseUser.sendEmailVerification();
      print(firebaseUser.uid);

      user.userId = firebaseUser.uid;

      print("User going to register in DB");
      await FirestoreServices().addNewUser(user);
      print("user going to register in connectycube");
      int connectyId = await Connecty.newusersignup(CubeUser(
        login: firebaseUser.uid,
        password: 'av^2Bu-xtx2080#q2',
      ));

      await FirestoreServices()
          .addConnectyIdToUserData(uid: user.userId, id: connectyId);

      switchLoading();

      goToInitScreen();
    } on PlatformException catch (e) {
      print(e.toString());
      switchLoading();

      switch (e.code) {
        case 'ERROR_EMAIL_ALREADY_IN_USE':
          Fluttertoast.showToast(
              msg: "This email is linked to an existing account");
          break;
        default:
          Fluttertoast.showToast(msg: "Registration Problem!");
      }
    } catch (e) {
      print(e.toString());
      switchLoading();
    }
  }

  // @override
  // void sendVerificationMail() async {
  //   try {
  //     FirebaseUser user = await _auth.currentUser();
  //     user.sendEmailVerification();
  //     Fluttertoast.showToast(msg: "Email sent!");
  //   } catch (e) {
  //     Fluttertoast.showToast(
  //       msg: "Error sending email! Try later!",
  //       backgroundColor: Colors.red,
  //       textColor: Colors.white,
  //     );
  //   }
  // }

  @override
  Future<void> signOut(Function goToInitScreen) async {
    await _auth.signOut();
    goToInitScreen();
  }
}
