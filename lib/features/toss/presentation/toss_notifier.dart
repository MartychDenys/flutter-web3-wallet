import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/toss/data/toss_storage.dart';
import 'package:flutter_web3_wallet/features/toss/domain/toss_order.dart';
import 'package:flutter_web3_wallet/features/toss/domain/toss_state.dart';

class TossNotifier extends AsyncNotifier<TossState> {
  final _storage = TossStorage();
  Timer? _ticker;

  @override
  Future<TossState> build() async {
    final balance = await _storage.getBalance();
    final lastClaim = await _storage.getLastClaimTime();
    final orders = await _storage.getOrders();
    final s = TossState(
      balance: balance,
      pending: _calcPending(lastClaim),
      lastClaimTime: lastClaim,
      orders: orders,
    );
    _startTicker();
    ref.onDispose(() => _ticker?.cancel());
    return s;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _tick() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(pending: _calcPending(current.lastClaimTime)));
  }

  Future<void> claim() async {
    final current = state.valueOrNull;
    if (current == null || !current.canClaim) return;

    final newBalance = current.balance + current.pending;
    final now = DateTime.now();

    await _storage.saveBalance(newBalance);
    await _storage.saveLastClaimTime(now);

    state = AsyncData(TossState(
      balance: newBalance,
      pending: 0,
      lastClaimTime: now,
      orders: current.orders,
    ));
  }

  Future<bool> buyItem({
    required String itemName,
    required String emoji,
    required String size,
    required double price,
    required String shipName,
    required String shipCity,
    required String shipAddress,
  }) async {
    final current = state.valueOrNull;
    if (current == null || current.balance < price) return false;

    final newBalance = current.balance - price;
    final order = TossOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemName: itemName,
      emoji: emoji,
      size: size,
      price: price,
      createdAt: DateTime.now(),
      shipName: shipName,
      shipCity: shipCity,
      shipAddress: shipAddress,
    );
    final newOrders = [order, ...current.orders];

    await _storage.saveBalance(newBalance);
    await _storage.saveOrders(newOrders);

    state = AsyncData(current.copyWith(balance: newBalance, orders: newOrders));
    return true;
  }

  double _calcPending(DateTime lastClaim) {
    final elapsed = DateTime.now().difference(lastClaim);
    final ratio = elapsed.inSeconds / TossState.miningDuration.inSeconds;
    return (ratio * TossState.rewardPerCycle).clamp(0.0, TossState.rewardPerCycle);
  }
}
