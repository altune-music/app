import 'package:flutter/services.dart';

/// Owns the Android battery optimization platform channel.
///
/// Extracted from SettingsScreen so the widget stays dumb and the
/// channel logic is unit-testable without a widget tree.
class BatteryOptimizationService {
  static const _channel = MethodChannel('altune/battery_settings');

  Future<bool?> isExempted() =>
      _channel.invokeMethod<bool>('getBatteryOptimizationStatus');

  Future<void> openSettings() =>
      _channel.invokeMethod('openBatteryOptimizationSettings');
}
