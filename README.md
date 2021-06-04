# flutter_map_fast_markers
A [blazing-fast](https://twitter.com/acdlite/status/974390255393505280) solution for Markers in flutter_map when you need *a lot* of them

## Why?
Original `flutter_map` Markers are cool if you use ~200 of them. You give them a builder with standard Flutter widget,
and it works. Easy to make, maintain, and use with libraries, right?

Problems arrive when you want to use 600, 1000, or 5000 of them - turns out Flutter doesn't like this, and starts to
**lag** as hell 🔥 to the point where your app crashes 💥 This plugin lets you draw your markers *directly on canvas*,
which is *way faster* 🚀

## How to use
1. Prepare you markers:
    ```dart
    final redPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    const width = 16, height = 16;
    final markers = [
      FastMarker(
        point: LatLng(49.8828, 19.4930),
        width: width,
        height: height,
        anchorPos: AnchorPos.align(AnchorAlign.center),
        onDraw: (canvas, offset) {
          canvas.drawCircle(
            offset + Offset(width / 2, height / 2),  // The center
            width / 2,  // Radius
            redPaint,
          );
        },
        onTap: () => print("Marker was tapped!"),
      ),
    ];
    ```
    The `onDraw` method is where the magic happens - you get a `canvas` to draw on, and `offset` that tells you *where*
    to draw. `offset` is a location of upper-left corner of the rectangle where you should draw
    
    ![onDraw explanation](https://user-images.githubusercontent.com/40139196/118564102-013e1c80-b770-11eb-94da-b15d13c4d861.jpg)
     
    "Should" - that's a good word, because while having access to full `canvas`, you *could* draw anywhere you want...
    **Do not** do this! The plugin doesn't draw markers that are not currently visible on screen, so your markers will
    unexpectedly disappear if you draw them outside previously defined `width` and `height`
    
    **Important note** - `onDraw` executes every frame for every visible marker when map is moved! So keep it as light 
    as possible and move anything you can outside

2. Add it to your Map Options:
    ```dart
    FlutterMap(
      options: MapOptions(
        ...
        plugins: [FastMarkersPlugin()],
      ),
      layers: [
        ...
        FastMarkersLayerOptions(markers: markers),
      ],
    ),
    ```
