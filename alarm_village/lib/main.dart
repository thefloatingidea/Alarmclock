import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm/alarm_engine.dart';
import 'alarm/alarm_store.dart';
import 'state/village_state.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final village = VillageState(prefs);
  final alarms = AlarmStore(prefs);
  await FlameAudio.audioCache.load('alarm.wav');
  final engine = AlarmEngine(alarms, village)..start();
  runApp(VillageAlarmApp(village: village, alarms: alarms, engine: engine));
}

class VillageAlarmApp extends StatelessWidget {
  const VillageAlarmApp({super.key, required this.village, required this.alarms, required this.engine});

  final VillageState village;
  final AlarmStore alarms;
  final AlarmEngine engine;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Village Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: const Color(0xFF4E8F6A)),
      home: HomeScreen(village: village, alarms: alarms, engine: engine),
    );
  }
}
