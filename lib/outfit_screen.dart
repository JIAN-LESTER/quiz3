import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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

      List<double> imageData = await preprocessImage(image!);
      String outfitResult = classifier.classifyImage(imageData);
      String colorResult = classifier.classifyColor(imageData);

      setState(() {
        prediction = outfitResult;
        color = colorResult;
      });
    }
  }

  Future<void> addOutfitToLocalFirestore() async {
    if (image == null || prediction.isEmpty || color.isEmpty) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('outfits').add({
        'outfitType': prediction,
        'color': color,
        'localPath': image!.path,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outfit saved successfully!")),
      );

      setState(() {
        image = null;
        prediction = "";
        color = "";
      });
    } catch (e) {
      print("Error saving outfit: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save outfit.")),
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
            if (image != null && prediction.isNotEmpty && color.isNotEmpty)
              ElevatedButton.icon(
                onPressed: isLoading ? null : addOutfitToLocalFirestore,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(isLoading ? "Saving..." : "Store Outfit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
