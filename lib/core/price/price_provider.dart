import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'coingecko_service.dart';

final coinGeckoServiceProvider = Provider((ref) => CoinGeckoService());

/// Fetches USD prices for a list of token symbols.
/// Key = uppercase symbol, value = USD price.
final tokenPricesProvider =
    FutureProvider.family<Map<String, double>, List<String>>(
  (ref, symbols) {
    final service = ref.read(coinGeckoServiceProvider);
    return service.getPricesUsd(symbols);
  },
);
