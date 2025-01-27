import 'dart:async';
import 'dart:math';
import 'package:synchronized/synchronized.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:swapitem/widget/chat_detail.dart';
import 'package:swapitem/widget/offer_imageshow.dart';

import 'ProfileScreen.dart';
//หน้าประวัติการโพสต์

class HistoryPost extends StatefulWidget {
  const HistoryPost({Key? key}) : super(key: key);

  @override
  State<HistoryPost> createState() => _HistoryPostState();
}

class _HistoryPostState extends State<HistoryPost> {
  late User _user;
  double? latitude;
  double? longitude;
  late DatabaseReference _postRef, offerRef, userRef;
  List<Map<dynamic, dynamic>> postsList = [];
  int _selectedIndex = -1;
  Map<dynamic, dynamic>? selectedOffer;
  late GoogleMapController mapController;
  int? mySlideindex;
  List<String> image_post = [];
  List<String> imageOffer = [];
  late String offerConfirm;
  late bool checkPost;
  String Ans = '';
  String AnsUidOffer = "";
  String uid = '';
  String postUid = "";
  bool isFetchDataCalled = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    userRef = FirebaseDatabase.instance.ref().child('users');
    _postRef = FirebaseDatabase.instance.ref().child('postitem');
    offerRef = FirebaseDatabase.instance.ref().child('offer');
    selectedOffer = null;

