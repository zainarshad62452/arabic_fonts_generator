import 'package:arabic_fonts_generator/main.dart';
import 'package:arabic_fonts_generator/ui/fontGeneratorPage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helper/fontDatabase.dart';


class ManageFontsPage extends StatefulWidget {
  @override
  _ManageFontsPageState createState() => _ManageFontsPageState();
}

class _ManageFontsPageState extends State<ManageFontsPage> {
  List<String>? fontList;

  @override
  void initState() {
    super.initState();
    _loadFontList();
  }

  Future<void> _loadFontList() async {
    final loadedFontList = await FontDatabase.getFontList();
    setState(() {
      fontList = loadedFontList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kMainColor,
        title: Text('Font List'),
      ),
      body: fontList != null && fontList!.isNotEmpty
          ? ListView.builder(
        itemCount: fontList!.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: ListTile(
                title: Text(fontList![index]),
                trailing: TextButton(onPressed: () async {
                  await FontDatabase.removeFont(fontList![index]);
                  await _loadFontList();
                  setState(() {

                  });
                }, child: Text("Delete Font")),
                // Add any additional functionality like deleting fonts here
              ),
            ),
          );
        },
      )
          : Center(
        child: Text('No fonts available'),
      ),
    );
  }
}