import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/wallet/domain/send_tx_params.dart';
import 'package:flutter_web3_wallet/features/wallet/presentation/wallet_provider.dart';

class SendTxNotifier extends AsyncNotifier<String?> {

  @override
  Future<String?> build() async {
    return null;
  }

  Future<void> send(SendTxParams params) async {
    state = const AsyncLoading();

    try {
      final useCase = ref.read(sendTransactionUseCaseProvider);

      final txHash = await useCase(
        privateKey: params.privateKey,
        toAddress: params.toAddress,
        amount: params.amount,
      );

      state = AsyncData(txHash);
    } catch (e, st) {
      if (e.toString().contains('insufficient funds')) {
        state = AsyncError(
          'Not enough ETH for gas + value',
          st,
        );
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  Future<double> getMaxSend({
    required String address,
    required String to,
  }) async {
    final web3 = ref.read(web3ServiceProvider);

    final balance = await web3.getBalance(address);
    final feeWei = await web3.estimateGasFee(
      from: address,
      to: to,
      amountInEth: 0.01,
    );

    final feeEth = feeWei.toDouble() / 1e18;

    return balance - feeEth;
  }
}
