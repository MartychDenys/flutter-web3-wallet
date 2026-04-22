import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/my_contracts/presentation/my_contracts_notifier.dart';

final myContractsNotifierProvider =
    StateNotifierProvider<MyContractsNotifier, MyContractsState>((ref) {
  return MyContractsNotifier(ref);
});
