import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/theme/app_theme.dart';
import 'toss_buy_sheet.dart';
import 'toss_orders_screen.dart';
import 'toss_provider.dart';

class TossAccessoriesScreen extends ConsumerStatefulWidget {
  const TossAccessoriesScreen({super.key});

  @override
  ConsumerState<TossAccessoriesScreen> createState() => _TossAccessoriesScreenState();
}

class _TossAccessoriesScreenState extends ConsumerState<TossAccessoriesScreen> {
  int _currentCap = 0;
  String _selectedSize = 'M';
  static const _price = 30.0;
  static const _sizes = ['S', 'M', 'L', 'XL'];

  static const _caps = [
    _CapItem(asset: 'assets/images/cap1.jpg', name: 'Black Cap'),
    _CapItem(asset: 'assets/images/cap2.jpg', name: 'Olive Cap'),
    _CapItem(asset: 'assets/images/cap3.jpg', name: 'Navy Cap'),
    _CapItem(asset: 'assets/images/cap4.jpg', name: 'Grey Cap'),
  ];

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(tossNotifierProvider).valueOrNull?.balance ?? 0.0;
    final canBuy = balance >= _price;
    final currentCap = _caps[_currentCap];

    return Scaffold(
      appBar: AppBar(title: const Text('Accessories'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cap gallery ───────────────────────────────────────────────
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _caps.length,
                onPageChanged: (i) => setState(() => _currentCap = i),
                itemBuilder: (context, i) {
                  final cap = _caps[i];
                  final isActive = i == _currentCap;
                  return AnimatedScale(
                    scale: isActive ? 1.0 : 0.93,
                    duration: const Duration(milliseconds: 250),
                    child: _CapCard(cap: cap),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // ── Dots ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_caps.length, (i) {
                final active = i == _currentCap;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    currentCap.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Кепка з вишитим логотипом BattleToads. Регульований ремінець, унісекс.',
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
          ],
        ),
      ),
    );
  }

  Future<void> _buy() async {
    final ok = await showBuySheet(
      context,
      itemName: _caps[_currentCap].name,
      emoji: '🧢',
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

class _CapItem {
  final String asset;
  final String name;
  const _CapItem({required this.asset, required this.name});
}

class _CapCard extends StatelessWidget {
  final _CapItem cap;
  const _CapCard({required this.cap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: const Color(0xFFF5F5F5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(cap.asset, fit: BoxFit.contain),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'assets/images/battletoads_label.png',
                    width: 70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
