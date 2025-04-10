import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:quiz3_1/outfit_classifier.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class OutfitScreen extends StatefulWidget {
  @override
  _OutfitScreenState createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  File? image;
  final ImagePicker picker = ImagePicker();
  final OutfitClassifier classifier = OutfitClassifier();
  String prediction = "";
  String color = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    classifier.loadModel();
  }

    Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
        prediction = "";
        color = "";
      });

      // Preprocess the image
      List<double> imageData = await preprocessImage(image!);

      // Classify the outfit type
      String outfitResult = classifier.classifyImage(imageData);

      // Classify the color using the color model
      String colorResult = classifier.classifyColor(imageData);

      setState(() {
        prediction = outfitResult;
        color = colorResult;
      });
    }
  }

  Future<void> addOutfitToLocalFirestore() async {
    if (image == null || prediction.isEmpty || color.isEmpty) {
      print("Missing image or classification result.");
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('outfits').add({
        'outfitType': prediction,
        'color': color,
        'localPath': image!.path,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Outfit saved locally!")),
      );

      setState(() {
        image = null;
        prediction = "";
        color = "";
      });
    } catch (e) {
      print("Error saving outfit: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save outfit.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  

  Future<List<double>> preprocessImage(File image) async {
    img.Image? imgData = img.decodeImage(await image.readAsBytes());
    img.Image resizedImage = img.copyResize(imgData!, width: 224, height: 224);

    List<double> imageData = [];
    for (int i = 0; i < resizedImage.height; i++) {
      for (int j = 0; j < resizedImage.width; j++) {
        int pixel = resizedImage.getPixel(j, i);
        int r = (pixel >> 16) & 0xFF;
        int g = (pixel >> 8) & 0xFF;
        int b = pixel & 0xFF;

        imageData.add(r / 255.0);
        imageData.add(g / 255.0);
        imageData.add(b / 255.0);
      }
    }
    return imageData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Outfit")),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(image!, height: 300),
                  ),
                SizedBox(height: 20),
                if (prediction.isNotEmpty)
                  Text("Outfit: $prediction", style: TextStyle(fontSize: 20)),
                if (color.isNotEmpty)
                  Text("Color: $color", style: TextStyle(fontSize: 20)),
                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: pickImage,
                  child: Text("Take a Picture"),
                ),

                if (image != null && prediction.isNotEmpty && color.isNotEmpty)
                  SizedBox(height: 20),
                if (image != null && prediction.isNotEmpty && color.isNotEmpty)
                  ElevatedButton(
                    onPressed: isLoading ? null : addOutfitToLocalFirestore,
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Store Outfit"),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
