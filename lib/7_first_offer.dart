//หน้าข้อเสนอที่เข้ามา
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OfferRequest extends StatefulWidget {
  const OfferRequest({Key? key}) : super(key: key);

  @override
  State<OfferRequest> createState() => _OfferRequestState();
}

class _OfferRequestState extends State<OfferRequest> {
  late User _user;
  double? latitude;
  double? longitude;
  late DatabaseReference _postRef;
  List<Map<dynamic, dynamic>> postsList = [];
  int _selectedIndex = -1;
  Map<dynamic, dynamic>? selectedPost;
  late GoogleMapController mapController;
  int? mySlideindex;
  List<String> image_post = [];
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
    selectedPost = null;

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
        var lastPayment = Map<dynamic, dynamic>.from(data[lastKey]);

        // Since we are listening to the last payment, we clear the list to ensure
        // it only contains the latest payment and corresponds to the first button.
        postsList.clear();

        setState(() {
          postsList.insert(0, lastPayment); // Insert at the start of the list
          selectedPost = lastPayment;
          _selectedIndex = 0; // This ensures the first button is selected
        });
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
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, top: 8, right: 8),
                                      child: SizedBox(
                                        height: 300,
                                        child: PageView.builder(
                                          onPageChanged: (value) {
                                            setState(() {
                                              mySlideindex = value;
                                            });
                                          },
                                          itemCount: image_post.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(20.0),
                                              child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Image.network(
                                                    image_post[index],
                                                    fit: BoxFit.cover,
                                                  )),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 60,
                                      width: 300,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: image_post.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Container(
                                              height: 20,
                                              width: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: index == mySlideindex
                                                    ? Colors.deepPurple
                                                    : Colors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .tag, // เปลี่ยนเป็นไอคอนที่คุณต้องการ
                                          color: Colors
                                              .blue, // เปลี่ยนสีไอคอนตามความต้องการ
                                        ),
                                        SizedBox(
                                            width:
                                                8), // ระยะห่างระหว่างไอคอนและข้อความ
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
                                          Icons
                                              .person, // เปลี่ยนเป็นไอคอนที่คุณต้องการ
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
                                          Icons
                                              .date_range, // เปลี่ยนเป็นไอคอนที่คุณต้องการ
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
                                          Icons
                                              .punch_clock, // เปลี่ยนเป็นไอคอนที่คุณต้องการ
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
                                          color: Color.fromARGB(
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
                                    //ข้อเสนอที่เข้ามา
                                    Text('ข้อเสนอที่เข้ามา'),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        buildCircularNumberButtonTest(1),
                                        SizedBox(
                                          width: 20,
                                        ),
                                        buildCircularNumberButtonTest(2),
                                        SizedBox(
                                          width: 20,
                                        ),
                                        buildCircularNumberButtonTest(3),
                                        SizedBox(
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, top: 8, right: 8),
                                      child: SizedBox(
                                        height: 300,
                                        child: PageView.builder(
                                          onPageChanged: (value) {
                                            setState(() {
                                              mySlideindex = value;
                                            });
                                          },
                                          itemCount: foodList.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.all(20.0),
                                              child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Image.network(
                                                    foodList[index],
                                                    fit: BoxFit.cover,
                                                  )),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 60,
                                      width: 300,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: foodList.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Container(
                                              height: 20,
                                              width: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: index == mySlideindex
                                                    ? Colors.deepPurple
                                                    : Colors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .person, // เปลี่ยนเป็นไอคอนที่คุณต้องการ
                                                color: Colors
                                                    .blue, // เปลี่ยนสีไอคอนตามความต้องการ
                                              ),
                                              SizedBox(
                                                  width:
                                                      8), // ระยะห่างระหว่างไอคอนและข้อความ
                                              Text(
                                                "ชื่อ : Prampree ",
                                                style: MyTextStyle(),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .date_range, // เปลี่ยนเป็นไอคอนที่คุณต้องการ
                                                color: Colors
                                                    .blue, // เปลี่ยนสีไอคอนตามความต้องการ
                                              ),
                                              SizedBox(
                                                  width:
                                                      8), // ระยะห่างระหว่างไอคอนและข้อความ
                                              Text(
                                                "วันที่ 9/8/2566",
                                                style: MyTextStyle(),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .punch_clock, // เปลี่ยนเป็นไอคอนที่คุณต้องการ
                                                color: Colors
                                                    .blue, // เปลี่ยนสีไอคอนตามความต้องการ
                                              ),
                                              Text(
                                                " เวลา 12:00 น.",
                                                style: MyTextStyle(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            decoration: BoxDecoration(
                                              color: Color.fromARGB(
                                                  255, 170, 170, 169),
                                              borderRadius: BorderRadius.circular(
                                                  12.0), // ทำให้ Container โค้งมน
                                            ),
                                            padding: EdgeInsets.all(
                                                16), // ระยะห่างของเนื้อหาจาก Container
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "ชื่อสิ่งของ :  เสื้อ",
                                                  style: MyTextStyle(),
                                                ),
                                                Text(
                                                  "หมวดหมู่ : เสื้อผ้า",
                                                  style: MyTextStyle(),
                                                ),
                                                Text(
                                                  "ยี่ห้อ : ตะขาบ",
                                                  style: MyTextStyle(),
                                                ),
                                                Text(
                                                  "รุ่น :  T-Shire",
                                                  style: MyTextStyle(),
                                                ),
                                                Text(
                                                  'รายละเอียด :สภาพการใช้งาน 50%',
                                                  style: MyTextStyle(),
                                                ),
                                              ],
                                            ),
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
                    Text('ไม่มีข้อเสนอที่เข้ามา',style: TextStyle(fontSize: 20),),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildCircularNumberButton(int index, Map<dynamic, dynamic> postData) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index; // Update the selected index
          selectedPost = postData; // Update the selected payment data
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
