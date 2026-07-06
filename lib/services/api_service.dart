import 'dart:convert';
import 'package:flutter/foundation.dart';
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

    final Uri baseApiUrl = Uri.https(_baseUrl, _searchPath, queryParameters);
    
    final List<Uri> urlsToTry = [];
    if (kIsWeb) {
      // Try direct connection first, as Semantic Scholar supports CORS natively for successful requests.
      // This uses the client's own IP, avoiding shared proxy rate limits.
      urlsToTry.add(baseApiUrl);

      final String rawUrlStr = baseApiUrl.toString();
      final List<String> proxyTemplates = [
        'https://corsproxy.io/?',
        'https://api.allorigins.win/raw?url=',
        'https://api.cors.lol/?url=',
        'https://api.codetabs.com/v1/proxy?quest=',
      ];
      // Shuffle proxies to distribute load as fallbacks
      final List<String> shuffledTemplates = List.from(proxyTemplates)..shuffle();
      for (final prefix in shuffledTemplates) {
        urlsToTry.add(Uri.parse('$prefix${Uri.encodeComponent(rawUrlStr)}'));
      }
    } else {
      // On mobile/desktop, add the direct URL 3 times to simulate 3 retries
      urlsToTry.add(baseApiUrl);
      urlsToTry.add(baseApiUrl);
      urlsToTry.add(baseApiUrl);
    }
    
    String lastErrorType = 'NetworkError';

    for (int i = 0; i < urlsToTry.length; i++) {
      final currentUrl = urlsToTry[i];
      try {
        final response = await http.get(
          currentUrl,
          headers: kIsWeb
              ? {
                  "Accept": "application/json",
                }
              : {
                  "User-Agent": "AegisMedSearch/1.0 (Flutter; Research Tool)",
                  "Accept": "application/json",
                },
        ).timeout(const Duration(seconds: 10));

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
          lastErrorType = 'RateLimitError';
          // Wait a bit before trying the next proxy/retry
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
          continue;
        } else {
          lastErrorType = 'ServerError';
          await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
          continue;
        }
      } catch (e) {
        if (e is FormatException) {
          lastErrorType = 'ServerError';
        } else {
          lastErrorType = 'NetworkError';
        }
        await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
        continue;
      }
    }

    throw Exception(lastErrorType);
  }
}
