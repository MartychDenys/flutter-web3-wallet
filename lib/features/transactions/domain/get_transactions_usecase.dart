import 'transaction.dart';
import 'transaction_repository.dart';

class GetTransactionsUseCase {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<List<WalletTransaction>> call(String address, {int pageSize = 25}) {
    return repository.getAllTransactions(address, pageSize: pageSize);
  }
}
