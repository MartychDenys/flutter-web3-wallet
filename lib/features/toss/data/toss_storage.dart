import 'package:flutter_web3_wallet/features/toss/domain/toss_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TossStorage {
  static const _keyBalance = 'toss_balance';
  static const _keyLastClaim = 'toss_last_claim';
  static const _keyOrders = 'toss_orders';

  Future<double> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyBalance) ?? 0.0;
  }

  Future<void> saveBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBalance, balance);
  }

  Future<DateTime> getLastClaimTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyLastClaim);
    if (ms == null) return DateTime.now();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveLastClaimTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastClaim, time.millisecondsSinceEpoch);
  }

  Future<List<TossOrder>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyOrders);
    if (raw == null) return [];
    try {
      return TossOrder.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOrders(List<TossOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOrders, TossOrder.encodeList(orders));
  }
}
