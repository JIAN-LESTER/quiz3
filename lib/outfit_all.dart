import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quiz3_1/matched_outfits.dart';
import 'package:quiz3_1/outfit_screen.dart';

class OutfitAll extends StatelessWidget {
  final String category;
  final List<DocumentSnapshot> items;

  const OutfitAll({
    super.key,
    required this.category,
    required this.items,
  });

   void navigateToSuggestions(BuildContext context) {
    final tops = items.where((doc) {
      final type = doc['outfitType'].toString().toLowerCase();
      return type.contains('shirt');
    }).toList();

    final bottoms = items.where((doc) {
      final type = doc['outfitType'].toString().toLowerCase();
      return type.contains('pants') || type.contains('shorts');
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
            onPressed: () => navigateToSuggestions(context),
            icon: Icon(Icons.auto_awesome),
            label: Text(
              "Suggest Outfits",
             
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final doc = items[index];
          final imagePath = doc['localPath'];
          final outfitType = doc['outfitType'];
          final color = doc['color'];
          final docID = doc.id;

          return GestureDetector(
              onLongPress: () {
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: Text("Delete Outfit"),
                          content: Text(
                              "Are you sure you want to delete this outfit?"),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("Cancel")),
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
                                      SnackBar(
                                          content: Text("Outfit Deleted")));
                                },
                                child: Text(
                                  "Delete",
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                )),
                          ],
                        ));
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
              ));
        },
      ),
    floatingActionButton: FloatingActionButton.extended(onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => OutfitScreen()));
          },
          icon:  Icon(Icons.add),
          label: Text("Add Clothes"),
          tooltip:"Add Clothes",
          
        ),
    );
  }
}
