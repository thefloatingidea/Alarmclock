import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../alarm/alarm_engine.dart';
import '../alarm/alarm_store.dart';
import '../game/village_game.dart';
import '../state/village_state.dart';
import 'alarm_panel.dart';
import 'glass.dart';
import 'ringing_overlay.dart';
import 'shop_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.village, required this.alarms, required this.engine});

  final VillageState village;
  final AlarmStore alarms;
  final AlarmEngine engine;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final VillageGame _game = VillageGame(village: widget.village, engine: widget.engine);

  @override
  void initState() {
    super.initState();
    widget.village.addListener(_onVillageChanged);
  }

  @override
  void dispose() {
    widget.village.removeListener(_onVillageChanged);
    super.dispose();
  }

  void _onVillageChanged() {
    final msg = widget.village.takeMessage();
    if (msg == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final village = widget.village;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        GameWidget(game: _game),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Align(alignment: Alignment.topCenter, child: _StatusBar(village: village))),
              const SizedBox(width: 8),
              Glass(
                padding: EdgeInsets.zero,
                radius: 30,
                child: IconButton(
                  tooltip: 'Re-centre view (pinch to zoom, drag to move)',
                  icon: const Icon(Icons.center_focus_strong, color: Colors.white),
                  onPressed: _game.resetView,
                ),
              ),
            ]),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AlarmPanel(store: widget.alarms, engine: engine, village: village),
              ),
            ),
          ),
        ),
        ListenableBuilder(
          listenable: Listenable.merge([engine, village]),
          builder: (context, _) {
            if (engine.isRinging) return RingingOverlay(engine: engine, village: village);
            if (village.destroyed) return _DestroyedOverlay(village: village);
            if (village.damagePct > 0) return _DamagedOverlay(village: village);
            return const SizedBox.shrink();
          },
        ),
      ]),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.village});
  final VillageState village;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: village,
      builder: (context, _) {
        const style = TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13);
        return Glass(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          radius: 30,
          child: InkWell(
            onTap: () => showShop(context, village),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.local_fire_department, size: 16, color: Color(0xFFFFC46B)),
              Text(' ${village.streak}', style: style),
              const SizedBox(width: 10),
              const Icon(Icons.landscape_rounded, size: 16, color: Colors.white),
              Text(' Day ${village.level}', style: style),
              const SizedBox(width: 10),
              Icon(village.shieldActive ? Icons.shield : Icons.shield_outlined, size: 16, color: const Color(0xFF6FD3FF)),
              Text(' ${village.shields}${village.shieldActive ? ' (${village.shieldCharges} on)' : ''}', style: style),
              const SizedBox(width: 10),
              const Icon(Icons.water_drop, size: 16, color: Color(0xFF4FA3FF)),
              Text(' ${village.buckets}', style: style),
              const SizedBox(width: 4),
              const Icon(Icons.add_circle, size: 16, color: Color(0xFFFFC46B)),
            ]),
          ),
        );
      },
    );
  }
}

class _DamagedOverlay extends StatelessWidget {
  const _DamagedOverlay({required this.village});
  final VillageState village;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -.55),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Glass(
          tint: const Color(0x66301818),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_fire_department, size: 40, color: Color(0xFFFF8A5A)),
            const SizedBox(height: 6),
            Text('${village.damagePct}% of your city burned',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('You stopped it before 50%. The villagers will rebuild for free!',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: village.restoreFree,
              icon: const Icon(Icons.water_drop),
              label: const Text('Restore for free'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DestroyedOverlay extends StatelessWidget {
  const _DestroyedOverlay({required this.village});
  final VillageState village;

  @override
  Widget build(BuildContext context) {
    final can = village.canRestore;
    return Container(
      color: const Color(0x88000000),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Glass(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.whatshot, size: 52, color: Color(0xFFFF7A45)),
          const SizedBox(height: 8),
          const Text('The dragon burned your city',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Make it rain with ${VillageState.restoreCost} water buckets to bring back your day-${village.level} city, '
              'or start again from day 0.',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 14),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.water_drop, color: Color(0xFF4FA3FF)),
            Text(' You have ${village.buckets}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2F7DC4)),
              onPressed: can ? village.restoreWithWater : () => showShop(context, village),
              icon: Icon(can ? Icons.water_drop : Icons.storefront),
              label: Text(can ? 'Rain ${VillageState.restoreCost} buckets & restore' : 'Get water buckets'),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(onPressed: village.startOver, child: const Text('Start over from day 0', style: TextStyle(color: Colors.white70))),
        ]),
      ),
    );
  }
}
