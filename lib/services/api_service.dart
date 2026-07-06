import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paper_model.dart';
import 'translation_helper.dart';

class ApiService {
  static const String _baseUrl = 'api.semanticscholar.org';
  static const String _searchPath = '/graph/v1/paper/search';

  /// Searches papers in Semantic Scholar.
  static Future<List<Paper>> searchPapers({
    required String query,
    bool filterMedicineOnly = true,
    String sortBy = 'relevance', // 'relevance' or 'year'
    int limit = 25,
  }) async {
    if (query.trim().isEmpty) return [];

    // Enhance query with translation if needed
    final translationInfo = TranslationHelper.getTranslationInfo(query);
    final finalQuery = translationInfo['enhanced'] ?? query;

    // Define parameters with full fields needed for the UI
    final Map<String, String> queryParameters = {
      'query': finalQuery,
      'fields': 'title,abstract,authors,year,journal,url,tldr,citationCount,fieldsOfStudy',
      'limit': limit.toString(),
    };

    final Uri url = Uri.https(_baseUrl, _searchPath, queryParameters);
    
    int retryCount = 0;
    const int maxRetries = 2;

    while (true) {
      try {
        final response = await http.get(
          url,
          headers: {
            "User-Agent": "AegisMedSearch/1.0 (Flutter; Research Tool)",
            "Accept": "application/json",
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> papersJson = data['data'] ?? [];
          
          List<Paper> papers = papersJson.map((json) => Paper.fromJson(json)).toList();

          // Filter to Medicine / Biology client-side if enabled
          if (filterMedicineOnly) {
            papers = papers.where((paper) {
              if (paper.fieldsOfStudy.isEmpty) return true;
              return paper.fieldsOfStudy.any((f) => 
                f == 'Medicine' || f == 'Biology' || f == 'Psychology' || f == 'Nursing');
            }).toList();
          }

          // Sort papers
          if (sortBy == 'year') {
            papers.sort((a, b) {
              if (a.year == null && b.year == null) return 0;
              if (a.year == null) return 1;
              if (b.year == null) return -1;
              return b.year!.compareTo(a.year!);
            });
          } else if (sortBy == 'citations') {
            papers.sort((a, b) => b.citationCount.compareTo(a.citationCount));
          }

          return papers;
        } else if (response.statusCode == 429) {
          // If rate limited, wait and retry
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(Duration(milliseconds: 1000 * retryCount));
            continue;
          }
          throw Exception('RateLimitError');
        } else {
          throw Exception('ServerError');
        }
      } catch (e) {
        if (e.toString().contains('RateLimitError')) {
          rethrow;
        }
        // For other network errors, retry once
        if (retryCount < 1) {
          retryCount++;
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        throw Exception('NetworkError');
      }
    }
  }
}
