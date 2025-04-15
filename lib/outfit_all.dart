import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quiz3_1/matched_outfits.dart';
import 'package:quiz3_1/outfit_screen.dart';

class OutfitAll extends StatelessWidget {
  final String category;

  const OutfitAll({
    super.key,
    required this.category,
  });


  bool isMatch(String outfitType, String category) {
    outfitType = outfitType.toLowerCase();
    category = category.toLowerCase();

    if (category == 'tops') {
      return outfitType.contains('top') ||
          outfitType.contains('tshirt') ||
          outfitType.contains('polo') ||
          outfitType.contains('shirt') ||
          outfitType.contains('longsleeve');
    } else if (category == 'bottoms') {
      return outfitType.contains('bottom') ||
          outfitType.contains('pants') ||
          outfitType.contains('shorts');
    } else if (category == 'shoes') {
      return outfitType.contains('shoes') ||
          outfitType.contains('sneakers') ||
          outfitType.contains('footwear');
    }
    return false;
  }

  void navigateToSuggestions(BuildContext context, List<DocumentSnapshot> items) {
    final tops = items.where((doc) {
      final type = doc['outfitType'].toString().toLowerCase();
      return type.contains('shirt') || type.contains('top') || type.contains('polo');
    }).toList();

    final bottoms = items.where((doc) {
      final type = doc['outfitType'].toString().toLowerCase();
      return type.contains('pants') || type.contains('shorts') || type.contains('bottom');
    }).toList();

    final shoes = items.where((doc) {
      final type = doc['outfitType'].toString().toLowerCase();
      return type.contains('shoes');
    }).toList();

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        title: Text('All $category'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance.collection('outfits').get();
              navigateToSuggestions(context, snapshot.docs);
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text("Suggest Outfits"),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('outfits').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final allDocs = snapshot.data!.docs;
          final filteredItems = allDocs.where((doc) {
            final outfitType = doc['outfitType'] ?? '';
            return isMatch(outfitType, category);
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final doc = filteredItems[index];
              final imagePath = doc['localPath'];
              final outfitType = doc['outfitType'];
              final color = doc['color'];
              final docID = doc.id;

              return GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Outfit"),
                      content: const Text("Are you sure you want to delete this outfit?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('outfits')
                                .doc(docID)
                                .delete();

                            if (imagePath != null) {
                              final file = File(imagePath);
                              if (await file.exists()) {
                                await file.delete();
                              }
                            }

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Outfit Deleted")),
                            );
                          },
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: imagePath != null
                            ? Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                              )
                            : Container(color: Colors.grey),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Type: $outfitType"),
                            Text("Color: $color"),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => OutfitScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Clothes"),
        tooltip: "Add Clothes",
      ),
     
    );
  }
}
