part of smashlibs;

abstract class OnMapTapHandler {
  void handleTap(LatLng tapCoordinate, double zoom);
  void handleLongTap(LatLng tapCoordinate, double zoom);
}

// ignore: must_be_immutable
class SmashMapWidget extends StatelessWidget {
  JTS.Coordinate? _initCenterCoordonate;
  JTS.Envelope? _initBounds;
  double _initZoom = 13.0;
  double _minZoom = SmashMapState.MINZOOM;
  double _maxZoom = SmashMapState.MAXZOOM;
  bool _canRotate = false;
  bool _useLayerManager = true;
  bool _addBorder = false;
  bool consumerBuild = false;
  bool _isMapReady = false;

  MapController _mapController = MapController();
  List<Widget> preLayers = [];
  List<Widget> postLayers = [];
  List<LayerSource> layerSources = [];
  List<Widget> nonRotationLayers = [];
  void Function(LatLng, double) _handleTap = (ll, z) {};
  void Function(LatLng, double) _handleLongTap = (ll, z) {};
  void Function() _onMapReady = () {};
  void Function(MapPosition, bool) _onPositionChanged =
      (mapPosition, hasGesture) {};

  SmashMapWidget({Key? key})
      : super(key: key != null ? key : ValueKey("SMASH_MAPVIEW"));

  void setInitParameters({
    JTS.Coordinate? centerCoordinate,
    JTS.Envelope? initBounds,
    double? initZoom,
    double? minZoom,
    double? maxZoom,
    bool canRotate = false,
    bool useLayerManager = true,
    bool addBorder = false,
  }) {
    if (centerCoordinate != null) _initCenterCoordonate = centerCoordinate;
    if (initBounds != null) _initBounds = initBounds;
    if (initZoom != null) _initZoom = initZoom;
    if (minZoom != null) _minZoom = minZoom;
    if (maxZoom != null) _maxZoom = maxZoom;
    _canRotate = canRotate;
    _useLayerManager = useLayerManager;
    _addBorder = addBorder;
  }

  void setTapHandlers(
      {Function(LatLng, double)? handleTap,
      Function(LatLng, double)? handleLongTap}) {
    if (handleTap != null) _handleTap = handleTap;
    if (handleLongTap != null) _handleLongTap = handleLongTap;
  }

  void setOnMapReady(Function()? onMapReady) {
    if (onMapReady != null) _onMapReady = onMapReady;
  }

  bool isMapReady() {
    return _isMapReady;
  }

  void setOnPositionChanged(Function(MapPosition, bool)? onPositionChanged) {
    if (onPositionChanged != null) _onPositionChanged = onPositionChanged;
  }

  /// Clear all layers list (pre, post and manual [LayerSource]s).
  void clearLayers() {
    preLayers.clear();
    postLayers.clear();
    layerSources.clear();
  }

  /// Add a [LayerSource]. If [_useLayerManager] is set to false,
  /// this creates a custom datasource list to be used (in case the common
  /// layers are not wanted in a different map view).
  void addLayerSource(LayerSource layerSource) {
    if (_useLayerManager) {
      LayerManager().addLayerSource(layerSource);
    } else if (!layerSources.contains(layerSource)) {
      layerSources.add(layerSource);
    }
  }

  void removeLayerSource(LayerSource layerSource) {
    if (_useLayerManager) {
      LayerManager().removeLayerSource(layerSource);
    } else if (layerSources.contains(layerSource)) {
      layerSources.remove(layerSource);
    }
  }

  /// Add a layer to the list of layers that is loaded before
  /// the [LayerManager] layers.
  void addPreLayer(Widget layer) {
    int index = _getLayerIndex(preLayers, layer);
    if (index != -1) {
      preLayers[index] = layer;
    } else {
      preLayers.add(layer);
    }
  }

  /// Add a layer to the list of layers that is loaded after
  /// the [LayerManager] layers.
  void addPostLayer(Widget layer) {
    int index = _getLayerIndex(postLayers, layer);
    if (index != -1) {
      postLayers[index] = layer;
    } else {
      postLayers.add(layer);
    }
  }

  int _getLayerIndex(List<Widget> list, Widget layer) {
    int i = 0;
    for (var item in list) {
      if (item.key == layer.key) {
        return i;
      }
      i++;
    }
    return -1;
  }

  // Add a layer that is not subject to rotation.
  void addNonRotationLayer(Widget layer) {
    int index = _getLayerIndex(nonRotationLayers, layer);
    if (index != -1) {
      nonRotationLayers[index] = layer;
    } else {
      nonRotationLayers.add(layer);
    }
  }

  void triggerRebuild(BuildContext context) {
    Provider.of<SmashMapBuilder>(context, listen: false).reBuild();
  }

  void zoomToBounds(JTS.Envelope bounds) {
    _mapController.fitBounds(LatLngBounds(
        LatLng(bounds.getMinY(), bounds.getMinX()),
        LatLng(bounds.getMaxY(), bounds.getMaxX())));
  }

  void centerOn(JTS.Coordinate ll) {
    _mapController.move(LatLngExt.fromCoordinate(ll), _mapController.zoom);
  }

  void zoomTo(double newZoom) {
    _mapController.move(_mapController.center, newZoom);
  }

  void zoomIn() {
    var z = _mapController.zoom + 1;
    if (z > _maxZoom) z = _maxZoom;
    zoomTo(z);
  }

