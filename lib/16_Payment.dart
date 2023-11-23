import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

import '17_PaymentSuccess.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//หน้าแนปสลิปการโอนเงิน

class Payment extends StatefulWidget {
  const Payment({super.key});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  XFile? _imageFile;
  late List<String> package;
  late String dropdownValue;

  Future<void> _showPaymentConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: const Text(
            'ยืนยันการชำระเงิน',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'คุณต้องการที่จะชำระเงินหรือไม่?',
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => PaymentSuccess()),
                      );
                    },
                    child: const Text(
                      'ยืนยัน',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    package = [
      'แพ็คเก็จ 1 เดือน : 50 บาท',
      'แพ็คเก็จ 2 เดือน : 100 บาท',
      'แพ็คเก็จ 3 เดือน : 150 บาท',
    ];
    dropdownValue = package.first;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("ชำระเงิน"),
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
        body: Column(
          children: [
            Center(
              child: Container(
                  child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                child: Image.asset(
                  "assets/images/qrcodepromptpay.jpeg",
                  width: 225,
                  height: 225,
                ),
              )),
            ),
            Text(
              'บริษัท ????????????? จำกัด',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 10,
            ),
            DropdownMenu<String>(
              width: 280,
              initialSelection: package.first,
              onSelected: (String? value) {
                setState(() {
                  dropdownValue = value!;
                });
              },
              dropdownMenuEntries:
                  package.map<DropdownMenuEntry<String>>((String value) {
                return DropdownMenuEntry<String>(value: value, label: value);
              }).toList(),
            ),
            const SizedBox(
              height: 15,
            ),
            imgPayment(),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 50,
              width: 250,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {
                  _showPaymentConfirmationDialog();
                },
                child: Text(
                  "ชำระเงิน",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void takePhoto(ImageSource source) async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: source,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });

      Navigator.pop(context);
    }
  }

  Widget imgPayment() {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
                context: context, builder: ((Builder) => bottomSheet()));
          },
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(border: Border.all()),
            child: Center(
              child: _imageFile != null
                  ? Image.file(
                      File(_imageFile?.path ?? ''),
                      width: 350,
                      height: 350,
                      fit: BoxFit.contain,
                    )
                  : Image.asset(
                      'assets/images/add_slip.png',
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget bottomSheet() {
    return Container(
      height: 100.0,
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: Column(
        children: <Widget>[
          Text(
            "เลือกรูปภาพของคุณ",
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton.icon(
                onPressed: () {
                  takePhoto(ImageSource.camera);
                },
                icon: Icon(Icons.camera),
                label: Text('กล้อง'),
              ),
              TextButton.icon(
                onPressed: () {
                  takePhoto(ImageSource.gallery);
                },
                icon: Icon(Icons.camera),
                label: Text('แกลลอรี่'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
