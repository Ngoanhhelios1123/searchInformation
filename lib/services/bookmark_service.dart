import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/paper_model.dart';

class BookmarkService {
  static const String _storageKey = 'bookmarked_papers';

  /// Fetch all bookmarked papers from local storage
  static Future<List<Paper>> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? serializedList = prefs.getStringList(_storageKey);
      
      if (serializedList == null) return [];
      
      return serializedList.map((item) {
        final Map<String, dynamic> jsonMap = json.decode(item);
        return Paper.fromJson(jsonMap);
      }).toList();
    } catch (e) {
      // Return empty list if there's any error parsing or loading
      return [];
    }
  }

  /// Check if a specific paper is already bookmarked
  static Future<bool> isBookmarked(String paperId) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((p) => p.id == paperId);
  }

  /// Add a paper to bookmarks
  static Future<bool> saveBookmark(Paper paper) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = await getBookmarks();
      
      // If already bookmarked, do nothing
      if (bookmarks.any((p) => p.id == paper.id)) {
        return true;
      }
      
      bookmarks.add(paper);
      
      final List<String> serializedList = bookmarks.map((p) => json.encode(p.toJson())).toList();
      return await prefs.setStringList(_storageKey, serializedList);
    } catch (e) {
      return false;
    }
  }

  /// Remove a paper from bookmarks
  static Future<bool> removeBookmark(String paperId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var bookmarks = await getBookmarks();
      
      bookmarks.removeWhere((p) => p.id == paperId);
      
      final List<String> serializedList = bookmarks.map((p) => json.encode(p.toJson())).toList();
      return await prefs.setStringList(_storageKey, serializedList);
    } catch (e) {
      return false;
    }
  }
}
