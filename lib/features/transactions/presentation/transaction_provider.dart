import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/transactions/data/data_sources/etherscan_data_source.dart';
import 'package:flutter_web3_wallet/features/transactions/data/transaction_repository_impl.dart';
import 'package:flutter_web3_wallet/features/transactions/domain/get_transactions_usecase.dart';
import 'package:flutter_web3_wallet/features/transactions/domain/transaction.dart';
import 'package:flutter_web3_wallet/features/transactions/domain/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(EtherscanDataSource());
});

final getTransactionsUseCaseProvider = Provider((ref) {
  return GetTransactionsUseCase(ref.read(transactionRepositoryProvider));
});

final transactionsProvider =
    FutureProvider.autoDispose.family<List<WalletTransaction>, String>((ref, address) {
  if (address.isEmpty) return Future.value([]);
  final useCase = ref.read(getTransactionsUseCaseProvider);
  return useCase(address);
});
