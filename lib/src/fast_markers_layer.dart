import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import 'fast_markers_layer_option.dart';

extension on CustomPoint {
  Offset toOffset() => Offset(this.x, this.y);
}

class FastMarker {
  final LatLng point;
  final double width;
  final double height;
  final Anchor anchor;
  final Function(Canvas canvas, Offset offset) onDraw;
  final Function() onTap;

  // TODO: Rotating
  /// If true marker will be counter rotated to the map rotation
  // final bool rotate;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  // final Offset rotateOrigin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [rotateOrigin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  // final AlignmentGeometry rotateAlignment;

  FastMarker({
    @required this.point,
    this.width = 30.0,
    this.height = 30.0,
    @required this.onDraw,
    this.onTap,
    // this.rotate,
    // this.rotateOrigin,
    // this.rotateAlignment,
    AnchorPos anchorPos,
  }) : anchor = Anchor.forPos(anchorPos, width, height);
}

class MarkerLayerWidget extends StatelessWidget {
  final FastMarkersLayerOptions options;

  MarkerLayerWidget({Key key, @required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.of(context);
    return FastMarkersLayer(options, mapState, mapState.onMoved);
  }
}

class FastMarkersLayer extends StatefulWidget {
  final FastMarkersLayerOptions layerOptions;
  final MapState map;
  final Stream<Null> stream;

  FastMarkersLayer(this.layerOptions, this.map, this.stream)
      : super(key: layerOptions.key);

  @override
  _FastMarkersLayerState createState() => _FastMarkersLayerState();
}

class _FastMarkersLayerState extends State<FastMarkersLayer> {
  _FastMarkersPainter painter;

  @override
  void initState() {
    super.initState();
    painter = _FastMarkersPainter(
      widget.map,
      widget.layerOptions,
    );
    widget.map.onTapRaw = (p) => painter.onTap(p.relative);
  }

  @override
  void didUpdateWidget(covariant FastMarkersLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    painter = _FastMarkersPainter(
      widget.map,
      widget.layerOptions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: StreamBuilder<int>(
        stream: widget.stream, // a Stream<int> or null
        builder: (BuildContext context, snapshot) {
          return CustomPaint(
            painter: painter,
            willChange: true,
          );
        },
      ),
    );
  }
}

class _FastMarkersPainter extends CustomPainter {
  final MapState map;
  final FastMarkersLayerOptions options;
  final List<MapEntry<Bounds, FastMarker>> markersBoundsCache = [];
  var _lastZoom = -1.0;

  _FastMarkersPainter(this.map, this.options) {
    _pxCache = generatePxCache();
  }

  /// List containing cached pixel positions of markers
  /// Should be discarded when zoom changes
  // Has a fixed length of markerOpts.markers.length - better performance:
  // https://stackoverflow.com/questions/15943890/is-there-a-performance-benefit-in-using-fixed-length-lists-in-dart
  var _pxCache = <CustomPoint>[];

  // Calling this every time markerOpts change should guarantee proper length
  List<CustomPoint> generatePxCache() => List.generate(
        options.markers.length,
        (i) => map.project(options.markers[i].point),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final sameZoom = map.zoom == _lastZoom;
    markersBoundsCache.clear();
    for (var i = 0; i < options.markers.length; i++) {
      var marker = options.markers[i];

      // Decide whether to use cached point or calculate it
      var pxPoint = sameZoom ? _pxCache[i] : map.project(marker.point);
      if (!sameZoom) {
        _pxCache[i] = pxPoint;
      }

      var topLeft = CustomPoint(
          pxPoint.x - marker.anchor.left, pxPoint.y - marker.anchor.top);
      var bottomRight =
          CustomPoint(topLeft.x + marker.width, topLeft.y + marker.height);

      if (!map.pixelBounds
          .containsPartialBounds(Bounds(topLeft, bottomRight))) {
        continue;
      }

      final pos = (topLeft - map.getPixelOrigin());
      // TODO: Rotating
      marker.onDraw(canvas, pos.toOffset());
      markersBoundsCache.add(
        MapEntry(
          Bounds(pos, pos + CustomPoint(marker.width, marker.height)),
          marker,
        ),
      );
    }
    _lastZoom = map.zoom;
  }

  bool onTap(Offset pos) {
    final marker = markersBoundsCache.reversed.firstWhere(
      (e) => e.key.contains(CustomPoint(pos.dx, pos.dy)),
      orElse: () => null,
    );
    if (marker != null) {
      marker.value?.onTap();
      return false;
    } else {
      return true;
    }
  }

  @override
  bool shouldRepaint(covariant _FastMarkersPainter oldDelegate) {
    return true;
  }
}
