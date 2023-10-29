/*
 * Copyright 2023 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';
import 'package:arabic_fonts_generator/helper/fontDatabase.dart';
import 'package:arabic_fonts_generator/main.dart';
import 'package:arabic_fonts_generator/ui/fontGeneratorPage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../helper/image_classification_helper.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  ImageClassificationHelper? imageClassificationHelper;
  final imagePicker = ImagePicker();
  String? imagePath;
  img.Image? image;
  Map<String, double>? classification;
  bool cameraIsAvailable = Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    imageClassificationHelper = ImageClassificationHelper();
    imageClassificationHelper!.initHelper();
    super.initState();
  }

  // Clean old results when press some take picture button
  void cleanResult() {
    imagePath = null;
    image = null;
    classification = null;
    setState(() {});
  }

  // Process picked image
  Future<void> processImage() async {
    if (imagePath != null) {
      final rawImage = img.decodeImage(File(imagePath!).readAsBytesSync());
      image = rawImage;
      setState(() {});
      classification = await imageClassificationHelper?.inferenceImage(image!);
      print(classification);
      setState(() {});
    }
  }

  @override
  void dispose() {
    imageClassificationHelper?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                TextButton.icon(
                  onPressed: () async {
                    cleanResult();
                    final result = await imagePicker.pickImage(
                      source: ImageSource.camera,
                    );

                    imagePath = result?.path;
                    setState(() {});
                    processImage();
                  },
                  icon: const Icon(
                    Icons.camera,
                    size: 48,
                  ),
                  label: const Text("Take a photo"),
                ),
              TextButton.icon(
                onPressed: () async {
                  cleanResult();
                  final result = await imagePicker.pickImage(
                    source: ImageSource.gallery,
                  );

                  imagePath = result?.path;
                  setState(() {});
                  processImage();
                },
                icon: const Icon(
                  Icons.photo,
                  size: 48,
                ),
                label: const Text("Pick from gallery"),
              ),
            ],
          ),
          const Divider(color: Colors.black),
          Expanded(
              child: Stack(
            alignment: Alignment.center,
            children: [
              if (imagePath != null) Image.file(File(imagePath!)),
              if (image == null)
                const Text("Take a photo or choose one from the gallery to "
                    "inference."),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show classification result
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          if (classification != null)
                            ...(classification!.entries.toList()
                                  ..sort(
                                    (a, b) => a.value.compareTo(b.value),
                                  ))
                                .reversed
                                .take(3)
                                .map(
                                  (e) => Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.white,
                                    child: Column(
                                      children: [
                                        Text("Detected Font :${e.key}"),
                                        MaterialButton(onPressed: () async {
                                          await FontDatabase.addFontIfNotExists('${e.key}'.trim(),context).then((value) => Get.back());
                                        },child: Text("Save To Your Font List",style: TextStyle(color: Colors.white),),color: kMainColor,),
                                        MaterialButton(onPressed: (){
                                          Get.to(()=>FontGeneratorPage(style: TextStyle(
                                            fontFamily: '${e.key}'.trim(),
                                            fontSize: 24.0,
                                            color: Colors.black, // Change color as needed
                                          ),));
                                        },child: Text("Generate Text Of Font",style: TextStyle(color: Colors.white),),color: kMainColor,),
                                      ],
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }
}
