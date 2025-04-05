import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiz3_1/outfit_classifier.dart';

import 'package:image/image.dart' as img;

class OutfitScreen extends StatefulWidget {
  @override
  _OutfitScreenState createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  File? image;
  final ImagePicker picker = ImagePicker();
  final OutfitClassifier classifier = OutfitClassifier();
  String prediction = "";

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
      });

      List<double> imageData = await preprocessImage(image!);
      String result = classifier.classifyImage(imageData);

      setState(() {
        prediction = result;
      });
    }
  }


Future<List<double>> preprocessImage(File image) async {
  // Load the image using the image package
  img.Image? imgData = img.decodeImage(await image.readAsBytes());

  // Resize the image to the expected size (e.g., 224x224)
  img.Image resizedImage = img.copyResize(imgData!, width: 224, height: 224);

  // Normalize the image and convert it into a list of doubles (flattened)
  List<double> imageData = [];
  for (int i = 0; i < resizedImage.height; i++) {
    for (int j = 0; j < resizedImage.width; j++) {
      int pixel = resizedImage.getPixel(j, i);  // Get the pixel as an integer

      // Extract the RGB components using bitwise operations
      int r = (pixel >> 16) & 0xFF; // Extract the red component
      int g = (pixel >> 8) & 0xFF;  // Extract the green component
      int b = pixel & 0xFF;         // Extract the blue component

      // Normalize the components and add them to the imageData list
      imageData.add(r / 255.0);  // Normalize red component
      imageData.add(g / 255.0);  // Normalize green component
      imageData.add(b / 255.0);  // Normalize blue component
    }
  }

  return imageData;
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Outfit Classifier"),
      ),
      body: Center(
        child: Column(
          children: [
            if (image != null) Image.file(image!),
            Text(
              prediction,
              style: TextStyle(fontSize: 20),
            ),
            ElevatedButton(
                onPressed: pickImage, child: Text("Take a Picture")),
          ],
        ),
      ),
    );
  }
}
