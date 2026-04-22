// RPC URL (yours Alchemy)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/web3/web3_service.dart';
import 'package:flutter_web3_wallet/features/wallet/data/data_sources/wallet_remote_data_source.dart';
import 'package:flutter_web3_wallet/features/wallet/data/wallet_repository_impl.dart';
import 'package:flutter_web3_wallet/features/wallet/domain/gas_params.dart';
import 'package:flutter_web3_wallet/features/wallet/domain/get_balance_usecase.dart';
import 'package:flutter_web3_wallet/features/wallet/domain/send_transaction_usecase.dart';
import 'package:flutter_web3_wallet/features/wallet/domain/send_tx_params.dart';
import 'package:flutter_web3_wallet/features/wallet/presentation/send_tx_notifier.dart';

const rpcUrl = "https://eth-sepolia.g.alchemy.com/v2/8CrEyaP2V8-scxdrHUMWO";

// 🔹 STATE
final addressInputProvider = StateProvider<String>((ref) => '');
final submittedAddressProvider = StateProvider<String?>((ref) => null);

// 🔹 SERVICES
final web3ServiceProvider = Provider((ref) {
  return Web3Service(rpcUrl);
});

// 🔹 DATA
final walletRepositoryProvider = Provider((ref) {
  return WalletRepositoryImpl(
    WalletRemoteDataSource(ref.read(web3ServiceProvider)),
  );
});

// 🔹 DOMAIN
final getBalanceUseCaseProvider = Provider((ref) {
  return GetBalanceUseCase(ref.read(walletRepositoryProvider));
});

// 🔹 FEATURE
final balanceProvider = FutureProvider.autoDispose<double>((ref) async {
  final address = ref.watch(submittedAddressProvider);

  if (address == null || address.isEmpty) {
    throw Exception('Enter address');
  }

  final useCase = ref.read(getBalanceUseCaseProvider);
  return useCase(address);
});


final sendTransactionUseCaseProvider = Provider((ref) {
  return SendTransactionUseCase(ref.read(walletRepositoryProvider));
});

final sendTxProvider = FutureProvider.family<String, SendTxParams>((ref, params) async {
  final useCase = ref.read(sendTransactionUseCaseProvider);

  return useCase(
    privateKey: params.privateKey,
    toAddress: params.toAddress,
    amount: params.amount,
  );
});

final sendTxNotifierProvider = AsyncNotifierProvider<SendTxNotifier, String?>(
      () => SendTxNotifier(),
);

final gasFeeProvider = FutureProvider.family<double, GasParams>((ref, params) async {
  try {
    final web3 = ref.read(web3ServiceProvider);

    final feeWei = await web3.estimateGasFee(
      from: params.from,
      to: params.to,
      amountInEth: params.amount,
    );

    return feeWei.toDouble() / 1e18;
  } catch (e) {
    rethrow;
  }
});

