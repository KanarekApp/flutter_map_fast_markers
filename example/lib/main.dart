import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_fast_markers/flutter_map_fast_markers.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fast_markers example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

const maxMarkersCount = 5000;

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double doubleInRange(Random source, num start, num end) =>
      source.nextDouble() * (end - start) + start;
  List<FastMarker> allMarkers = [];

  int _sliderVal = maxMarkersCount ~/ 10;

  @override
  void initState() {
    super.initState();
    const colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green];
    Future.microtask(() {
      var r = Random();
      for (var x = 0; x < maxMarkersCount; x++) {
        final paint = Paint()
          ..color = colors[r.nextInt(colors.length)]
          ..strokeWidth = 2;
        const width = 12.0, height = 12.0;
        // Markers will randomly point at topLeft/bottomRight
        final option = r.nextBool();
        final anchor = option ? Anchor(0, 0) : Anchor(width, height);
        allMarkers.add(
          FastMarker(
            point: LatLng(
              doubleInRange(r, 37, 55),
              doubleInRange(r, -9, 30),
            ),
            width: width,
            height: height,
            anchorPos: AnchorPos.exactly(anchor),
            onDraw: (canvas, offset) {
              final point = offset +
                  (option ? Offset(0, 0) : Offset(anchor.left, anchor.top));
              // Lines from bottomLeft and topRight to point (where anchor is)
              canvas.drawLine(offset + Offset(width, 0), point, paint);
              canvas.drawLine(offset + Offset(0, height), point, paint);
            },
          ),
        );
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('A lot of markers')),
      body: Column(
        children: [
          Slider(
            min: 0,
            max: maxMarkersCount.toDouble(),
            divisions: maxMarkersCount ~/ 500,
            label: 'Markers',
            value: _sliderVal.toDouble(),
            onChanged: (newVal) {
              _sliderVal = newVal.toInt();
              setState(() {});
            },
          ),
          Text('$_sliderVal markers'),
          Flexible(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(50, 20),
                zoom: 5.0,
                interactiveFlags: InteractiveFlag.all - InteractiveFlag.rotate,
                plugins: [FastMarkersPlugin()],
              ),
              layers: [
                TileLayerOptions(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                FastMarkersLayerOptions(
                  markers:
                      allMarkers.sublist(0, min(allMarkers.length, _sliderVal)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
