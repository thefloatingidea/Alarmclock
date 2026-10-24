import 'dart:math' as math;
import 'dart:ui' show Rect;

/// Everything that can exist on the island and the streak day it unlocks on.
/// Grid is 16 x 16 tiles; the clock tower sits in the middle (tiles 6.5 - 9.5).
const int gridN = 16;
const double center = 8;
const int maxLevel = 60;

/// Island half-size (in tiles): 6x6 on day 0, full 16x16 from day 15.
int islandHalf(int level) => math.min(8, 3 + level ~/ 3);

int minDayForExt(double ext) {
  final h = (ext - 0.001).ceil();
  return h <= 3 ? 0 : (h - 3) * 3;
}

double extOf(double x, double y, double w, double d) => [
      (x - center).abs(),
      (x + w - center).abs(),
      (y - center).abs(),
      (y + d - center).abs(),
    ].reduce(math.max);

enum Kind {
  tower, house, barn, church, market, windmill, lighthouse, mountain,
  pine, oak, bush, flowers, rock, lamp, well, bench, sign, pen,
  path, field, pond, bridge, balloon,
}

const Map<Kind, String> kindNames = {
  Kind.house: 'a family moved into a new house',
  Kind.barn: 'a barn was raised',
  Kind.church: 'a chapel was built',
  Kind.market: 'the market opened',
  Kind.windmill: 'a windmill started turning',
  Kind.lighthouse: 'the lighthouse was lit',
  Kind.mountain: 'mountains rose at the edge',
  Kind.pen: 'sheep arrived',
  Kind.field: 'a new field was planted',
  Kind.pond: 'a pond appeared',
  Kind.well: 'a well was dug',
  Kind.bridge: 'a bridge was built',
  Kind.balloon: 'a hot-air balloon arrived',
};

class Item {
  const Item(this.kind, this.day, this.x, this.y, {this.w = 0.6, this.d = 0.6, this.h = 0, this.variant = 0});

  final Kind kind;
  final int day;
  final double x, y, w, d, h;
  final int variant;

  double get ext => extOf(x, y, w, d);
  Rect get rect => Rect.fromLTWH(x, y, w, d);

  bool get isBuilding =>
      kind == Kind.house || kind == Kind.barn || kind == Kind.church || kind == Kind.market || kind == Kind.windmill;

  Item withDay(int day) => Item(kind, day, x, y, w: w, d: d, h: h, variant: variant);
}

const riverCells = <(int, int)>[(12, 0), (12, 1), (12, 2), (12, 3), (13, 3), (13, 4), (13, 5), (14, 5), (15, 5)];
const int riverDay = 9;
const towerRect = Rect.fromLTWH(6.5, 6.5, 3, 3);

final List<Item> layout = _build();

List<int> activeBuildingIds(int level, Set<int> ruined) => [
      for (var i = 0; i < layout.length; i++)
        if (layout[i].isBuilding && layout[i].day <= level && !ruined.contains(i)) i,
    ];