    _postRef.orderByChild('uid').equalTo(_user.uid).onValue.listen((event) {
      postsList.clear();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);

        data.forEach((key, value) {
          if (true) {
            postsList.add(value);
          }
        });

        // Sort postsList by 'timestamp' in descending order
        postsList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        if (postsList.isNotEmpty) {
          setState(() {
            selectedOffer = postsList.first;
            _selectedIndex = 0;
            postUid = "${selectedOffer!['post_uid']}";
          });
        }
      }
    }).onError((error) {
      print("Error fetching data: $error");
    });
  }

  void fetchData(String Ans) async {
    try {
      await _postRef
          .child(selectedOffer!['post_uid'])
          .update({'answerStatus': Ans});

      updateCreditSuccess(uid, 'creditOfferSuccess');

      updateCreditSuccess(_user.uid, 'creditPostSuccess');
    } catch (e) {}
  }

  Future<void> updateCreditSuccess(String uid, String creditType) async {
    try {
      print('Updating $creditType for UID: $uid');

      userRef.child(uid).once().then((databaseEvent) async {
        if (databaseEvent.snapshot.value != null) {
          DataSnapshot snapshot = databaseEvent.snapshot;

          Map<String, dynamic> userData =
              Map<String, dynamic>.from(snapshot.value as Map);
          int currentCredit = userData[creditType] ?? 0;
          int newCredit = currentCredit + 1;

          await userRef.child(uid).update({
            creditType: newCredit,
          });

          print('$creditType updated successfully for UID: $uid');
        } else {
          print('User data not found for UID: $uid');
        }
      }).catchError((error) {
        print('Error fetching user data: $error');
      });
    } catch (error) {
      print('Error updating $creditType: $error');
    }
  }

  void Show_Confirmation_Dialog_Status_cancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการตัดสินใจ'),
          content: const Text(
              '**คำเตือน** การปฏิเสธจะถือว่าเป็นการ แลกเปลี่ยนล้มเหลวทั้งสองฝ่าย'),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'ยันยัน',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                try {
                  // อัปเดตสถานะของโพสต์เป็น "ยืนยัน"
                  DatabaseReference postRef1 = FirebaseDatabase.instance
                      .ref()
                      .child('postitem')
                      .child(postUid);

                  // อัปเดตสถานะของโพสต์เป็น "ยืนยัน"
                  await postRef1.update({
                    'statusPosts': "ปฏิเสธ",
                    'answerStatus': "ล้มเหลว",
                    'statusPosts_With_Offer_uid': AnsUidOffer,
                  });
                } catch (e) {
                  // จัดการข้อผิดพลาดตามความเหมาะสม
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void Show_Confirmation_Dialog_Status(BuildContext context, String postKey) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการตัดสินใจ'),
          content: const Text(
              '**คำเตือน** รอการยืนยันการตัดสินใจจาก ผู้แลกเปลี่ยนของคุณก่อน ถึงจะสำเร็จ'),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'ยันยัน',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                _performUpdateOffer();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void deletePost(String postKey) {
    // Delete the post from the database using the post key
    _postRef.child(postKey).remove().then((_) {
      print("Post deleted successfully!");
      setState(() {
        // Remove the post from the list to update the UI
        postsList.removeWhere((post) => post['post_uid'] == postKey);
        // Reset selectedPost if it's the one being deleted
        if (selectedOffer != null && selectedOffer!['post_uid'] == postKey) {
          selectedOffer = null;
        }
      });
    }).catchError((error) {
      print("Failed to delete post: $error");
    });
  }

  void showDeleteConfirmation(BuildContext context, String postKey) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: const Text('คุณแน่ใจหรือไม่ที่จะลบโพสต์นี้?'),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'ลบ',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                deletePost(postKey);
              },
            ),
          ],
        );
      },
    );
  }

  void selectPayment(Map<dynamic, dynamic> postData) {
    setState(() {
      selectedOffer = postData; // Update selectedPost with the chosen data
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("ประวัติการโพสต์"),
          toolbarHeight: 40,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/image 40.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
        body: StreamBuilder(
          stream: _postRef.orderByChild('uid').equalTo(_user.uid).onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (!snapshot.hasData ||
                snapshot.data!.snapshot.value == null) {
              // ไม่มีข้อมูลโพสต์
              return Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://cdn-icons-png.flaticon.com/256/11191/11191755.png',
                      width: 100,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ไม่มีประวัติการโพสต์',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              );
            } else {
              // มีข้อมูลโพสต์
              Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
                  snapshot.data!.snapshot.value as Map);

              // นำข้อมูลไปใช้แสดงผลตามที่ต้องการ
              return Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: postsList.asMap().entries.map((entry) {
                          int idx = entry.key;
                          Map<dynamic, dynamic> postData = entry.value;
                          image_post =
                              List<String>.from(selectedOffer!['imageUrls']);
                          latitude = double.tryParse(
                              selectedOffer!['latitude'].toString());
                          longitude = double.tryParse(
                              selectedOffer!['longitude'].toString());
                          checkPost = selectedOffer!['answerStatus'] ==
                                      'แลกเปลี่ยนสำเร็จ' ||
                                  selectedOffer!['answerStatus'] == 'ล้มเหลว' ||
                                  selectedOffer!['answerStatus'] ==
                                      'รอการยืนยัน' ||
                                  selectedOffer!['counterDelete'] ==
                                      'ไม่สามารถลบได้'
                              ? true
                              : false;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: buildCircularNumberButton(idx, postData),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const Divider(),
                  selectedOffer != null
                      ? Expanded(
                          child: ListView(
                            children: [
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        ImageGalleryWidget(
                                          imageUrls: image_post,
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.tag,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "หมายเลขโพสต์ : ${selectedOffer!['postNumber']}",
                                              style:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.date_range,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "วันที่ : ${selectedOffer!['date']}",
                                              style:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.punch_clock,
                                              color: Colors.blue,
                                            ),
                                            Text(
                                              '${" เวลา : " + selectedOffer!['time']} น.',
                                              style:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          alignment: Alignment.topLeft,
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                                255, 214, 214, 212),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(11.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'ชื่อสิ่งของ : ' +
                                                      selectedOffer![
                                                          'item_name'],
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                                Text(
                                                  'หมวดหมู่ : ' +
                                                      selectedOffer!['type'],
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                                Text(
                                                  'ยี่ห้อ : ' +
                                                      selectedOffer!['brand'],
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                                Text(
                                                  'รุ่น : ' +
                                                      selectedOffer!['model'],
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                                Text(
                                                  'รายละเอียด : ' +
                                                      selectedOffer!['detail'],
                                                  style: const TextStyle(
                                                      fontSize: 18),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Center(
                                            child: Image.asset(
                                          'assets/images/swap.png',
                                          width: 20,
                                        )),
                                        const SizedBox(height: 10),
                                        Container(
                                          alignment: Alignment.topLeft,
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                                255, 214, 214, 212),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(11.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'สิ่งของที่สนใจจะแลกเปลี่ยน',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: Colors
                                                          .deepPurpleAccent),
                                                ),
                                                Divider(
                                                  color: Colors.black87,
                                                ),
                                                Text(
                                                  'ชื่อสิ่งของ : ${selectedOffer!['item_name1']}',
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                                Text(
                                                  'ยี่ห้อ : ' +
                                                      selectedOffer!['brand1'],
                                                  style: const TextStyle(
                                                      fontSize: 18),
                                                ),
                                                Text(
                                                  'รุ่น : ${selectedOffer!['model1']}',
                                                  style: const TextStyle(
                                                      fontSize: 18),
                                                ),
                                                Text(
                                                  'รายละเอียด : ${selectedOffer!['details1']}',
                                                  style: const TextStyle(
                                                      fontSize: 18),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          decoration: BoxDecoration(
                                              border: Border.all()),
                                          height: 300,
                                          width: 380,
                                          child: GoogleMap(
                                            onMapCreated: (GoogleMapController
                                                controller) {
                                              mapController = controller;
                                            },
                                            initialCameraPosition:
                                                CameraPosition(
                                              target:
                                                  LatLng(latitude!, longitude!),
                                              zoom: 12.0,
                                            ),
                                            markers: <Marker>{
                                              Marker(
                                                markerId: const MarkerId(
                                                    'initialPosition'),
                                                position: LatLng(
                                                    latitude!, longitude!),
                                                infoWindow: const InfoWindow(
                                                  title: 'Marker Title',
                                                  snippet: 'Marker Snippet',
                                                ),
                                              ),
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        checkPost
                                            ? const SizedBox()
                                            : ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red),
                                                onPressed: () {
                                                  if (selectedOffer != null &&
                                                      selectedOffer!
                                                          .containsKey(
                                                              'post_uid')) {
                                                    showDeleteConfirmation(
                                                        context,
                                                        selectedOffer![
                                                            'post_uid']);
                                                  } else {
                                                    print(
                                                        'No post selected for deletion.');
                                                    print(
                                                        'Current selectedPost: $selectedOffer');
                                                  }
                                                },
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.white),
                                                label: const Text('ลบโพสต์',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                              ),
                                        const Divider(),
                                        offerCome(),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        )
                      : const Column(
                          children: [
                            CircularProgressIndicator(),
                            Text('กำลังโหลด..'),
                          ],
                        ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildtimeShow(BuildContext context, String timeGG) {
    // Timestamp in milliseconds
    int timestamp = int.parse(timeGG);

    // Convert timestamp to DateTime
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    return Center(
      child: Text(
        'Date and Time: ${dateTime.toString()}',
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  Widget offerCome() {
    return StreamBuilder(
      stream: offerRef
          .orderByChild('offer_uid')
          .equalTo(selectedOffer!['user_offer_id_confirm'])
          .onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          // Extract data from the snapshot
          Map<dynamic, dynamic> data =
              Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);

          // Initialize variables outside the loop
          String offerNumber = '';
          String date = '';
          String time = '';
          String statusOffers = '';
          String username = '';
          List<Widget> offerWidgets = [];
          String itemname = '';
          String type1 = '';
          String brand1 = '';
          String model1 = '';
          String detail1 = '';
          uid = '';

          get() {
            return AnsUidOffer;
          }

          data.forEach((key, value) {
            username = value['username'];
            AnsUidOffer = value['offer_uid'].toString();
            statusOffers = value['statusOffers'].toString();
            offerNumber = value['offerNumber'].toString();
            date = value['date'].toString();
            time = value['time'].toString();
            itemname = value['nameitem1'].toString();
            type1 = value['type1'].toString();
            brand1 = value['brand1'].toString();
            model1 = value['model1'].toString();
            detail1 = value['detail1'].toString();
            imageOffer = List<String>.from(value['imageUrls']);
            uid = value['uid'].toString();
          });

          return Column(
            children: [
              ImageGalleryWidget(
                imageUrls: imageOffer,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.tag,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "หมายเลขการยื่นข้อเสนอ: $offerNumber",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 8),
                  Row(
                    children: [
                      const Text(
                        "ชื่อผู้ใช้ :",
                        style: TextStyle(fontSize: 18),
                      ),
                      GestureDetector(
                        onTap: () {
                          fetchUserData(uid, context);
                        },
                        child: Row(
                          children: [
                            Text(
                              ' $username',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.purple),
                            ),
                            const Icon(
                              Icons.search,
                              color: Colors.purple,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.date_range,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "วันที่ : ${(date)}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.punch_clock, // เปลี่ยนเป็นไอคอนที่คุณต้องการ
                    color: Colors.blue, // เปลี่ยนสีไอคอนตามความต้องการ
                  ),
                  Text(
                    " เวลา : $time น.",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 2, right: 2, top: 10, bottom: 10),
                child: Container(
                  width: 500,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 214, 214, 212),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(11.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ชื่อสิ่งของ : $itemname",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'หมวดหมู่ : $type1',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'ยี่ห้อ : $brand1',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'รุ่น : $model1',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'รายละเอียด : $detail1',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 600,
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 214, 214, 212),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(11.0),
                    child: Column(
                      children: [
                        Text(
                          'สถานะการแลกเปลี่ยน',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 19,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 0,
                          ),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 30.0, bottom: 10.0, right: 15.0),
                                child: Text(
                                  'ผู้โพสต์',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 45,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 21.0, bottom: 10.0),
                                child: Text(
                                  'ผู้ยื่นข้อเสนอ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                width: 150,
                                height: 50,
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 5.0, right: 10.0, left: 10.0),
                                  child: Center(
                                    child: Text(
                                      selectedOffer!['statusPosts'],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Transform.rotate(
                                angle: -pi /
                                    2, // หมุนทางซ้าย 90 องศา (ในรูปแบบ radian)
                                child: Image.asset(
                                  'assets/images/swap.png',
                                  width: 20,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Container(
                                width: 150,
                                height: 50,
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 5.0, right: 10.0, left: 10.0),
                                  child: Center(
                                    child: Text(
                                      statusOffers,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Container(
                            width: 150,
                            height: 50,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(width: 1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 5.0, right: 10.0, left: 10.0),
                              child: Center(
                                  child: Text(
                                buildStatus(selectedOffer!['statusPosts'],
                                    statusOffers),
                              )),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'ผลการแลกเปลี่ยน',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 0,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                width: double.infinity,
                // Make the button expand to the full width available
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.chat,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetail(
                          receiverUid: uid,
                        ),
                      ),
                    );
                  },
                  label: const Text(
                    'แชท',
                    style: TextStyle(color: Colors.white, fontSize: 19),
                  ),
                ),
              ),
              SizedBox(height: 10),
              statusOffers == 'รอการยืนยัน' || statusOffers == 'ยืนยัน'
                  ? confirmBtn()
                  : Container(),
              ...offerWidgets, // Spread the list of offerWidgets here
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 70),
              Image.network(
                  'https://cdn-icons-png.flaticon.com/128/4310/4310056.png'),
              const SizedBox(height: 20),
              const Text('โปรดเลือกข้อเสนอที่ต้องการ',
                  style: TextStyle(fontSize: 20)),
            ],
          );
        }
      },
    );
  }

  Widget confirmBtn() {
    if (selectedOffer!['statusPosts'] == 'รอการยืนยัน') {
      return Container(
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    Show_Confirmation_Dialog_Status(
                        context, selectedOffer!['post_uid']);
                    // Add your onPressed logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                  label: const Text(
                    'ปฏิเสธการแลกเปลี่ยน',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.check,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    Show_Confirmation_Dialog_Status(
                        context, selectedOffer!['post_uid']);
                    // Add your onPressed logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  ),
                  label: const Text(
                    'ยืนยันการแลกเปลี่ยน',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.warning,
                  color: Colors.white,
                ),
                onPressed: () async {
                  // Add your onPressed logic here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                label: Text(
                  'อย่ากดยืนยัน หรือปฏิเสธจนกว่าจะได้เห็นสิ่งของ',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Future<void> _performUpdateOffer() async {
    try {
      String postUid = selectedOffer!['post_uid'];
      // อัปเดตสถานะของโพสต์เป็น "ยืนยัน"
      DatabaseReference postRef1 =
          FirebaseDatabase.instance.ref().child('postitem').child(postUid);

      // อัปเดตสถานะของโพสต์เป็น "ยืนยัน"
      await postRef1.update({
        'statusPosts': "ยืนยัน",
        'statusPosts_With_Offer_uid': '$AnsUidOffer',
      });
    } catch (e) {
      // จัดการข้อผิดพลาดตามความเหมาะสม
    }
  }

  Future<void> ss() async {
    var merge = "$Ans $AnsUidOffer ";
    var merge2 = merge.split(' ');
    merge2 = merge2[2] as List<String>;
    try {
      // อัปเดตสถานะของโพสต์เป็น "ยืนยัน"
      DatabaseReference postRef1 =
          FirebaseDatabase.instance.ref().child('postitem').child(postUid);

      // อัปเดตสถานะของโพสต์เป็น "ยืนยัน"
      await postRef1.update({
        'statusPosts_With_Offer_uid': "กกก",
      });
    } catch (e) {
      // จัดการข้อผิดพลาดตามความเหมาะสม
    }
  }

  void fetchUserData(String uid, BuildContext context) {
    print('Fetching user data for UID: $uid');

    FirebaseDatabase.instance.ref('users/$uid').once().then((databaseEvent) {
      if (databaseEvent.snapshot.value != null) {
        print('User data found for UID: $uid');

        Map<String, dynamic> userData =
            Map<String, dynamic>.from(databaseEvent.snapshot.value as Map);
        String id = userData['id'] ?? '';
        String username = userData['username'] ?? 'Unknown';
        String imageUser = userData['image_user'] ?? '';
        String creditPostSuccess = userData['creditPostSuccess'].toString();
        String creditOfferSuccess = userData['creditOfferSuccess'].toString();
        String totalOffer = userData['totalOffer'].toString();
        String totalPost = userData['totalPost'].toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              username: username,
              id: id,
              imageUser: imageUser,
              creditPostSuccess: creditPostSuccess,
              creditOfferSuccess: creditOfferSuccess,
              totalOffer: totalOffer,
              totalPost: totalPost,
            ),
          ),
        );
      } else {
        print('User data not found for UID: $uid');
      }
    }).catchError((error) {
      print('Error fetching user data: $error');
    });
  }

  Widget buildCircularNumberButton(int index, Map<dynamic, dynamic> postData) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index; // Update the selected index
          selectedOffer = postData; // Update the selected payment data
        });
      },
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? Colors.blue
              : Colors.grey, // Highlight if selected
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black,
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String convertDateFormat(String inputDate) {
    DateTime dateTime = DateTime.parse(inputDate); // แปลงสตริงเป็นวันที่
    DateFormat formatter =
        DateFormat('d MMMM y', 'th'); // สร้างรูปแบบการแสดงวันที่ตามที่ต้องการ
    String formattedDate =
        formatter.format(dateTime); // แปลงวันที่เป็นรูปแบบที่ต้องการ
    return formattedDate; // คืนค่าวันที่ที่ถูกแปลง
  }

  String buildStatus(String statusPost, String statusOffer) {
    String Ans = "กกก";
    if (statusPost == "รอการยืนยัน" && statusOffer == "รอการยืนยัน") {
      Ans = "รอการยืนยัน"; //
    } else if (statusPost == "ยืนยัน" && statusOffer == "รอการยืนยัน") {
      Ans = "รอการยืนยัน"; //
    } else if (statusPost == "รอการยืนยัน" && statusOffer == "ยืนยัน") {
      Ans = "รอการยืนยัน"; //
    } else if (statusPost == "ยืนยัน" && statusOffer == "ยืนยัน") {
      Ans = "แลกเปลี่ยนสำเร็จ"; //
    } else if (statusPost == "ยืนยัน" && statusOffer == "ปฏิเสธ") {
      Ans = "ล้มเหลว"; //
    } else if (statusPost == "ปฏิเสธ" && statusOffer == "ยืนยัน") {
      Ans = "ล้มเหลว"; //
    } else if (statusPost == "ปฏิเสธ" && statusOffer == "ปฏิเสธ") {
      Ans = "ล้มเหลว"; //
    } else if (statusPost == "ปฏิเสธ" && statusOffer == "รอการยืนยัน") {
      Ans = "ล้มเหลว"; //
    } else if (statusPost == "รอการยืนยัน" && statusOffer == "ปฏิเสธ") {
      Ans = "ล้มเหลว"; //
    }

    if ((Ans == 'แลกเปลี่ยนสำเร็จ' || Ans == 'ล้มเหลว') && !isFetchDataCalled) {
      fetchData(Ans);
      isFetchDataCalled =
          true; // Set the flag to true after calling fetchData()
    }
    return Ans;
  }
}
