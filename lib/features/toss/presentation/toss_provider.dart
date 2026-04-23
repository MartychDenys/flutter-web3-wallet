import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/toss/domain/toss_state.dart';
import 'toss_notifier.dart';

final tossNotifierProvider = AsyncNotifierProvider<TossNotifier, TossState>(
  TossNotifier.new,
);
