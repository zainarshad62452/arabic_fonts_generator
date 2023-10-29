import 'package:arabic_fonts_generator/ui/userFontList.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../main.dart';
import 'manageFonts.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kMainColor,
        title: Text('MainScreen'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MaterialButton(onPressed: (){
            Get.to(()=>BottomNavigationBarExample());
          },child: Text("Generate Font From Image",style: TextStyle(color: Colors.white),),color: kMainColor,),
          SizedBox(height: 30.0,),
          MaterialButton(onPressed: (){
            Get.to(()=>FontListPage());
          },child: Text("Generate Text From Custom Fonts",style: TextStyle(color: Colors.white),),color: kMainColor,),
          SizedBox(height: 30.0,),
          MaterialButton(onPressed: (){
            Get.to(()=>ManageFontsPage());
          },child: Text("Manage Custom Fonts",style: TextStyle(color: Colors.white),),color: kMainColor,),
        ],
      ),
    );
  }
}
