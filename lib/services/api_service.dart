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

    // If Semantic Scholar fails, attempt fallback to Europe PMC API.
    // Europe PMC is a reliable, open life sciences database that supports CORS natively.
    try {
      return await _searchEuropePMC(
        query: query,
        limit: limit,
        filterMedicineOnly: filterMedicineOnly,
        sortBy: sortBy,
      );
    } catch (e) {
      // If the fallback also fails, throw the original exception.
      throw Exception(lastErrorType);
    }
  }

  /// Fallback search in Europe PMC when Semantic Scholar fails.
  static Future<List<Paper>> _searchEuropePMC({
    required String query,
    required int limit,
    bool filterMedicineOnly = true,
    String sortBy = 'relevance',
  }) async {
    final translationInfo = TranslationHelper.getTranslationInfo(query);
    final finalQuery = translationInfo['enhanced'] ?? query;

    final String url = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search'
        '?query=${Uri.encodeComponent(finalQuery)}'
        '&format=json'
        '&pageSize=$limit'
        '&resultType=core';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('ServerError');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> resultsJson = data['resultList']?['result'] ?? [];

    List<Paper> papers = resultsJson.map((item) {
      // Parse authors
      List<String> authors = [];
      if (item['authorString'] != null) {
        authors = (item['authorString'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      // Parse journal
      String? journalName;
      if (item['journalInfo'] != null && item['journalInfo']['journal'] != null) {
        journalName = item['journalInfo']['journal']['title'] as String?;
      }
      journalName ??= item['journalTitle'] as String?;

      // Parse URL
      String? paperUrl = item['url'] as String?;
      if (paperUrl == null || paperUrl.isEmpty) {
        if (item['doi'] != null && (item['doi'] as String).isNotEmpty) {
          paperUrl = 'https://doi.org/${item['doi']}';
        } else {
          paperUrl = 'https://europepmc.org/article/${item['source'] ?? 'MED'}/${item['id']}';
        }
      }

      // Parse TLDR (using the first sentence of the abstract)
      String? tldrText;
      if (item['abstractText'] != null && (item['abstractText'] as String).isNotEmpty) {
        final abs = item['abstractText'] as String;
        final cleanAbs = abs.replaceAll(RegExp(r'<[^>]*>'), '');
        final sentences = cleanAbs.split(RegExp(r'\. (?=[A-Z])'));
        if (sentences.isNotEmpty) {
          tldrText = sentences.first.trim();
          if (!tldrText.endsWith('.')) tldrText += '.';
        }
      }

      return Paper(
        id: item['id']?.toString() ?? '',
        title: item['title'] ?? 'No Title',
        authors: authors,
        year: int.tryParse(item['pubYear']?.toString() ?? ''),
        journal: journalName,
        url: paperUrl,
        abstractText: item['abstractText'] as String?,
        tldr: tldrText,
        citationCount: item['citedByCount'] as int? ?? 0,
        fieldsOfStudy: const ['Medicine'], // Hardcode medicine to pass filter
      );
    }).toList();

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
  }
}
