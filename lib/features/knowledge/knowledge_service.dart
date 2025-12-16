import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'knowledge_model.dart';

class KnowledgeService extends ChangeNotifier {
  static final KnowledgeService _instance = KnowledgeService._internal();
  factory KnowledgeService() => _instance;
  KnowledgeService._internal();

  List<KnowledgeItem> _items = [];
  bool _isLoading = false;

  List<KnowledgeItem> get items => _items;
  bool get isLoading => _isLoading;

  int _readingStreak = 0;
  DateTime? _lastCheckInDate;

  int get readingStreak => _readingStreak;
  bool get isCheckedInToday {
    if (_lastCheckInDate == null) return false;
    final now = DateTime.now();
    return _lastCheckInDate!.year == now.year &&
        _lastCheckInDate!.month == now.month &&
        _lastCheckInDate!.day == now.day;
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? itemsJson = prefs.getStringList('knowledge_items');

      if (itemsJson != null) {
        _items = itemsJson
            .map((item) => KnowledgeItem.fromJson(jsonDecode(item)))
            .toList();
        // Sort by newest first
        _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      _readingStreak = prefs.getInt('reading_streak') ?? 0;
      final lastCheckInString = prefs.getString('last_check_in_date');
      if (lastCheckInString != null) {
        _lastCheckInDate = DateTime.parse(lastCheckInString);
      } else {
        _lastCheckInDate = null;
      }

      // Reset streak if missed a day (more than 1 day gap)
      if (_lastCheckInDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final last = DateTime(
          _lastCheckInDate!.year,
          _lastCheckInDate!.month,
          _lastCheckInDate!.day,
        );

        final difference = today.difference(last).inDays;
        if (difference > 1) {
          _readingStreak = 0;
          await prefs.setInt('reading_streak', 0);
        }
      }
    } catch (e) {
      debugPrint('Error loading knowledge items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem({
    required String title,
    required String description,
    String? url,
  }) async {
    try {
      final newItem = KnowledgeItem(
        id: const Uuid().v4(),
        title: title,
        description: description,
        url: url,
        createdAt: DateTime.now(),
      );

      _items.insert(0, newItem);
      await _saveItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding knowledge item: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      _items.removeWhere((item) => item.id == id);
      await _saveItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting knowledge item: $e');
      rethrow;
    }
  }

  Future<void> checkInReading() async {
    if (isCheckedInToday) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if yesterday was checked in to increment streak, else reset to 1
    if (_lastCheckInDate != null) {
      final last = DateTime(
        _lastCheckInDate!.year,
        _lastCheckInDate!.month,
        _lastCheckInDate!.day,
      );
      final difference = today.difference(last).inDays;

      if (difference == 1) {
        _readingStreak++;
      } else {
        _readingStreak = 1;
      }
    } else {
      _readingStreak = 1;
    }

    _lastCheckInDate = now;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reading_streak', _readingStreak);
    await prefs.setString('last_check_in_date', now.toIso8601String());

    notifyListeners();
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> itemsJson =
        _items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('knowledge_items', itemsJson);
  }
}