List<Item> _build() {
  const hand = <Item>[
    Item(Kind.path, 2, 7.7, 9.5, w: 0.6, d: 0.7),
    Item(Kind.path, 2, 5.0, 10.2, w: 6.0, d: 0.6),
    Item(Kind.path, 6, 7.7, 10.8, w: 0.6, d: 2.2),
    Item(Kind.path, 9, 2.0, 10.2, w: 3.0, d: 0.6),
    Item(Kind.path, 9, 11.0, 10.2, w: 3.0, d: 0.6),
    Item(Kind.path, 15, 0.0, 10.2, w: 2.0, d: 0.6),
    Item(Kind.path, 15, 14.0, 10.2, w: 2.0, d: 0.6),
    Item(Kind.path, 15, 7.7, 13.0, w: 0.6, d: 3.0),
    Item(Kind.oak, 1, 10.0, 6.9),
    Item(Kind.bush, 1, 5.5, 6.3, w: 0.5, d: 0.5),
    Item(Kind.house, 2, 5.0, 8.8, w: 1.4, d: 1.2, variant: 0),
    Item(Kind.lamp, 3, 8.5, 9.6, w: 0.3, d: 0.3),
    Item(Kind.flowers, 3, 6.95, 11.0, w: 0.5, d: 0.5),
    Item(Kind.pine, 3, 4.4, 4.4),
    Item(Kind.pine, 3, 11.4, 5.8),
    Item(Kind.house, 4, 9.7, 8.8, w: 1.4, d: 1.2, variant: 1),
    Item(Kind.well, 5, 5.0, 7.4),
    Item(Kind.bench, 5, 6.6, 9.75, w: 0.6, d: 0.3),
    Item(Kind.house, 6, 3.3, 8.8, w: 1.4, d: 1.2, variant: 2),
    Item(Kind.oak, 6, 3.3, 4.4),
    Item(Kind.rock, 6, 12.3, 6.6, w: 0.5, d: 0.4),
    Item(Kind.field, 7, 10.8, 11.0, w: 2.0, d: 1.8),
    Item(Kind.sign, 7, 10.4, 10.9, w: 0.2, d: 0.2),
    Item(Kind.house, 8, 5.4, 11.0, w: 1.4, d: 1.2, variant: 3),
    Item(Kind.lamp, 9, 4.72, 9.85, w: 0.25, d: 0.25),
    Item(Kind.lamp, 9, 11.3, 9.9, w: 0.3, d: 0.3),
    Item(Kind.windmill, 10, 3.6, 12.6, w: 1.2, d: 1.2),
    Item(Kind.lamp, 10, 8.5, 12.4, w: 0.3, d: 0.3),
    Item(Kind.house, 11, 9.0, 11.0, w: 1.4, d: 1.2, variant: 4),
    Item(Kind.barn, 12, 13.0, 11.2, w: 1.6, d: 1.3),
    Item(Kind.pen, 12, 1.4, 6.0, w: 2.0, d: 2.0),
    Item(Kind.house, 13, 12.2, 8.8, w: 1.4, d: 1.2, variant: 5),
    Item(Kind.pond, 14, 1.0, 3.8, w: 2.0, d: 1.6),
    Item(Kind.mountain, 15, 0.2, 0.2, w: 3.2, d: 3.2, h: 115),
    Item(Kind.mountain, 16, 3.9, 0.3, w: 2.5, d: 2.5, h: 85),
    Item(Kind.house, 17, 1.4, 8.8, w: 1.4, d: 1.2, variant: 6),
    Item(Kind.mountain, 18, 6.6, 0.4, w: 1.8, d: 1.8, h: 50),
    Item(Kind.house, 19, 14.0, 8.8, w: 1.4, d: 1.2, variant: 7),
    Item(Kind.lighthouse, 20, 14.6, 0.4, w: 1.0, d: 1.0),
    Item(Kind.church, 21, 9.0, 1.2, w: 1.6, d: 1.4),
    Item(Kind.bridge, 21, 12.0, 1.0, w: 1.0, d: 1.0),
    Item(Kind.house, 22, 2.0, 11.0, w: 1.4, d: 1.2, variant: 8),
    Item(Kind.field, 23, 14.0, 6.4, w: 1.6, d: 2.0),
    Item(Kind.house, 24, 9.0, 13.2, w: 1.4, d: 1.2, variant: 9),
    Item(Kind.market, 25, 9.8, 4.4, w: 2.0, d: 1.2),
    Item(Kind.house, 26, 12.0, 13.4, w: 1.4, d: 1.2, variant: 10),
    Item(Kind.house, 28, 5.4, 13.6, w: 1.4, d: 1.2, variant: 11),
    Item(Kind.balloon, 29, 4.0, 6.0, w: 0, d: 0),
  ];

  final items = [for (final it in hand) it.withDay(math.max(it.day, minDayForExt(it.ext)))];

  final blocked = <Rect>[
    towerRect.inflate(0.35),
    const Rect.fromLTWH(6.6, 9.6, 1.0, 0.6), // clock-keeper's spot
    for (final it in items)
      if (it.kind != Kind.balloon) it.rect.inflate(it.kind == Kind.mountain ? 0.1 : 0.3),
    for (final c in riverCells) Rect.fromLTWH(c.$1.toDouble(), c.$2.toDouble(), 1, 1).inflate(0.15),
  ];
  bool free(Rect r) => !blocked.any((b) => b.overlaps(r));

  final rnd = math.Random(7);
  const trees = 60;
  for (var i = 0, tries = 0; i < trees && tries < 4000; tries++) {
    final x = 0.15 + rnd.nextDouble() * 15.2, y = 0.15 + rnd.nextDouble() * 15.2;
    final r = Rect.fromLTWH(x, y, 0.6, 0.6);
    if (!free(r)) continue;
    blocked.add(r.inflate(0.12));
    final base = 3 + (i * 37 / trees).floor();
    items.add(Item(rnd.nextDouble() < 0.55 ? Kind.pine : Kind.oak, math.max(base, minDayForExt(extOf(x, y, .6, .6))), x, y,
        variant: rnd.nextInt(100)));
    i++;
  }
  const decor = 45;
  const decorKinds = [Kind.bush, Kind.flowers, Kind.rock, Kind.flowers, Kind.bush];
  for (var i = 0, tries = 0; i < decor && tries < 4000; tries++) {
    final x = 0.15 + rnd.nextDouble() * 15.4, y = 0.15 + rnd.nextDouble() * 15.4;
    final r = Rect.fromLTWH(x, y, 0.45, 0.45);
    if (!free(r)) continue;
    blocked.add(r.inflate(0.05));
    final base = 1 + (i * 35 / decor).floor();
    items.add(Item(decorKinds[rnd.nextInt(decorKinds.length)], math.max(base, minDayForExt(extOf(x, y, .45, .45))), x, y,
        w: 0.45, d: 0.45, variant: rnd.nextInt(100)));
    i++;
  }
  return items;
}
