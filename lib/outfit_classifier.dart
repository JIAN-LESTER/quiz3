import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class OutfitClassifier {
  Interpreter? interpreter, colorInterpreter;

  List<String> _labels = [];
  List<String> colorsLabel = [];

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/model/clothing_model.tflite');
      colorInterpreter = await Interpreter.fromAsset('assets/model/colors_model.tflite');
      print("TFLite model loaded successfully.");

      String labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split("\n").where((label) => label.isNotEmpty).toList();

      String colorLabelsData = await rootBundle.loadString('assets/color_label.txt');
      colorsLabel = colorLabelsData.split("\n").where((label) => label.isNotEmpty).toList();

      print("Labels loaded: ${_labels.length}, Color labels loaded: ${colorsLabel.length}");
    } catch (e) {
      print("Error loading model or labels: $e");
    }
  }

  String classifyImage(List<double> imageData) {
    if (interpreter == null) {
      throw Exception("TFLite Interpreter is not initialized. Call loadModel() first.");
    }

    if (_labels.isEmpty) {
      throw Exception("Labels are not loaded.");
    }

    var inputData = imageData.reshape([1, 224, 224, 3]);
    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
    interpreter!.run(inputData, output);

    int predictedIndex = output[0]
        .indexOf(output[0].reduce((double a, double b) => a > b ? a : b));

    return _labels[predictedIndex];
  }

  String classifyColor(List<double> imageData) {
    if (colorInterpreter == null) {
      throw Exception("Color TFLite Interpreter is not initialized. Call loadModel() first.");
    }

    if (colorsLabel.isEmpty) {
      throw Exception("Color labels are not loaded.");
    }

    var inputData = imageData.reshape([1, 224, 224, 3]);
    var output = List.filled(1 * colorsLabel.length, 0.0).reshape([1, colorsLabel.length]);
    colorInterpreter!.run(inputData, output);

    int predictedIndex = output[0]
        .indexOf(output[0].reduce((double a, double b) => a > b ? a : b));

    return colorsLabel[predictedIndex];
  }

  // Process the segmented image (background removed)
  List<double> preprocessSegmentedImage(File segmentedImage) {
    img.Image? imgData = img.decodeImage(segmentedImage.readAsBytesSync());
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
}
