import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import 'fast_markers_layer_option.dart';

class Anchor {
  final double left;
  final double top;

  Anchor(this.left, this.top);

  Anchor._(double width, double height, AnchorAlign alignOpt)
      : left = _leftOffset(width, alignOpt),
        top = _topOffset(height, alignOpt);

  static double _leftOffset(double width, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.left:
        return 0.0;
      case AnchorAlign.right:
        return width;
      case AnchorAlign.top:
      case AnchorAlign.bottom:
      case AnchorAlign.center:
      default:
        return width / 2;
    }
  }

  static double _topOffset(double height, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.top:
        return 0.0;
      case AnchorAlign.bottom:
        return height;
      case AnchorAlign.left:
      case AnchorAlign.right:
      case AnchorAlign.center:
      default:
        return height / 2;
    }
  }

  factory Anchor.forPos(AnchorPos pos, double width, double height) {
    if (pos == null) return Anchor._(width, height, null);
    if (pos.value is AnchorAlign) return Anchor._(width, height, pos.value);
    if (pos.value is Anchor) return pos.value;
    throw Exception('Unsupported AnchorPos value type: ${pos.runtimeType}.');
  }
}

class AnchorPos<T> {
  AnchorPos._(this.value);

  T value;

  static AnchorPos exactly(Anchor anchor) => AnchorPos._(anchor);

  static AnchorPos align(AnchorAlign alignOpt) => AnchorPos._(alignOpt);
}

enum AnchorAlign {
  left,
  right,
  top,
  bottom,
  center,
}

class FastMarker {
  final LatLng point;
  final double width;
  final double height;
  final Anchor anchor;

  /// If true marker will be counter rotated to the map rotation
  final bool rotate;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset rotateOrigin;

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
  final AlignmentGeometry rotateAlignment;

  FastMarker({
    this.point,
    this.width = 30.0,
    this.height = 30.0,
    this.rotate,
    this.rotateOrigin,
    this.rotateAlignment,
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
    return StreamBuilder<int>(
      stream: widget.stream, // a Stream<int> or null
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        return CustomPaint(
          painter: painter,
          willChange: true,
        );
      },
    );
  }
}

class _FastMarkersPainter extends CustomPainter {
  final MapState map;
  final FastMarkersLayerOptions options;
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
    for (var i = 0; i < options.markers.length; i++) {
      var marker = options.markers[i];

      // Decide whether to use cached point or calculate it
      var pxPoint = sameZoom ? _pxCache[i] : map.project(marker.point);
      if (!sameZoom) {
        _pxCache[i] = pxPoint;
      }

      final width = marker.width - marker.anchor.left;
      final height = marker.height - marker.anchor.top;
      var sw = CustomPoint(pxPoint.x + width, pxPoint.y - height);
      var ne = CustomPoint(pxPoint.x - width, pxPoint.y + height);

      if (!map.pixelBounds.containsPartialBounds(Bounds(sw, ne))) {
        continue;
      }

      final pos = pxPoint - map.getPixelOrigin();
      // TODO: Rotating markers when they will have their own shapes
      final redPaint = Paint()..color = Colors.green;
      canvas.drawCircle(
          Offset(pos.x - width, pos.y - height), marker.width, redPaint);
    }
    _lastZoom = map.zoom;
  }

  @override
  bool shouldRepaint(covariant _FastMarkersPainter oldDelegate) {
    return true;
  }
}
