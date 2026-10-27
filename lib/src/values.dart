import 'dart:convert';

import 'byte_reader.dart';

part 'values/blood_pressure.dart';
part 'values/cycling.dart';
part 'values/device.dart';
part 'values/glucose.dart';
part 'values/heart_rate.dart';
part 'values/pulse_oximeter.dart';
part 'values/running.dart';
part 'values/temperature.dart';
part 'values/weight.dart';

/// A parsed characteristic value.
///
/// The class is sealed, so a `switch` over it can handle every type the
/// package returns:
///
/// ```dart
/// switch (GattParser.parse(uuid, bytes)) {
///   case HeartRateMeasurement(:final bpm):
///     print('Heart rate: $bpm');
///   case BatteryLevel(:final percent):
///     print('Battery: $percent%');
///   default:
///     break;
/// }
/// ```
sealed class GattValue {
  const GattValue();
}

bool _has(int flags, int mask) => flags & mask != 0;

/// Builds `Name(field: value, ...)`, leaving out null fields.
String _describe(String name, Map<String, Object?> fields) {
  final shown = fields.entries
      .where((field) => field.value != null)
      .map((field) => '${field.key}: ${field.value}');
  return '$name(${shown.join(', ')})';
}
