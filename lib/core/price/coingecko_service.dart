import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinGeckoService {
  static const _base = 'https://api.coingecko.com/api/v3';

  // symbol (uppercase) → CoinGecko id
  static const _ids = {
    'ETH': 'ethereum',
    'USDC': 'usd-coin',
    'LINK': 'chainlink',
    'WETH': 'weth',
    'DEV': 'ethereum', // fallback — DevToken is testnet-only
  };

  Future<Map<String, double>> getPricesUsd(List<String> symbols) async {
    final ids = symbols
        .map((s) => _ids[s.toUpperCase()])
        .whereType<String>()
        .toSet()
        .join(',');

    if (ids.isEmpty) return {};

    final uri = Uri.parse('$_base/simple/price?ids=$ids&vs_currencies=usd');
    final response = await http.get(uri);

    if (response.statusCode != 200) return {};

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final result = <String, double>{};
    for (final symbol in symbols) {
      final id = _ids[symbol.toUpperCase()];
      if (id == null) continue;
      final price = (json[id]?['usd'] as num?)?.toDouble();
      if (price != null) result[symbol.toUpperCase()] = price;
    }
    return result;
  }
}
