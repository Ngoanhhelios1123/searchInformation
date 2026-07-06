import 'package:http/http.dart' as http;

void main() async {
  final target = 'https://api.semanticscholar.org/graph/v1/paper/search?query=cardiology&limit=1';
  print('Testing direct: $target');
  try {
    final response = await http.get(
      Uri.parse(target),
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 10));
    print('Status: ${response.statusCode}');
    print('Headers:');
    response.headers.forEach((k, v) {
      print('  $k: $v');
    });
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}

