import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/tokens/presentation/token_provider.dart';

class TokenTransferNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<void> transfer({
    required String privateKey,
    required String contractAddress,
    required String toAddress,
    required double amount,
  }) async {
    state = const AsyncLoading();
    try {
      final useCase = ref.read(transferTokenUseCaseProvider);
      final txHash = await useCase(
        privateKey: privateKey,
        contractAddress: contractAddress,
        toAddress: toAddress,
        amount: amount,
      );
      state = AsyncData(txHash);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> approve({
    required String privateKey,
    required String contractAddress,
    required String spenderAddress,
    required double amount,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(tokenRepositoryProvider);
      final txHash = await repo.approveToken(
        privateKey: privateKey,
        contractAddress: contractAddress,
        spenderAddress: spenderAddress,
        amount: amount,
      );
      state = AsyncData(txHash);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
