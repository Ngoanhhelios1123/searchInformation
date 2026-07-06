import 'dart:io';

void main() {
  final file = File(r'C:\Users\DELL\.gemini\antigravity\brain\3abe1ab1-1f20-469b-92c8-c5a090470a70\.system_generated\steps\158\content.md');
  if (!file.existsSync()) {
    print('File does not exist');
    return;
  }
  
  final text = file.readAsStringSync().toLowerCase();
  
  // Search for keywords
  final keywords = ['kotlin', 'gradle', 'plugins', 'settings.gradle', 'build.gradle'];
  
  for (final kw in keywords) {
    int idx = 0;
    print('--- Keyword: $kw ---');
    while (true) {
      idx = text.indexOf(kw, idx);
      if (idx == -1) break;
      
      // Print context
      int start = (idx - 100).clamp(0, text.length);
      int end = (idx + 300).clamp(0, text.length);
      print('Context at index $idx:');
      print(text.substring(start, end));
      print('====================================\n');
      
      idx += kw.length;
      if (idx >= text.length) break;
      break; // Only print first occurrence of each keyword to avoid huge output
    }
  }
}
