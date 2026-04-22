import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/tokens/data/data_sources/token_remote_data_source.dart';
import 'package:flutter_web3_wallet/features/tokens/data/token_repository_impl.dart';
import 'package:flutter_web3_wallet/features/tokens/domain/get_token_balance_usecase.dart';
import 'package:flutter_web3_wallet/features/tokens/domain/get_token_info_usecase.dart';
import 'package:flutter_web3_wallet/features/tokens/domain/token.dart';
import 'package:flutter_web3_wallet/features/tokens/domain/token_repository.dart';
import 'package:flutter_web3_wallet/features/tokens/domain/transfer_token_usecase.dart';
import 'package:flutter_web3_wallet/features/tokens/presentation/token_transfer_notifier.dart';
import 'package:flutter_web3_wallet/features/wallet/presentation/wallet_provider.dart';

final tokenRepositoryProvider = Provider<TokenRepository>((ref) {
  final web3 = ref.read(web3ServiceProvider);
  return TokenRepositoryImpl(TokenRemoteDataSource(web3));
});

final getTokenInfoUseCaseProvider = Provider((ref) {
  return GetTokenInfoUseCase(ref.read(tokenRepositoryProvider));
});

final getTokenBalanceUseCaseProvider = Provider((ref) {
  return GetTokenBalanceUseCase(ref.read(tokenRepositoryProvider));
});

final transferTokenUseCaseProvider = Provider((ref) {
  return TransferTokenUseCase(ref.read(tokenRepositoryProvider));
});

/// Params for token info query
class TokenInfoParams {
  final String contractAddress;
  final String walletAddress;

  const TokenInfoParams({
    required this.contractAddress,
    required this.walletAddress,
  });

  @override
  bool operator ==(Object other) =>
      other is TokenInfoParams &&
      other.contractAddress == contractAddress &&
      other.walletAddress == walletAddress;

  @override
  int get hashCode => Object.hash(contractAddress, walletAddress);
}

final tokenInfoProvider =
    FutureProvider.autoDispose.family<Token, TokenInfoParams>((ref, params) {
  final useCase = ref.read(getTokenInfoUseCaseProvider);
  return useCase(
    contractAddress: params.contractAddress,
    walletAddress: params.walletAddress,
  );
});

/// Watches a list of tokens for a wallet
final walletTokensProvider =
    FutureProvider.autoDispose.family<List<Token>, String>((ref, walletAddress) async {
  final useCase = ref.read(getTokenInfoUseCaseProvider);

  final contractAddresses = [
    SepoliaTokens.usdc,
    SepoliaTokens.link,
    SepoliaTokens.weth,
  ];

  final results = await Future.wait(
    contractAddresses.map(
      (addr) => useCase(
        contractAddress: addr,
        walletAddress: walletAddress,
      ).catchError((_) => Token(
            contractAddress: addr,
            symbol: '???',
            name: 'Unknown',
            decimals: 18,
            balance: 0,
          )),
    ),
  );

  return results;
});

final tokenTransferNotifierProvider =
    AsyncNotifierProvider<TokenTransferNotifier, String?>(
  () => TokenTransferNotifier(),
);
