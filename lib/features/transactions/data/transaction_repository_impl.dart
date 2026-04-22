import 'package:flutter_web3_wallet/features/transactions/data/data_sources/etherscan_data_source.dart';
import 'package:flutter_web3_wallet/features/transactions/domain/transaction.dart';
import 'package:flutter_web3_wallet/features/transactions/domain/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final EtherscanDataSource dataSource;

  TransactionRepositoryImpl(this.dataSource);

  @override
  Future<List<WalletTransaction>> getEthTransactions(
    String address, {
    int page = 1,
    int pageSize = 25,
  }) {
    return dataSource.getEthTransactions(address, page: page, pageSize: pageSize);
  }

  @override
  Future<List<WalletTransaction>> getTokenTransactions(
    String address, {
    int page = 1,
    int pageSize = 25,
  }) {
    return dataSource.getTokenTransactions(address, page: page, pageSize: pageSize);
  }

  @override
  Future<List<WalletTransaction>> getAllTransactions(
    String address, {
    int pageSize = 25,
  }) async {
    final results = await Future.wait([
      getEthTransactions(address, pageSize: pageSize),
      getTokenTransactions(address, pageSize: pageSize),
    ]);

    final all = [...results[0], ...results[1]];
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(pageSize).toList();
  }
}
