import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final target = 'https://api.semanticscholar.org/graph/v1/paper/search?query=cardiology&limit=1';
  final List<Map<String, dynamic>> proxies = [
    {
      'name': 'corsproxy.org',
      'url': 'https://corsproxy.org/?${Uri.encodeComponent(target)}',
      'parse': (http.Response r) => r.body,
    },
    {
      'name': 'allorigins-get',
      'url': 'https://api.allorigins.win/get?url=${Uri.encodeComponent(target)}',
      'parse': (http.Response r) {
        final data = json.decode(r.body);
        return data['contents'] as String;
      },
    },
    {
      'name': 'thingproxy',
      'url': 'https://thingproxy.freeboard.io/fetch/$target',
      'parse': (http.Response r) => r.body,
    },
  ];

  for (final proxy in proxies) {
    print('\nTesting proxy: ${proxy['name']}');
    try {
      final response = await http.get(
        Uri.parse(proxy['url'] as String),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      print('Status: ${response.statusCode}');
      final parsedBody = (proxy['parse'] as Function)(response);
      if (parsedBody.length > 200) {
        print('Parsed Body (truncated): ${parsedBody.substring(0, 200)}...');
      } else {
        print('Parsed Body: $parsedBody');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
