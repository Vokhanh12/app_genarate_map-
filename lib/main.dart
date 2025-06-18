import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

// test
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: MapScreen()),
  ));
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  static const double tileSize = 32.0;

  late AnimationController controller;
  late Animation<double> animation;

  List<Point<int>> path = [];
  int currentSegment = 0;

  Point<int> currentPosition = Point(0, 0);

  @override
  void initState() {
    super.initState();
    path = findPath(Point(0, 0), Point(9, 9), mapGrid);

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && path.length > 1) {
          currentSegment = (currentSegment + 1) % (path.length - 1);
          controller.forward(from: 0);
        }
      });

    animation = CurvedAnimation(parent: controller, curve: Curves.linear);
    controller.forward();
  }

  void move(Point<int> direction) {
    final next = Point(currentPosition.x + direction.x, currentPosition.y + direction.y);
    if (_isWalkable(next)) {
      setState(() {
        currentPosition = next;
      });
    }
  }

  bool _isWalkable(Point<int> p) =>
      p.y >= 0 &&
      p.x >= 0 &&
      p.y < mapGrid.length &&
      p.x < mapGrid[0].length &&
      mapGrid[p.y][p.x] == TileType.road;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 10 * tileSize,
            height: 10 * tileSize,
            child: CustomPaint(
              painter: MapPainter(
                map: mapGrid,
                tileSize: tileSize,
                path: path,
                currentSegment: currentSegment,
                animationValue: animation.value,
                currentPosition: currentPosition,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(onPressed: () => move(Point(0, -1)), child: const Text("↑")),
              ElevatedButton(onPressed: () => move(Point(-1, 0)), child: const Text("←")),
              ElevatedButton(onPressed: () => move(Point(1, 0)), child: const Text("→")),
              ElevatedButton(onPressed: () => move(Point(0, 1)), child: const Text("↓")),
            ],
          ),
        ],
      ),
    );
  }
}

enum TileType {
  road,
  building,
  park,
  water,
  empty,
}

final List<List<TileType>> mapGrid = [
  [TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road],
  [TileType.road, TileType.building, TileType.building, TileType.building, TileType.road, TileType.park, TileType.park, TileType.park, TileType.road, TileType.road],
  [TileType.road, TileType.building, TileType.water, TileType.building, TileType.road, TileType.park, TileType.water, TileType.park, TileType.road, TileType.road],
  [TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road],
  [TileType.road, TileType.building, TileType.building, TileType.building, TileType.road, TileType.park, TileType.park, TileType.park, TileType.road, TileType.road],
  [TileType.road, TileType.building, TileType.water, TileType.building, TileType.road, TileType.park, TileType.water, TileType.park, TileType.road, TileType.road],
  [TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road],
  [TileType.road, TileType.empty, TileType.empty, TileType.empty, TileType.road, TileType.empty, TileType.empty, TileType.empty, TileType.road, TileType.road],
  [TileType.road, TileType.empty, TileType.empty, TileType.empty, TileType.road, TileType.empty, TileType.empty, TileType.empty, TileType.road, TileType.road],
  [TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road, TileType.road],
];

class MapPainter extends CustomPainter {
  final List<List<TileType>> map;
  final double tileSize;
  final List<Point<int>> path;
  final int currentSegment;
  final double animationValue;
  final Point<int> currentPosition;

  MapPainter({
    required this.map,
    required this.tileSize,
    required this.path,
    required this.currentSegment,
    required this.animationValue,
    required this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        paint.color = _tileColor(map[y][x]);
        canvas.drawRect(
          Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize),
          paint,
        );
      }
    }

    _drawPath(canvas);
    _drawMovingDot(canvas);
  }

  void _drawPath(Canvas canvas) {
    if (path.length < 2) return;

    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final pathPainter = Path()
      ..moveTo(path[0].x * tileSize + tileSize / 2, path[0].y * tileSize + tileSize / 2);

    for (int i = 1; i < path.length; i++) {
      pathPainter.lineTo(path[i].x * tileSize + tileSize / 2, path[i].y * tileSize + tileSize / 2);
    }

    canvas.drawPath(pathPainter, paint);
  }

  void _drawMovingDot(Canvas canvas) {
    final dx = currentPosition.x * tileSize + tileSize / 2;
    final dy = currentPosition.y * tileSize + tileSize / 2;

    final paint = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(dx, dy), tileSize / 3, paint);
  }

  Color _tileColor(TileType type) {
    switch (type) {
      case TileType.road:
        return Colors.grey.shade800;
      case TileType.building:
        return Colors.brown.shade400;
      case TileType.park:
        return Colors.green.shade600;
      case TileType.water:
        return Colors.lightBlue.shade300;
      case TileType.empty:
        return Colors.white;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

List<Point<int>> findPath(Point<int> start, Point<int> goal, List<List<TileType>> map) {
  bool isWalkable(Point<int> p) =>
      p.y >= 0 &&
      p.x >= 0 &&
      p.y < map.length &&
      p.x < map[0].length &&
      map[p.y][p.x] == TileType.road;

  final openSet = <Point<int>>[start];
  final cameFrom = <Point<int>, Point<int>>{};
  final gScore = <Point<int>, int>{start: 0};
  final fScore = <Point<int>, double>{start: _heuristic(start, goal)};

  while (openSet.isNotEmpty) {
    openSet.sort((a, b) => fScore[a]!.compareTo(fScore[b]!));
    final current = openSet.removeAt(0);

    if (current == goal) return _reconstructPath(cameFrom, current);

    for (final neighbor in _neighbors(current, map)) {
      if (!isWalkable(neighbor)) continue;

      final tentativeG = gScore[current]! + 1;
      if (tentativeG < (gScore[neighbor] ?? double.infinity)) {
        cameFrom[neighbor] = current;
        gScore[neighbor] = tentativeG;
        fScore[neighbor] = tentativeG + _heuristic(neighbor, goal);
        if (!openSet.contains(neighbor)) openSet.add(neighbor);
      }
    }
  }
  return [];
}

double _heuristic(Point a, Point b) => (a.x - b.x).abs() + (a.y - b.y).abs().toDouble();

List<Point<int>> _neighbors(Point<int> p, List<List<TileType>> map) {
  final directions = [Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)];

  return directions
      .map((d) => Point(p.x + d.x, p.y + d.y))
      .where((n) => n.x >= 0 && n.y >= 0 && n.y < map.length && n.x < map[0].length)
      .toList();
}

List<Point<int>> _reconstructPath(Map<Point<int>, Point<int>> cameFrom, Point<int> current) {
  final path = <Point<int>>[current];
  while (cameFrom.containsKey(current)) {
    current = cameFrom[current]!;
    path.add(current);
  }
  return path.reversed.toList();
}
