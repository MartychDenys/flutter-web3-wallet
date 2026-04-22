import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/walletconnect/wallet_connect_service.dart';
import 'package:flutter_web3_wallet/features/walletconnect/presentation/wc_notifier.dart';

final walletConnectServiceProvider = Provider<WalletConnectService>((ref) {
  return WalletConnectService();
});

final wcNotifierProvider = StateNotifierProvider<WcNotifier, WcState>((ref) {
  return WcNotifier(ref.read(walletConnectServiceProvider));
});
