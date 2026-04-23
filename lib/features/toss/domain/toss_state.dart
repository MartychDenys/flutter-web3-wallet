import 'toss_order.dart';

class TossState {
  final double balance;
  final double pending;
  final DateTime lastClaimTime;
  final List<TossOrder> orders;

  static const miningDuration = Duration(hours: 12);
  static const rewardPerCycle = 0.6;

  const TossState({
    required this.balance,
    required this.pending,
    required this.lastClaimTime,
    required this.orders,
  });

  double get progress => (pending / rewardPerCycle).clamp(0.0, 1.0);
  bool get canClaim => progress >= 0.20;
  bool get isFull => pending >= rewardPerCycle;

  Duration get timeUntilFull {
    final elapsed = DateTime.now().difference(lastClaimTime);
    final remaining = miningDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  TossState copyWith({
    double? balance,
    double? pending,
    DateTime? lastClaimTime,
    List<TossOrder>? orders,
  }) {
    return TossState(
      balance: balance ?? this.balance,
      pending: pending ?? this.pending,
      lastClaimTime: lastClaimTime ?? this.lastClaimTime,
      orders: orders ?? this.orders,
    );
  }
}
