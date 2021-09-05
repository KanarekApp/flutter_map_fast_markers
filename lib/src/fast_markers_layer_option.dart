import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_fast_markers/flutter_map_fast_markers.dart';

class FastMarkersLayerOptions extends LayerOptions {
  final List<FastMarker> markers;

  // TODO: Rotating
  /// If true markers will be counter rotated to the map rotation
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

  FastMarkersLayerOptions({
    Key? key,
    this.markers = const [],
    // this.rotate = false,
    // this.rotateOrigin,
    // this.rotateAlignment = Alignment.center,
    Stream<Null>? rebuild,
  }) : super(key: key, rebuild: rebuild);
}
