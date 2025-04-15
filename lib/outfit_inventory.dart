import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quiz3_1/matched_outfits.dart';
import 'package:quiz3_1/outfit_all.dart';
import 'package:quiz3_1/outfit_screen.dart';

class OutfitInventory extends StatefulWidget {
  @override
  _OutfitInventoryState createState() => _OutfitInventoryState();
}

class _OutfitInventoryState extends State<OutfitInventory> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  StreamSubscription? stream;

  List<DocumentSnapshot> tops = [];
  List<DocumentSnapshot> bottoms = [];
  List<DocumentSnapshot> shoes = [];

  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }

  void _loadOutfits() {
    stream =
        firestore.collection('outfits').snapshots().listen((querySnapshot) {
      tops.clear();
      bottoms.clear();
      shoes.clear();

      for (var doc in querySnapshot.docs) {
        String outfitType = doc['outfitType'].toString().toLowerCase();
        if (outfitType.contains('top') ||
            outfitType.contains('tshirt') ||
            outfitType.contains('poloshirt') ||
            outfitType.contains('polo') ||
            outfitType.contains('longsleeve')) {
          tops.add(doc);
        } else if (outfitType.contains('bottom') ||
            outfitType.contains('pants') ||
            outfitType.contains('shorts')) {
          bottoms.add(doc);
        } else if (outfitType.contains('shoes')) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Digital Wardrobe"),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchedOutfits(
                    tops: tops,
                    bottoms: bottoms,
                    shoes: shoes,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text("Suggest Outfit"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildOutfitCategory('Tops', tops),
            const SizedBox(height: 20),
            buildOutfitCategory('Bottoms', bottoms),
            const SizedBox(height: 20),
            buildOutfitCategory('Shoes', shoes),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => OutfitScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Clothes"),
        tooltip: "Add Clothes",
      ),
    );
  }

  Widget buildOutfitCategory(String title, List<DocumentSnapshot> outfits) {
    final previewOutfits = outfits.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OutfitAll(category: title),
      ),
    );
  },
  child: const Text("See All"),
),

          ],
        ),
        const SizedBox(height: 10),
        outfits.isEmpty
            ? const Text(
                "No outfits in this category.",
                style: TextStyle(color: Colors.grey),
              )
            : Column(
                children: previewOutfits.map((outfit) {
                  String? imagePath = outfit['localPath'];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imagePath != null
                            ? Image.file(
                                File(imagePath),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                      ),
                      title: Text(
                        "Type: ${outfit['outfitType']}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text("Color: ${outfit['color']}"),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}
