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

      image_lib.Image imageInput = image_lib.copyResize(
        img!,
        width: isolateModel.inputShape[1],
        height: isolateModel.inputShape[2],
      );
      print("Pre Process  ${imageInput.data?.toUint8List()})");

      print(imageInput);
      final imageMatrix = List.generate(
        imageInput.height,
            (y) => List.generate(
          imageInput.width,
              (x) {
            final pixel = imageInput.getPixel(x, y);
            return [pixel.r/255.0];
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
