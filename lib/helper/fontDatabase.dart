import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontDatabase {
  static const String _key = 'font_list';

  // Save a list of strings to SharedPreferences
  static Future<void> saveFontList(List<String> fontList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, fontList);
  }

  // Get the list of strings from SharedPreferences
  static Future<List<String>?> getFontList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key);
  }
  static Future<void> addFontIfNotExists(String font,context) async {
    final List<String> currentList = (await getFontList()) ?? [];

    if (currentList.contains(font)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Font "$font" is already available.')),
      );
    } else {
      currentList.add(font);
      await saveFontList(currentList);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Font "$font" added to the list.')),
      );
    }
  }

  // Add a new string to the list and save it to SharedPreferences
  static Future<void> addFont(String font) async {
    final List<String> currentList = (await getFontList()) ?? [];
    currentList.add(font);
    await saveFontList(currentList);
  }

  // Remove a string from the list and save it to SharedPreferences
  static Future<void> removeFont(String font) async {
    List<String> currentList = (await getFontList()) ?? [];
    currentList.remove(font);
    await saveFontList(currentList);
  }
}
