import 'dart:io';
import 'dart:ui';

import 'package:arabic_fonts_generator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class FontGeneratorPage extends StatefulWidget {

  TextStyle style;
  FontGeneratorPage({required this.style});
  @override
  _FontGeneratorPageState createState() => _FontGeneratorPageState();
}

class _FontGeneratorPageState extends State<FontGeneratorPage> {
  final TextEditingController _textController = TextEditingController();
  String _generatedText = '';
  void _generateFont() {
    setState(() {
      _generatedText = _textController.text;
    });
  }
  final _screenshotController = ScreenshotController();

  Future<void> _captureAndSaveImage() async {
    _screenshotController
        .captureFromWidget(Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Text(
        _generatedText,
        style: widget.style.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    ))
        .then((capturedImage) async {
      if (capturedImage != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/image.png').create();
        await imagePath.writeAsBytes(capturedImage);

        await Share.shareFiles([imagePath.path]);
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Font Generator Page"),
        backgroundColor: kMainColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _textController,
                decoration: InputDecoration(labelText: 'Enter Text'),
              ),
              SizedBox(height: 16.0),
              MaterialButton(
                color: kMainColor,
                onPressed: _generateFont,
                child: Text('Generate Font',style: TextStyle(color: Colors.white),),
              ),
              SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  _generatedText,
                  style: widget.style,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16.0),
                ElevatedButton(
                onPressed: _generatedText.isEmpty ? null : () async {
                 await Share.share(_generatedText);
                },
                child: Text('Copy to Clipboard'),
              ),
              SizedBox(height: 16.0),
                ElevatedButton(
                onPressed: _generatedText.isEmpty ? null : () async {
                  await _captureAndSaveImage();
                },
                child: Text('Share'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}