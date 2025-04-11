import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MatchedOutfits extends StatefulWidget {
  final List<DocumentSnapshot> tops;
  final List<DocumentSnapshot> bottoms;
  final List<DocumentSnapshot> shoes;

  const MatchedOutfits({
    super.key,
    required this.tops,
    required this.bottoms,
    required this.shoes,
  });

  @override
  _MatchedOutfitState createState() => _MatchedOutfitState();
}

class _MatchedOutfitState extends State<MatchedOutfits> {
  List<Map<String, DocumentSnapshot>> suggestedOutfits = [];
  int curr = 0;

  @override
  void initState() {
    super.initState();
    generateSuggestions();
  }

  void showNextSuggestion() {
    setState(() {
      curr = (curr + 1) % suggestedOutfits.length;
    });
  }

  void generateSuggestions() {
    for (var top in widget.tops) {
      for (var bottom in widget.bottoms) {
        for (var shoe in widget.shoes) {
          final topColor = top['color'];
          final bottomColor = bottom['color'];
          final shoeColor = shoe['color'];

          if (colorsGoesWell(topColor, bottomColor, shoeColor)) {
            suggestedOutfits.add({
              'top': top,
              'bottom': bottom,
              'shoes': shoe,
            });
          }
        }
      }
    }
  }

  bool colorsGoesWell(String top, String bottom, String shoes) {
    top = top.toLowerCase();
    bottom = bottom.toLowerCase();
    shoes = shoes.toLowerCase();

    if (top == 'white' || bottom == 'white' || shoes == 'white') return true;
    if (top == 'black' || bottom == 'white' || shoes == 'white') return true;
    if (top == 'blue' && bottom == "white") return true;
    if (top == 'black' && bottom == 'grey') return true;
    if (top == bottom && bottom == shoes) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Suggested Outfits"),
      ),
      body: suggestedOutfits.isEmpty
          ? const Center(
              child: Text(
                "No outfit suggestion found",
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                   
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['top', 'bottom', 'shoes'].map((key) {
                            final doc = suggestedOutfits[curr][key]!;
                            final imagePath = doc['localPath'];
                            return Column(
                              children: [
                                Text(
                                  key.toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imagePath != null
                                      ? Image.file(
                                          File(imagePath),
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 90,
                                          height: 90,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: showNextSuggestion,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Next Suggestion"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
