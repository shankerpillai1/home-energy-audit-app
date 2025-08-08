import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leakage_task.dart';

class LocalStorageService {
  static const _tasksKey = 'leakage_tasks';

  /// Save a boolean under [key]
  Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Read a boolean for [key], defaulting to false
  Future<bool> readBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  /// Load all stored LeakageTasks (or empty list)
  Future<List<LeakageTask>> getLeakageTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_tasksKey);
    if (jsonString == null) return [];
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded
        .map((e) => LeakageTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Persist the full list of LeakageTasks
  Future<void> saveLeakageTasks(List<LeakageTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        json.encode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_tasksKey, jsonString);
  }
}