  void zoomOut() {
    var z = _mapController.zoom - 1;
    if (z < _minZoom) z = _minZoom;
    zoomTo(z);
  }

  void centerAndZoomOn(JTS.Coordinate ll, double newZoom) {
    _mapController.move(LatLngExt.fromCoordinate(ll), newZoom);
  }

  void rotate(double heading) {
    _mapController.rotate(heading);
  }

  JTS.Envelope? getBounds() {
    if (_mapController.bounds != null) {
      return LatLngBoundsExt.fromBounds(_mapController.bounds!).toEnvelope();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    consumerBuild = false;
    return Consumer<SmashMapBuilder>(builder: (context, mapBuilder, child) {
      consumerBuild = true;
      mapBuilder.context = context;
      // mapBuilder.scaffoldKey = _scaffoldKey;
      return consumeBuild(mapBuilder);
    });
  }

  Widget consumeBuild(SmashMapBuilder mapBuilder) {
    var layers = <Widget>[];

    layers.addAll(preLayers);
    if (_useLayerManager) {
      layers.addAll(LayerManager().getActiveLayers());
    } else {
      layers.addAll(layerSources
          .map((l) => SmashMapLayer(
                l,
                key: ValueKey(l.getName()),
              ))
          .toList());
    }
    layers.addAll(postLayers);

    BuildContext context = mapBuilder.context!;
    var mapState = Provider.of<SmashMapState>(context, listen: false);
    mapState.mapView = this;
    var mapFlags = InteractiveFlag.all &
        ~InteractiveFlag.flingAnimation &
        ~InteractiveFlag.pinchMove;
    if (!_canRotate) {
      mapFlags = mapFlags & ~InteractiveFlag.rotate;
    }

    // ! TODO check
    // GeometryEditorState editorState =
    //     Provider.of<GeometryEditorState>(context, listen: false);
    // if (editorState.isEnabled) {
    //   GeometryEditManager().startEditing(editorState.editableGeometry, () {
    //     // editorState.refreshEditLayer();
    //     triggerRebuild(context);
    //   });
    //   GeometryEditManager().addEditLayers(layers);
    // }
    var layerKey = "SmashMapEditLayer-${key.toString()}";
    layers.add(SmashMapEditLayer(
      key: ValueKey(layerKey),
    ));

    var mapKey = "FlutterMapWidget-${key.toString()}";
    Widget flutterMap = FlutterMap(
      key: ValueKey(mapKey),
      options: new MapOptions(
        bounds: _initBounds != null
            ? LatLngBounds(
                LatLng(_initBounds!.getMinY(), _initBounds!.getMinX()),
                LatLng(_initBounds!.getMaxY(), _initBounds!.getMaxX()))
            : null,
        center: _initCenterCoordonate != null && _initBounds == null
            ? new LatLng(_initCenterCoordonate!.y, _initCenterCoordonate!.x)
            : null,
        zoom: _initZoom,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        onPositionChanged: (newPosition, hasGesture) {
          _onPositionChanged(newPosition, hasGesture);
        },
        onMapEvent: (MapEvent mapEvent) {
          if (mapEvent is MapEventDoubleTapZoom ||
              mapEvent is MapEventScrollWheelZoom ||
              mapEvent is MapEventMove) {
            SmashMapState mapState =
                Provider.of<SmashMapState>(context, listen: false);
            mapState.notifyListenersMsg("manual zoom update");
          }
        },
        onTap: (TapPosition tPos, LatLng point) =>
            _handleTap(point, _mapController.zoom),
        onLongPress: (TapPosition tPos, LatLng point) =>
            _handleLongTap(point, _mapController.zoom),
        interactiveFlags: mapFlags,
        onMapReady: () {
          _isMapReady = true;
          _onMapReady();
        },
      ),
      children: layers,
      nonRotatedChildren: nonRotationLayers,
      mapController: _mapController,
    );

    if (_addBorder) {
      flutterMap = Container(
        child: flutterMap,
        decoration: BoxDecoration(
            color: SmashColors.mainBackground,
            border:
                Border.all(width: 1, color: SmashColors.mainDecorationsDarker)),
      );
    }
    return Stack(
      children: <Widget>[
        flutterMap,
        mapBuilder.inProgress
            ? Center(
                child: SmashCircularProgress(
                  label:
                      SLL.of(context).mainView_loadingData, //"Loading data...",
                ),
              )
            : SizedBox.shrink(),
        // Align(
        //   alignment: Alignment.bottomRight,
        //   child: _iconMode == IconMode.NAVIGATION_MODE
        //       ? IconButton(
        //           key: coachMarks.toolbarButtonKey,
        //           icon: Icon(
        //             MdiIcons.forwardburger,
        //             color: SmashColors.mainDecorations,
        //             size: 32,
        //           ),
        //           onPressed: () {
        //             setState(() {
        //               _iconMode = IconMode.TOOL_MODE;
        //             });
        //           },
        //         )
        //       : IconButton(
        //           icon: Icon(
        //             MdiIcons.backburger,
        //             color: SmashColors.mainDecorations,
        //             size: 32,
        //           ),
        //           onPressed: () {
        //             BottomToolbarToolsRegistry.disableAll(context);
        //             setState(() {
        //               _iconMode = IconMode.NAVIGATION_MODE;
        //             });
        //           },
        //         ),
        // )
      ],
    );
  }
}
