import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:swapitem/widget/offer_imageshow.dart';

class Offer_come extends StatefulWidget {
  const Offer_come({Key? key}) : super(key: key);

  @override
  State<Offer_come> createState() => _Offer_comeState();
}

class _Offer_comeState extends State<Offer_come> {
  int currentPage = 0;
  late User _user;
  double? latitude;
  double? longitude;
  late DatabaseReference _postRef;
  List<Map<dynamic, dynamic>> postsList = [];
  List<Map<dynamic, dynamic>> postsList1 = [];
  int _selectedIndex = -1;
  Map<dynamic, dynamic>? selectedPost;

  ////
  int _selectedIndex1 = -1;
  Map<dynamic, dynamic>? selectedOffers1;

  late GoogleMapController mapController;
  int? mySlideindex;
  int? mySlideindex1;
  List<String> image_post = [];
  List<String> image_offer = [];
  List<String> foodList = [
    "https://cdn.pixabay.com/photo/2010/12/13/10/05/berries-2277_1280.jpg",
    "https://cdn.pixabay.com/photo/2015/12/09/17/11/vegetables-1085063_640.jpg",
    "https://cdn.pixabay.com/photo/2017/01/20/15/06/oranges-1995056_640.jpg",
    "https://cdn.pixabay.com/photo/2014/11/05/15/57/salmon-518032_640.jpg",
    "https://cdn.pixabay.com/photo/2016/07/22/09/59/fruits-1534494_640.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _postRef = FirebaseDatabase.instance.ref().child('postitem');

    // Load the latest post
    _postRef
        .orderByChild('uid')
        .equalTo(_user.uid)
        .limitToLast(1)
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        var lastKey = data.keys.last;
        var lastPost = Map<dynamic, dynamic>.from(data[lastKey]);

        // When you get the latest post, load its offers
        _loadPostData1(lastPost[
            'post_uid']); // This will load the offers for the latest post
        setState(() {
          postsList.clear();
          postsList.insert(0, lastPost);
          selectedPost = lastPost;
          _selectedIndex = 0;
        });
      }
    });
  }

  Map<String, Map<dynamic, dynamic>>? offersMap = {};

  void _loadPostData1(String postUid) {
    FirebaseDatabase.instance
        .ref('offer')
        .orderByChild('post_uid')
        .equalTo(postUid)
        .onValue
        .listen((databaseEvent1) {
      if (databaseEvent1.snapshot.value != null) {
        Map<dynamic, dynamic>? offers =
            Map<dynamic, dynamic>.from(databaseEvent1.snapshot.value as Map);
        List<Map<dynamic, dynamic>> offersList = [];

        offers.forEach((key, value) {
          offersList.add(Map<dynamic, dynamic>.from(value));
        });
        postsList1.clear();
        setState(() {
          postsList1 = offersList;
          if (offersList.isNotEmpty) {
            print(postsList1);
            _selectedIndex1 = 0; // Select the first offer by default
            selectedOffers1 = offersList.first;
          }
        });
      } else {
        print('No offers found for postUid: $postUid');
      }
    });
  }

  void selectPayment(Map<dynamic, dynamic> postData) {
    setState(() {
      selectedPost = postData; // Update selectedPost with the chosen data
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("ข้อเสนอที่เข้ามา"),
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
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return Center(
                child: Text(
                  'ไม่มีข้อเสนอที่เข้ามา',
                  style: TextStyle(fontSize: 20),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              postsList.clear();
              Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
                  snapshot.data!.snapshot.value as Map);
              data.forEach((key, value) {
                postsList.add(Map<dynamic, dynamic>.from(value));
              });

              return Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: postsList.asMap().entries.map((entry) {
                        int idx = entry.key;
                        image_offer = List<String>.from(selectedOffers1!['imageUrls']);
                        Map<dynamic, dynamic> postData = entry.value;
                        image_post =
                            List<String>.from(selectedPost!['imageUrls']);
                        latitude = double.tryParse(
                            selectedPost!['latitude'].toString());
                        longitude = double.tryParse(
                            selectedPost!['longitude'].toString());
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: buildCircularNumberButton(idx, postData),
                        );
                      }).toList(),
                    ),
                  ),
                  Divider(),
                  selectedPost != null
                      ? Expanded(
                          child: ListView(children: [
                          Column(
                            children: [
                              ImageGalleryWidget(imageUrls: image_post,),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.tag,
                                          // เปลี่ยนเป็นไอคอนที่คุณต้องการ
                                          color: Colors
                                              .blue, // เปลี่ยนสีไอคอนตามความต้องการ
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'หมายเลขโพสต์ : ' +
                                              selectedPost!['postNumber'],
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          // เปลี่ยนเป็นไอคอนที่คุณต้องการ
                                          color: Colors
                                              .blue, // เปลี่ยนสีไอคอนตามความต้องการ
                                        ),
                                        SizedBox(
                                            width:
                                                8), // ระยะห่างระหว่างไอคอนและข้อความ
                                        Text(
                                          "ชื่อผู้โพสต์ : " +
                                              selectedPost!['username'],
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.date_range,
                                          // เปลี่ยนเป็นไอคอนที่คุณต้องการ
                                          color: Colors
                                              .blue, // เปลี่ยนสีไอคอนตามความต้องการ
                                        ),
                                        SizedBox(
                                            width:
                                                8), // ระยะห่างระหว่างไอคอนและข้อความ
                                        Text(
                                          'วันที่ : ' + selectedPost!['date'],
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.punch_clock,
                                          // เปลี่ยนเป็นไอคอนที่คุณต้องการ
                                          color: Colors
                                              .blue, // เปลี่ยนสีไอคอนตามความต้องการ
                                        ),
                                        Text(
                                          " เวลา :" +
                                              selectedPost!['time'] +
                                              ' น.',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 2,
                                          right: 15,
                                          top: 10,
                                          bottom: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF0F0F0),
                                          borderRadius:
                                              BorderRadius.circular(7.0),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(11.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ชื่อสิ่งของ : ' +
                                                    selectedPost!['item_name'],
                                                style: TextStyle(fontSize: 18),
                                              ),
                                              Text(
                                                'หมวดหมู่ : ' +
                                                    selectedPost!['type'],
                                                style: TextStyle(fontSize: 18),
                                              ),
                                              Text(
                                                'ยี่ห้อ : ' +
                                                    selectedPost!['brand'],
                                                style: TextStyle(fontSize: 18),
                                              ),
                                              Text(
                                                'รุ่น : ' +
                                                    selectedPost!['model'],
                                                style: TextStyle(fontSize: 18),
                                              ),
                                              Text(
                                                'รายละเอียด : ' +
                                                    selectedPost!['detail'],
                                                style: TextStyle(fontSize: 18),
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Center(
                                                  child: Image.asset(
                                                'assets/images/swap.png',
                                                width: 20,
                                              )),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                'ชื่อสิ่งของ : ' +
                                                    selectedPost!['item_name1'],
                                                style: TextStyle(fontSize: 18),
                                              ),
                                              Text(
                                                'ยี่ห้อ : ' +
                                                    selectedPost!['brand1'],
                                                style: TextStyle(fontSize: 18),
                                              ),
                                              Text(
                                                'รุ่น : ' +
                                                    selectedPost!['model1'],
                                                style: TextStyle(fontSize: 18),
                                              ),
                                              Text(
                                                'รายละเอียด : ' +
                                                    selectedPost!['details1'],
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration:
                                          BoxDecoration(border: Border.all()),
                                      height: 300,
                                      width: 380,
                                      child: GoogleMap(
                                        onMapCreated:
                                            (GoogleMapController controller) {
                                          mapController = controller;
                                        },
                                        initialCameraPosition: CameraPosition(
                                          target: LatLng(latitude!, longitude!),
                                          zoom: 12.0,
                                        ),
                                        markers: <Marker>{
                                          Marker(
                                            markerId:
                                                MarkerId('initialPosition'),
                                            position:
                                                LatLng(latitude!, longitude!),
                                            infoWindow: InfoWindow(
                                              title: 'Marker Title',
                                              snippet: 'Marker Snippet',
                                            ),
                                          ),
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Divider(),
                                    SizedBox(height: 10),
                                    Text(
                                      'ข้อเสนอที่เข้ามา',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    SizedBox(height: 10),

                                    SizedBox(
                                      height: 10,
                                    ),
                                    ImageGalleryWidget(imageUrls: image_offer,),//
                                    Container(
                                      width: 400,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(19),
                                        color: Color(0xFFF0F0F0),
                                      ),

                                      // Reduced horizontal padding
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          SizedBox(
                                            width: 203,
                                            height: 22,
                                            child: Text(
                                              "เลขที่ผู้ยื่นข้อเสนอ : " +
                                                  selectedOffers1![
                                                          'offerNumber']
                                                      .toString(),
                                              style: TextStyle(
                                                color: Color(0xFFA717DA),
                                                fontSize: 17,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w400,
                                                height: 0,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 6), // Added spacing
                                          SizedBox(
                                            width: 217,
                                            height: 21,
                                            child: Text(
                                              "วันที่ " +
                                                  selectedOffers1!['date']
                                                      .toString() +
                                                  " เวลา" +
                                                  selectedOffers1!['time']
                                                      .toString(),
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 17,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w400,
                                                height: 0,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          SizedBox(
                                            width: 217,
                                            height: 21,
                                            child: Text(
                                              "เวลา " +
                                                  selectedOffers1!['time']
                                                      .toString(),
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 17,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w400,
                                                height: 0,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 6), // Added spacing
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'ชื่อคนเสนอ : ',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 17,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w400,
                                                    height: 0,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'Simpson',
                                                  style: TextStyle(
                                                    color: Color(0xFFA717DA),
                                                    fontSize: 17,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w400,
                                                    height: 0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 6), // Added spacing
                                          Text(
                                            'ชื่อสิ่งของ : ' +
                                                selectedOffers1!['nameitem1'],
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 17,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w400,
                                              height: 0,
                                            ),
                                          ),
                                          SizedBox(height: 6), // Added spacing
                                          Text(
                                            'แบรนด์: ' +
                                                selectedOffers1!['brand1'],
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 17,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w400,
                                              height: 0,
                                            ),
                                          ),
                                          SizedBox(height: 6), // Added spacing
                                          Text(
                                            'รุ่น: ' +
                                                selectedOffers1!['model1'],
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 17,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w400,
                                              height: 0,
                                            ),
                                          ),
                                          SizedBox(height: 6), // Added spacing
                                          Text(
                                            'หมวดหมู่ : ' +
                                                selectedOffers1?['type1'],
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 17,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w400,
                                              height: 0,
                                            ),
                                          ),
                                          SizedBox(height: 6), // Added spacing
                                          Text(
                                            'รายละเอียด : ' +
                                                selectedOffers1?['detail1'],
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 17,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w400,
                                              height: 0,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                'สถานะการยื่น :',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 17,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w400,
                                                  height: 0,
                                                ),
                                              ),
                                              SizedBox(width: 6),
                                              Container(
                                                width: 11,
                                                height: 11,
                                                decoration: ShapeDecoration(
                                                  color: Color(0xFFBAFA7B),
                                                  shape: OvalBorder(
                                                      side:
                                                          BorderSide(width: 1)),
                                                ),
                                              ),
                                              Text(
                                                ' สามารถแลกเปลี่ยนได้',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 17,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w400,
                                                  height: 0,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              SizedBox(width: 115, height: 40),
                                              Container(
                                                width: 11,
                                                height: 11,
                                                decoration: ShapeDecoration(
                                                  color: Color(0xFFBAFA7B),
                                                  shape: OvalBorder(
                                                      side:
                                                          BorderSide(width: 1)),
                                                ),
                                              ),
                                              Text(
                                                ' ลบ',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 17,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w400,
                                                  height: 0,
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 6), // Added spacing
                                        ],
                                      ),
                                    ),

                                    //Text("เลขที่ผู้ยื่นข้อเสนอ" +selectedOffers1?['post_uid']),
                                    // Text(selectedOffers1?['time']),
                                    // Text(selectedOffers1?['post_uid']),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            children: [
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue),
                                                icon: Icon(Icons.chat,
                                                    color: Colors.white),
                                                onPressed: () {},
                                                label: Text(
                                                  'แชท',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 50,
                                              ),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green),
                                                icon: Icon(Icons.check,
                                                    color: Colors.white),
                                                onPressed: () {},
                                                label: Text(
                                                  'ยืนยัน',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red),
                                                icon: Icon(Icons.close,
                                                    color: Colors.white),
                                                onPressed: () {},
                                                label: Text(
                                                  'ปฎิเสธ',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ]))
                      : Text('ไม่มีประวัติการโพสต์')
                ],
              );
            } else {
              return Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://cdn-icons-png.flaticon.com/256/11191/11191755.png',
                      width: 100,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'ไม่มีข้อเสนอที่เข้ามา',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildCircularNumberButton1(
      int index, Map<dynamic, dynamic> offerData) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex1 = index; // อัปเดต index ที่เลือก
          selectedOffers1 = offerData; // อัปเดตข้อมูล offer ที่เลือก
        });
      },
      child: Container(
        width: 40,
        height: 40,
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _selectedIndex1 == index
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCircularNumberButton(int index, Map<dynamic, dynamic> postData) {
    return InkWell(
      onTap: () {
        _loadPostData1(
            postData['post_uid']); // Load offer data based on the post_uid
        setState(() {
          _selectedIndex = index; // Update the selected index
          selectedPost = postData; // Update the selected post data
          // Clear the previously selected offers when a new post is selected
          postsList1.clear(); // This will clear the offer list
          selectedOffers1 = null; // Clear selected offer
          _selectedIndex1 = -1; // Reset the selected index for offers
        });
      },
      child: Container(
        width: 40,
        height: 40,
        margin: EdgeInsets.all(4),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildCircularNumberButtonTest(int number) {
  return InkWell(
    onTap: () {
// โค้ดที่ต้องการให้ทำงานเมื่อปุ่มถูกกด
    },
    child: Container(
      width: 40, // ปรับขนาดตามต้องการ
      height: 40, // ปรับขนาดตามต้องการ
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black, // สีขอบ
          width: 2.0, // ความกว้างขอบ
        ),
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

MyTextStyle() {
  return TextStyle(
    fontSize: 18,
    color: Colors.black,
  );
}