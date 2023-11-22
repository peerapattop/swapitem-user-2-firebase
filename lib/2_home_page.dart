import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:swapitem/16_Payment.dart';
import 'package:swapitem/3_build_post.dart';
import 'package:swapitem/notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late User _user;
  late DatabaseReference _userRef;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _userRef = FirebaseDatabase.instance.ref().child('users').child(_user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.notifications,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => NotificationD()));
              },
            )
          ],
          toolbarHeight: 40,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/image 40.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: StreamBuilder(
            stream: _userRef.onValue,
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 350,
                      ),
                      CircularProgressIndicator(),
                      Text('กำลังโหลดข้อมูล...')
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else {
                DataSnapshot dataSnapshot = snapshot.data!.snapshot;
                Map dataUser = dataSnapshot.value as Map;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 6.0),
                                  child: ClipRRect(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        border: Border.all(
                                            width: 1.0,
                                            color: Colors.black), // เส้นขอบ
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('โควตาการโพสต์ 5/5 เดือน',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 6.0),
                                  child: ClipRRect(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        border: Border.all(
                                            width: 1.0,
                                            color: Colors.black), // เส้นขอบ
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                            'โควตาการยื่นข้อเสนอ 5/5 เดือน',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 6.0),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => Payment(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        border: Border.all(
                                            width: 1.0, color: Colors.black),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Wrap(
                                          spacing:
                                              5.0, // ระยะห่างระหว่างไอคอนและข้อความ
                                          children: [
                                            Image.asset(
                                                'assets/images/vip.png'),
                                            Text(
                                              'เติม VIP',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                alignment: Alignment.topCenter,
                                child: ClipOval(
                                  child: Image.network(
                                    dataUser['image_user'],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                dataUser['username'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 6.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.create,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => NewPost(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            side: BorderSide(
                                width: 1.0, color: Colors.black), // เส้นขอบ
                            padding: EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 20.0), // ระยะห่างภายในปุ่ม
                            backgroundColor: Colors.red, // สีข้างใน
                          ),
                          label: Text(
                            'สร้างโพสต์',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 600,
                      width: double.infinity,
                      child: GridView.count(
                        primary: false,
                        padding: const EdgeInsets.all(20),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        crossAxisCount: 2,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.teal[100],
                            child: const Text(
                              "He'd have you all unravel at the",
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.teal[200],
                            child: const Text('Heed not the rabble'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.teal[300],
                            child: const Text('Sound of screams but the'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.teal[400],
                            child: const Text('Who scream'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.teal[500],
                            child: const Text('Revolution is coming...'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.teal[600],
                            child: const Text('Revolution, they...'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

Widget gh(BuildContext context) => Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: ElevatedButton(
              onPressed: () {},
              child: Column(
                children: [
                  Text('สร้างโพสต์'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
