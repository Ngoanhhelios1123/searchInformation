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

  factory Paper.fromJson(Map<String, dynamic> json) {
    // Parse authors list
    List<String> parsedAuthors = [];
    if (json['authors'] != null) {
      for (var author in json['authors']) {
        if (author is Map && author.containsKey('name')) {
          parsedAuthors.add(author['name'] as String);
        }
      }
    }

    // Parse fields of study
    List<String> parsedFields = [];
    if (json['fieldsOfStudy'] != null) {
      for (var field in json['fieldsOfStudy']) {
        if (field is String) {
          parsedFields.add(field);
        }
      }
    }

    // Parse journal details
    String? journalName;
    if (json['journal'] != null && json['journal'] is Map) {
      journalName = json['journal']['name'] as String?;
    } else if (json['journal'] != null && json['journal'] is String) {
      journalName = json['journal'] as String;
    }

    // Parse TLDR
    String? tldrText;
    if (json['tldr'] != null && json['tldr'] is Map) {
      tldrText = json['tldr']['text'] as String?;
    }

    return Paper(
      id: json['paperId'] ?? '',
      title: json['title'] ?? 'No Title',
      authors: parsedAuthors,
      year: json['year'] as int?,
      journal: journalName,
      url: json['url'] as String?,
      abstractText: json['abstract'] as String?,
      tldr: tldrText,
      citationCount: json['citationCount'] as int? ?? 0,
      fieldsOfStudy: parsedFields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paperId': id,
      'title': title,
      'authors': authors.map((name) => {'name': name}).toList(),
      'year': year,
      'journal': journal != null ? {'name': journal} : null,
      'url': url,
      'abstract': abstractText,
      'tldr': tldr != null ? {'text': tldr} : null,
      'citationCount': citationCount,
      'fieldsOfStudy': fieldsOfStudy,
    };
  }
}
