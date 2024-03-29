part of smashlibs;
/*
 * Copyright (c) 2019-2020. Antonello Andrea (www.hydrologis.com). All rights reserved.
 * Use of this source code is governed by a GPL3 license that can be
 * found in the LICENSE file.
 */

/// A dedicated map builder class.
///
/// Used to trigger just map builds and keep context.
class SmashMapBuilder extends ChangeNotifierPlus {
  BuildContext? context;
  GlobalKey<ScaffoldState>? scaffoldKey;

  /// List of rebuilt layers in case they are reloaded from outside the mapview.
  ///
  /// These are set to null after use.
  List<Widget>? _oneShotUpdateLayers;

  bool _inProgress = false;

  /// Ask for a map rebuild
  ///
  /// Doesn't reload anything, just rebuild using the current configuration and settings.
  void reBuild() {
    notifyListenersMsg("rebuild map");
  }

  bool get inProgress => _inProgress;

  setInProgress(bool progress) {
    _inProgress = progress;
    notifyListeners();
  }

  // set oneShotUpdateLayers(List<Widget>? newLayers) {
  //   _oneShotUpdateLayers = newLayers;
  // }

  // List<Widget>? get oneShotUpdateLayers {
  //   try {
  //     return _oneShotUpdateLayers;
  //   } finally {
  //     _oneShotUpdateLayers = null;
  //   }
  // }

  static void reBuildStatic(BuildContext context) {
    var mapBuilder = Provider.of<SmashMapBuilder>(context, listen: false);
    mapBuilder.reBuild();
  }
}
