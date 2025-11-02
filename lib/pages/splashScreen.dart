import 'package:finalproject/pages/loginScreen.dart'; 
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 40),
      child: Column(children: [
        Center(
          child: Text("Discover THe\nWheater In Your City", 
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.2,
            color: Colors.white
          ),
          ),
        ),
        Spacer(),
          Image.asset("assets/images/cloudy.png", height: 350,),
          Spacer(),
           Center(
          child: Text("Cari Tau Cuaca Di Sekitarmu\nRadar Peramal Cuacaku", 
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: Colors.white
          ),
          ),
        ),
        Padding(padding: EdgeInsets.only(top: 30), 
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)
            )
          ),
          onPressed: () {
             Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15 ),
            child: Text("Get Started", style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 18,
              color: Colors.white

            ),),
          )),)
      ],),
      )
      ),
    );
  }
}