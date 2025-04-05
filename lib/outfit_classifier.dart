import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class OutfitClassifier {
  Interpreter? interpreter;
  List<String> _labels = [];

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/model/clothing_model.tflite');
      print("TFLite model loaded successfully.");
      
      String labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split("\n").where((label) => label.isNotEmpty).toList();

      print("Labels loaded: ${_labels.length}");
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

    // Adjust the input shape (e.g., 1 image, 224x224, 3 channels)
    var inputData = imageData.reshape([1, 224, 224, 3]);

    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
    interpreter!.run(inputData, output);

   int predictedIndex = output[0].indexOf(output[0].reduce((double a, double b) => a > b ? a : b));



    return _labels[predictedIndex];
  }
}
