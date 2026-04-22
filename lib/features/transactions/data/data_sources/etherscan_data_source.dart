import 'package:dio/dio.dart';
import 'package:flutter_web3_wallet/features/transactions/domain/transaction.dart';

class EtherscanDataSource {
  static const _baseUrl = 'https://api-sepolia.etherscan.io/api';

  // Get a free key at https://etherscan.io/register
  // Without a key, requests are heavily rate-limited (1 req/5s, max 5 results)
  static const _apiKey = 'YourEtherscanApiKeyHere';

  final Dio _dio;

  EtherscanDataSource() : _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  Future<List<WalletTransaction>> getEthTransactions(
    String address, {
    int page = 1,
    int pageSize = 25,
  }) async {
    final response = await _dio.get('', queryParameters: {
      'module': 'account',
      'action': 'txlist',
      'address': address,
      'startblock': 0,
      'endblock': 99999999,
      'page': page,
      'offset': pageSize,
      'sort': 'desc',
      'apikey': _apiKey,
    });

    final result = response.data as Map<String, dynamic>;
    if (result['status'] != '1') return [];

    final list = result['result'] as List<dynamic>;
    return list.map((tx) => _parseEthTx(tx as Map<String, dynamic>)).toList();
  }

  Future<List<WalletTransaction>> getTokenTransactions(
    String address, {
    int page = 1,
    int pageSize = 25,
  }) async {
    final response = await _dio.get('', queryParameters: {
      'module': 'account',
      'action': 'tokentx',
      'address': address,
      'startblock': 0,
      'endblock': 99999999,
      'page': page,
      'offset': pageSize,
      'sort': 'desc',
      'apikey': _apiKey,
    });

    final result = response.data as Map<String, dynamic>;
    if (result['status'] != '1') return [];

    final list = result['result'] as List<dynamic>;
    return list.map((tx) => _parseTokenTx(tx as Map<String, dynamic>)).toList();
  }

  WalletTransaction _parseEthTx(Map<String, dynamic> tx) {
    final rawValue = BigInt.tryParse(tx['value'] as String? ?? '0') ?? BigInt.zero;
    final value = rawValue.toDouble() / 1e18;

    return WalletTransaction(
      hash: tx['hash'] as String,
      from: tx['from'] as String,
      to: tx['to'] as String? ?? '',
      value: value,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        int.parse(tx['timeStamp'] as String) * 1000,
      ),
      isError: tx['isError'] == '1',
      type: TxType.eth,
      gasUsed: BigInt.tryParse(tx['gasUsed'] as String? ?? '0') ?? BigInt.zero,
      gasPrice: BigInt.tryParse(tx['gasPrice'] as String? ?? '0') ?? BigInt.zero,
    );
  }

  WalletTransaction _parseTokenTx(Map<String, dynamic> tx) {
    final decimals = int.tryParse(tx['tokenDecimal'] as String? ?? '18') ?? 18;
    final rawValue = BigInt.tryParse(tx['value'] as String? ?? '0') ?? BigInt.zero;
    final value = rawValue.toDouble() / BigInt.from(10).pow(decimals).toDouble();

    return WalletTransaction(
      hash: tx['hash'] as String,
      from: tx['from'] as String,
      to: tx['to'] as String? ?? '',
      value: value,
      tokenSymbol: tx['tokenSymbol'] as String?,
      tokenName: tx['tokenName'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        int.parse(tx['timeStamp'] as String) * 1000,
      ),
      isError: false,
      type: TxType.erc20,
      gasUsed: BigInt.tryParse(tx['gasUsed'] as String? ?? '0') ?? BigInt.zero,
      gasPrice: BigInt.tryParse(tx['gasPrice'] as String? ?? '0') ?? BigInt.zero,
    );
  }
}
