import 'package:flutter/material.dart';
import 'app_constants.dart';

extension TabletUtils on BuildContext {
  bool get isTablet {
    final shortestSide = MediaQuery.sizeOf(this).shortestSide;
    return shortestSide >= AppConstants.tabletMinWidthDp;
  }
}
