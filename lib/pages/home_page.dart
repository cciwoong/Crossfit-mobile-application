import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ClassPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final currentUser = FirebaseAuth.instance.currentUser!;
  int participantsCount = 0;
  final _firestore = FirebaseFirestore.instance;
  late StreamSubscription<DocumentSnapshot> _subscription;

  bool canUserAccessResetButton(User user) {
    // Only coach can access
    List<String> allowedEmails = [
      "coach@gmail.com",
    ];

    // Are you Coach?
    return allowedEmails.contains(user.email);
  }

  // reset attendance
  @override
  void initState() {
    super.initState();
    _subscription = _firestore
        .collection('Class')
        .doc('class-attendance')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          participantsCount = snapshot.get('participants') ?? 0;
        });
      } else {
        setState(() {
          participantsCount = 0;
        });
      }
    });
  }

  // release resources
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  // Reserve a spot in the class
  void reserveSpot() {
    _firestore.runTransaction((transaction) async {
      final doc = _firestore.collection('Class').doc('class-attendance');
      final snapshot = await transaction.get(doc);
      int currentParticipants;

      // Check if the doc(document) exists
      if (snapshot.exists) {
        currentParticipants = snapshot.get('participants') ?? 0;
      } else {
        currentParticipants = 0;
        // Create the doc with an initial participants count of 0
        transaction.set(doc, {'participants': currentParticipants});
      }

      // Add participants when its under 10
      if (currentParticipants < 10) {
        transaction.update(
          doc,
          {'participants': currentParticipants + 1},
        );
        // Your in! go to ClassPage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ClassPage()),
        );
      } else {
        // Your too late
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Class Full"),
            content: Text("Sorry, the class is already full.."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    });
  }


  // reset the attendance for new WOD
  Widget resetButton() {
    if (canUserAccessResetButton(currentUser))
      return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: initiateResetButton,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(
                "Reset",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

    return Container(); // Members can not access
  }

  // reset in the DB
  void initiateResetButton() {
    _firestore.collection('Class').doc('class-attendance').update({
      'participants': 0,
    });
  }

  // sign user out
  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Crossfit",
        ),
        actions: [
          // sign out
          IconButton(
            onPressed: signOut,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // WOD
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: const Text(
                    "WOD",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ), //

              const SizedBox(height: 20),

              // WOD board
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'For Time',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '40 Cal Ski\n40 Dumbbell Thrusters\n20 Burpees\n120 Double Unders\n20 Burpees\n40 Barbell Thrusters\n40 Cal Row\n\nM - 2x22.5kg Dumbbells, 30kg Barbell\nF - 2x15kg Dumbbells, 20kg Barbell',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Booking button
              Material(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: reserveSpot,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Reserve",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // User email who logged in now
              Text(
                "Your logged in as: " + currentUser.email!,
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 20),


              // Reset attendance
              resetButton(),
            ],
          ),
        ),
      ),
    );
  }
}
