import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class FontDetectorScreen extends StatefulWidget {
  const FontDetectorScreen({Key? key});

  @override
  State<FontDetectorScreen> createState() => _FontDetectorScreenState();
}

class _FontDetectorScreenState extends State<FontDetectorScreen> {
  late ImagePicker _imagePicker;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
    loadModel();
  }

  loadModel() async {
    String? res = await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/label.txt",
      numThreads: 1,
      isAsset: true,
      useGpuDelegate: false,
    );
    print(res);
  }

  Future<void> recognize() async {
    if (_imagePath != null) {
      final rawImage = img.decodeImage(File(_imagePath!).readAsBytesSync());

      // Resize the image to (80 x 80)
      final resizedImage = img.copyResize(rawImage!, width: 160, height: 160);

      // Convert the image to grayscale and normalize it
      final grayscaleImage = img.grayscale(resizedImage);

      // Ensure the image data is of the expected size (25600 bytes)
      print(grayscaleImage.length);
      if (grayscaleImage.length == 25600) {
        final input = grayscaleImage.getBytes();

        try{
          var recognitions = await Tflite.runModelOnBinary(
            binary: input,
            numResults: 2,
            threshold: 0.2,
            asynch: true,
          );
          print(recognitions);
        }catch(e){
          print(e);
        }

      } else {
        print("Image size is not 25600 bytes.");
      }
    } else {
      print("Image not selected.");
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.getImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MaterialButton(
              onPressed: () => pickImage(ImageSource.gallery),
              child: Text("Pick Image from Gallery"),
            ),
            MaterialButton(
              onPressed: () => pickImage(ImageSource.camera),
              child: Text("Take a Picture"),
            ),
            MaterialButton(
              onPressed: () async {
                await loadModel();
                await recognize();
              },
              child: Text("Recognize"),
            ),
          ],
        ),
      ),
    );
  }
}
