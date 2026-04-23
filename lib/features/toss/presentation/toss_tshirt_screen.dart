import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/theme/app_theme.dart';
import 'toss_buy_sheet.dart';
import 'toss_orders_screen.dart';
import 'toss_provider.dart';

class TossTshirtScreen extends ConsumerStatefulWidget {
  const TossTshirtScreen({super.key});

  @override
  ConsumerState<TossTshirtScreen> createState() => _TossTshirtScreenState();
}

class _TossTshirtScreenState extends ConsumerState<TossTshirtScreen> {
  String _selectedSize = 'M';
  static const _price = 50.0;
  static const _sizes = ['S', 'M', 'L', 'XL', 'XXL'];

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(tossNotifierProvider).valueOrNull?.balance ?? 0.0;
    final canBuy = balance >= _price;

    return Scaffold(
      appBar: AppBar(title: const Text('T-Shirt'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Shirt mockup ──────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 300,
                color: const Color(0xFFF0F0F0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/tshirt_black.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 37,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Image.asset(
                          'assets/images/battletoads_label.png',
                          width: 130,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'BattleToads Black Tee',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Чорна футболка преміум якості з оригінальним принтом BattleToads. 100% cotton.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),

            const SizedBox(height: 24),
            const Text(
              'РОЗМІР',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _sizes.map((s) {
                final selected = s == _selectedSize;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSize = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary.withAlpha(20) : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.cardBorder,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          s,
                          style: TextStyle(
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ціна',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Text('🐸', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '${_price.toInt()} TOADS',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Твій баланс',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '${balance.toStringAsFixed(2)} TOADS',
                        style: TextStyle(
                          color: canBuy ? AppColors.textPrimary : AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: canBuy ? _buy : null,
                child: Text(
                  canBuy
                      ? 'Купити за ${_price.toInt()} TOADS'
                      : 'Не вистачає ${(_price - balance).toStringAsFixed(2)} TOADS',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy() async {
    final ok = await showBuySheet(
      context,
      itemName: 'BattleToads Black Tee',
      emoji: '👕',
      size: _selectedSize,
      price: _price,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🐸 Замовлення оформлено!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Мої замовлення',
            textColor: Colors.black,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TossOrdersScreen()),
            ),
          ),
        ),
      );
    }
  }
}
