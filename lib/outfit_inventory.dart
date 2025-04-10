import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quiz3_1/outfit_all.dart';
import 'package:quiz3_1/outfit_screen.dart';

class OutfitInventory extends StatefulWidget {
  _OutfitInventoryState createState() => _OutfitInventoryState();
}

class _OutfitInventoryState extends State<OutfitInventory> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  OutfitScreen outfitScreen = OutfitScreen();

  StreamSubscription? stream;

  List<DocumentSnapshot> tops = [];
  List<DocumentSnapshot> bottoms = [];
  List<DocumentSnapshot> shoes = [];

  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Digital Wardrobe"),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => OutfitScreen()));
              },
              child: Text("Add Clothes"))
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildOutfitCategory('Tops', tops.take(3).toList()),
            SizedBox(height: 20),
            buildOutfitCategory('Bottoms', bottoms.take(3).toList()),
            SizedBox(height: 20),
            buildOutfitCategory('Shoes', shoes.take(3).toList()),
          ],
        ),
      ),
    );
  }

  void _loadOutfits() {
   

    stream =
        firestore.collection('outfits').snapshots().listen((querySnapshot) {
      tops.clear();
      bottoms.clear();
      shoes.clear();

      for (var doc in querySnapshot.docs) {
        String outfitType = doc['outfitType'];

        if (outfitType.toLowerCase().contains('top')) {
          tops.add(doc);
        } else if (outfitType.toLowerCase().contains('bottom')) {
          bottoms.add(doc);
        } else if (outfitType.toLowerCase().contains('shoes')) {
          shoes.add(doc);
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    stream?.cancel();
    super.dispose();
  }

  Widget buildOutfitCategory(String title, List<DocumentSnapshot> outfits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => OutfitAll(category: title, items: outfits,)));
                },
                child: Text("See All"))
          ],
        ),
        SizedBox(
          height: 20,
        ),
        outfits.isEmpty
            ? Text("No outfits in this category.")
            : ListView.builder(
            
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: outfits.length,
                itemBuilder: (context, index) {
                  var outfit = outfits[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(outfit['outfitType']),
                      subtitle: Text("Color:   ${outfit['color']}"),
                      leading: outfit['localPath'] != null
                          ? Image.file(
                              File(outfit['localPath']),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  );
                })
      ],
    );
  }
}
