import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'outfit_classifier.dart';

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

  // Assuming you have an object segmentation model
  Interpreter? objectSegInterpreter;

  @override
  void initState() {
    super.initState();
    classifier.loadModel();
    loadObjectSegmentationModel();
  }

  Future<void> loadObjectSegmentationModel() async {
    try {
      objectSegInterpreter = await Interpreter.fromAsset('assets/model/segmentation_model.tflite');
      print("Object segmentation model loaded.");
    } catch (e) {
      print("Error loading object segmentation model: $e");
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
        prediction = "";
        color = "";
      });

      // Perform object segmentation to isolate clothes
      File segmentedImage = await applyObjectSegmentation(image!);

      // Preprocess the segmented image
      List<double> imageData = classifier.preprocessSegmentedImage(segmentedImage);

      // Get predictions
      String outfitResult = classifier.classifyImage(imageData);
      String colorResult = classifier.classifyColor(imageData);

      setState(() {
        prediction = outfitResult;
        color = colorResult;
      });
    }
  }

  Future<File> applyObjectSegmentation(File image) async {
    // Here, use your object segmentation model (e.g., DeepLabV3) to segment the image
    // Return the image with the background removed
    // For now, just returning the original image
    return image;
  }

  // Upload the outfit data to Firebase
  Future<void> uploadToFirebase() async {
    if (prediction.isNotEmpty && color.isNotEmpty && image != null) {
      try {
        setState(() {
          isLoading = true;
        });

        // Prepare the outfit data
        Map<String, dynamic> outfitData = {
          'image': image!.path, // Store image path or upload the image if needed
          'prediction': prediction,
          'color': color,
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Add the outfit data to Firestore
        await FirebaseFirestore.instance.collection('outfits').add(outfitData);

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Outfit added to Firebase")));
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error uploading to Firebase: $e")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please classify the outfit first")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Outfit")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(image!, height: 300, fit: BoxFit.cover),
              ),
            const SizedBox(height: 25),
            if (prediction.isNotEmpty || color.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Column(
                    children: [
                      if (prediction.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.checkroom, color: Colors.blueAccent),
                            const SizedBox(width: 10),
                            Text("Outfit: $prediction", style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      const SizedBox(height: 10),
                      if (color.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.color_lens, color: Colors.purple),
                            const SizedBox(width: 10),
                            Text("Color: $color", style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take a Picture"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: uploadToFirebase,
                icon: const Icon(Icons.upload),
                label: const Text("Store Outfit"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
