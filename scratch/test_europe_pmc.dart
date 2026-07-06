import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=cardiology&format=json&pageSize=1&resultType=core';
  print('Fetching from Europe PMC: $url');
  try {
    final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
    final Map<String, dynamic> data = json.decode(response.body);
    final results = data['resultList']['result'] as List;
    if (results.isNotEmpty) {
      final first = results.first;
      print('journalInfo: ${first['journalInfo']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
