import 'transaction.dart';

abstract class TransactionRepository {
  Future<List<WalletTransaction>> getEthTransactions(String address, {int page, int pageSize});
  Future<List<WalletTransaction>> getTokenTransactions(String address, {int page, int pageSize});
  Future<List<WalletTransaction>> getAllTransactions(String address, {int pageSize});
}
