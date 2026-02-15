import '../models/quote.dart';
import '../services/api_client.dart';

class QuoteRepository {
  final ApiClient api;
  QuoteRepository(this.api);

  Future<Quote> randomQuote() async {
    final uri = Uri.parse("https://dummyjson.com/quotes/random");

    final jsonData = await api.getJson(uri);

    return Quote(
      content: jsonData['quote'],
      author: jsonData['author'],
    );
  }
}
