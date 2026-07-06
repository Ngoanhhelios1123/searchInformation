import 'dart:convert';
import 'package:http/http.dart' as http;

class Paper {
  final String id;
  final String title;
  final List<String> authors;
  final int? year;
  final String? journal;
  final String? url;
  final String? abstractText;
  final String? tldr;
  final int citationCount;
  final List<String> fieldsOfStudy;

  Paper({
    required this.id,
    required this.title,
    required this.authors,
    this.year,
    this.journal,
    this.url,
    this.abstractText,
    this.tldr,
    this.citationCount = 0,
    this.fieldsOfStudy = const [],
  });
}

Future<List<Paper>> _searchEuropePMC(String query, int limit) async {
  final url = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=${Uri.encodeComponent(query)}&format=json&pageSize=$limit&resultType=core';
  print('Trying Europe PMC API: $url');
  
  final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw Exception('EuropePMCError');
  }

  final Map<String, dynamic> data = json.decode(response.body);
  final List<dynamic> resultsJson = data['resultList']?['result'] ?? [];
  
  return resultsJson.map((item) {
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

    // Parse TLDR
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
      fieldsOfStudy: ['Medicine'], // Force medicine so it passes filter
    );
  }).toList();
}

void main() async {
  try {
    final papers = await _searchEuropePMC('cancer oncology', 2);
    print('Successfully parsed ${papers.length} papers!');
    for (var i = 0; i < papers.length; i++) {
      final p = papers[i];
      print('\nPaper ${i + 1}:');
      print('ID: ${p.id}');
      print('Title: ${p.title}');
      print('Authors: ${p.authors}');
      print('Year: ${p.year}');
      print('Journal: ${p.journal}');
      print('URL: ${p.url}');
      print('TLDR: ${p.tldr}');
      print('Citations: ${p.citationCount}');
      print('Fields: ${p.fieldsOfStudy}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
