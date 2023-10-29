import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as image_lib;
import 'package:arabic_fonts_generator/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class IsolateInference {
  static const String _debugName = "TFLITE_INFERENCE";
  final ReceivePort _receivePort = ReceivePort();
  late Isolate _isolate;
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(entryPoint, _receivePort.sendPort,
        debugName: _debugName);
    _sendPort = await _receivePort.first;
  }

  Future<void> close() async {
    _isolate.kill();
    _receivePort.close();
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final InferenceModel isolateModel in port) {
      image_lib.Image? img;
      if (isolateModel.isCameraFrame()) {
        img = ImageUtils.convertCameraImage(isolateModel.cameraImage!);
      } else {
        img = isolateModel.image;
      }

      // resize original image to match model shape.

      image_lib.Image imageInput = img!;
      print("Pre Process  $imageInput");
      imageInput = image_lib.grayscale(imageInput);
      print("Pre Process  $imageInput");
      imageInput = image_lib.copyResize(
        imageInput,
        width: 80,
        height: 80,
      );
      print("Pre Process  $imageInput");


      // Normalize the pixel values
      imageInput = image_lib.normalize(imageInput, min: 0, max: 1);
      print("Pre Process  $imageInput");

      if (Platform.isAndroid && isolateModel.isCameraFrame()) {
        imageInput = image_lib.copyRotate(imageInput, angle: 90);
      }


      print("Decoded Image ${imageInput}");
      // Normalize imageInput by 255.0
      // const double normalizationFactor = 255.0;
      // for (var y = 0; y < imageInput.height; y++) {
      //   for (var x = 0; x < imageInput.width; x++) {
      //     final pixel = imageInput.getPixel(x, y);
      //     final r = (pixel.r / normalizationFactor).roundToDouble();
      //     final g = (pixel.g / normalizationFactor).roundToDouble();
      //     final b = (pixel.b / normalizationFactor).roundToDouble();
      //     final a = pixel.a;
      //     imageInput.setPixelRgba(x, y, r, g, b, a);
      //     imageInput.getPixel(x, y);
      //   }
      // }


      print(imageInput);

      // final imageMatrix = List.generate(
      //   imageInput.height,
      //   (y) => List.generate(
      //     imageInput.width,
      //     (x) {
      //       final pixel = imageInput.getPixel(x, y);
      //       return [pixel.r,pixel.g,pixel.b,pixel.a];
      //     },
      //   ),
      // );
      final List<List<List<num>>> imageMatrix = List.generate(
        imageInput.height,
            (y) => List.generate(
              imageInput.height,
              (x) {
            final pixel = imageInput.getPixel(x, y);
            return pixel.toList();
          },
        ),
      );

      print("Image Matrix : $imageMatrix");

      final input = [imageMatrix];
      final output = [List<double>.filled(isolateModel.outputShape[1], 0)];
      // // Run inference
      Interpreter interpreter =
          Interpreter.fromAddress(isolateModel.interpreterAddress);
      interpreter.run(input, output);
      final result = output.first;
      print("The response is : $output");
      int maxProbabilityIndex = 0;  // Initialize with the first element
      double maxProbability = result[0];  // Initialize with the first probability

      for (int i = 0; i < result.length; i++) {
        print("$i ${result[i]}");
        if (result[i] > maxProbability) {
          maxProbability = result[i];
          maxProbabilityIndex = i;
        }
      }

      print("The highest probability is $maxProbability at index $maxProbabilityIndex and font is ${isolateModel.labels[maxProbabilityIndex]}");

// Set classification map {label: points}
      int maxScore = result.reduce((a, b) => a + b).toInt();
      print(maxScore);
      // Set classification map {label: points}
      var classification = <String, double>{};
      classification = {
        isolateModel.labels[maxProbabilityIndex]: maxProbability
      };
      print("Classification are $classification");
      isolateModel.responsePort.send(classification);
    }
  }






}

class InferenceModel {
  CameraImage? cameraImage;
  image_lib.Image? image;
  int interpreterAddress;
  List<String> labels;
  List<int> inputShape;
  List<int> outputShape;
  late SendPort responsePort;

  InferenceModel(this.cameraImage, this.image, this.interpreterAddress,
      this.labels, this.inputShape, this.outputShape);

  // check if it is camera frame or still image
  bool isCameraFrame() {
    return cameraImage != null;
  }
}
