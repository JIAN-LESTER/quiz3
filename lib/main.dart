import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quiz3_1/firebase_options.dart';
import 'package:quiz3_1/outfit_classifier.dart';
import 'package:quiz3_1/outfit_inventory.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  OutfitClassifier classifier = OutfitClassifier();
  await classifier.loadModel();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp(classifier: classifier));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required OutfitClassifier classifier});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: OutfitInventory());
  }
}
