class Quote {
  final String content;
  final String author;

  Quote({required this.content, required this.author});

  factory Quote.fromJson(Map<String, dynamic> j) =>
      Quote(content: j['content'] ?? '', author: j['author'] ?? 'Unknown');
}

