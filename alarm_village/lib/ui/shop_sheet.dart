import 'package:flutter/material.dart';

import '../state/village_state.dart';

/// A purchasable bundle. Prices are deliberately small.
class Pack {
  const Pack(this.id, this.title, this.price, {this.shields = 0, this.buckets = 0, this.badge, required this.icon});
  final String id, title, price;
  final int shields, buckets;
  final String? badge;
  final IconData icon;
}

const packs = <Pack>[
  Pack('buckets_30', 'Bucket Splash', '\$0.49', buckets: 30, icon: Icons.water_drop),
  Pack('starter', 'Starter Bundle', '\$0.99', shields: 2, buckets: 50, badge: 'BEST START', icon: Icons.card_giftcard),
  Pack('shield_3', 'Shield Trio', '\$0.99', shields: 3, icon: Icons.shield),
  Pack('guardian', 'Guardian Pack', '\$1.99', shields: 5, buckets: 150, badge: 'POPULAR', icon: Icons.security),
  Pack('kingdom', 'Kingdom Chest', '\$4.99', shields: 15, buckets: 450, badge: 'BEST VALUE', icon: Icons.castle),
];

Future<void> showShop(BuildContext context, VillageState village) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF151B2E),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      maxChildSize: .95,
      builder: (context, scroll) => _Shop(village: village, scroll: scroll),
    ),
  );
}

class _Shop extends StatelessWidget {
  const _Shop({required this.village, required this.scroll});
  final VillageState village;
  final ScrollController scroll;

  Future<void> _buy(BuildContext context, Pack p) async {
    // TODO(phase 2): replace with Google Play Billing / App Store via the
    // in_app_purchase plugin. For now purchases are simulated.
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Buy ${p.title}?'),
        content: Text('${_contents(p)} for ${p.price}.\n\nDemo build: no real payment is taken.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('Pay ${p.price}')),
        ],
      ),
    );
    if (ok == true) village.addCurrency(shields: p.shields, buckets: p.buckets, note: 'Thanks! ${_contents(p)} added.');
  }

  static String _contents(Pack p) =>
      [if (p.shields > 0) '${p.shields} shield${p.shields > 1 ? 's' : ''}', if (p.buckets > 0) '${p.buckets} water buckets'].join(' + ');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: village,
      builder: (context, _) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 14),
          const Text('Village Shop', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Wallet(icon: Icons.shield, color: const Color(0xFF6FD3FF), label: 'Shields', value: '${village.shields}')),
            const SizedBox(width: 10),
            Expanded(child: _Wallet(icon: Icons.water_drop, color: const Color(0xFF4FA3FF), label: 'Water buckets', value: '${village.buckets}')),
          ]),
          const SizedBox(height: 12),
          _ShieldCard(village: village),
          const SizedBox(height: 18),
          const Text('Bundles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final p in packs) _PackTile(pack: p, onBuy: () => _buy(context, p)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(14)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Earn for free', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('• +${VillageState.bucketsPerWake} water buckets for every on-time wake-up'),
              Text('• +1 shield for every ${VillageState.shieldEveryDays}-day streak'),
              SizedBox(height: 8),
              Text('How they work', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('• A shield covers the island with a dome that absorbs ${VillageState.missesPerShield} missed alarms. Your streak is kept.'),
              Text('• If the city burns down, ${VillageState.restoreCost} water buckets make it rain and bring the whole city back.'),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Wallet extends StatelessWidget {
  const _Wallet({required this.icon, required this.color, required this.label, required this.value});
  final IconData icon;
  final Color color;
  final String label, value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withAlpha(60), color.withAlpha(20)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(90)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        ]),
      );
}

class _ShieldCard extends StatelessWidget {
  const _ShieldCard({required this.village});
  final VillageState village;

  @override
  Widget build(BuildContext context) {
    final active = village.shieldActive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? const Color(0x336FD3FF) : const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? const Color(0xFF6FD3FF) : Colors.white12),
      ),
      child: Row(children: [
        Icon(active ? Icons.shield : Icons.shield_outlined, color: const Color(0xFF6FD3FF), size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(active ? 'Shield active' : 'No shield active', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              active
                  ? 'Protects ${village.shieldCharges} more missed alarm${village.shieldCharges == 1 ? '' : 's'}.'
                  : 'Activate one to protect your next ${VillageState.missesPerShield} missed alarms.',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ]),
        ),
        FilledButton(
          onPressed: village.shields > 0 ? village.activateShield : null,
          child: Text(active ? 'Add +${VillageState.missesPerShield}' : 'Activate'),
        ),
      ]),
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({required this.pack, required this.onBuy});
  final Pack pack;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF243052), Color(0xFF1B2440)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pack.badge != null ? const Color(0xFFFFC46B) : Colors.white12),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: const Color(0x22FFC46B), borderRadius: BorderRadius.circular(12)),
          child: Icon(pack.icon, color: const Color(0xFFFFC46B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(pack.title, style: const TextStyle(fontWeight: FontWeight.w700))),
              if (pack.badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFFC46B), borderRadius: BorderRadius.circular(6)),
                  child: Text(pack.badge!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Wrap(spacing: 10, children: [
              if (pack.shields > 0) _chip(Icons.shield, '${pack.shields}', const Color(0xFF6FD3FF)),
              if (pack.buckets > 0) _chip(Icons.water_drop, '${pack.buckets}', const Color(0xFF4FA3FF)),
            ]),
          ]),
        ),
        FilledButton(onPressed: onBuy, child: Text(pack.price)),
      ]),
    );
  }

  Widget _chip(IconData i, String v, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(i, size: 15, color: c),
        const SizedBox(width: 3),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]);
}
