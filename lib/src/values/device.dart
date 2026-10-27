part of '../values.dart';

/// Battery Level (0x2A19).
final class BatteryLevel extends GattValue {
  const BatteryLevel(this.percent);

  factory BatteryLevel.parse(List<int> value) =>
      BatteryLevel(ByteReader(value, 'Battery Level').uint8('battery level'));

  /// Remaining charge, from 0 to 100.
  final int percent;

  @override
  String toString() => 'BatteryLevel($percent%)';
}

/// Where a heart-rate sensor is worn.
enum SensorLocation {
  other,
  chest,
  wrist,
  finger,
  hand,
  earLobe,
  foot,
  unknown;

  static SensorLocation _fromCode(int code) =>
      code >= 0 && code <= 6 ? values[code] : unknown;
}

/// Body Sensor Location (0x2A38), read from heart-rate sensors.
final class BodySensorLocation extends GattValue {
  const BodySensorLocation(this.location);

  factory BodySensorLocation.parse(List<int> value) => BodySensorLocation(
        SensorLocation._fromCode(
          ByteReader(value, 'Body Sensor Location').uint8('location'),
        ),
      );

  final SensorLocation location;

  @override
  String toString() => 'BodySensorLocation(${location.name})';
}

/// A UTF-8 text characteristic: Device Name (0x2A00) or a Device
/// Information string such as Manufacturer Name (0x2A29), Model Number
/// (0x2A24), Serial Number (0x2A25) or Firmware Revision (0x2A26).
final class GattString extends GattValue {
  const GattString(this.uuid, this.value);

  /// Decodes [value], dropping the trailing zero bytes some devices pad
  /// with.
  factory GattString.parse(int uuid, List<int> value) {
    var end = value.length;
    while (end > 0 && value[end - 1] == 0) {
      end--;
    }
    return GattString(
      uuid,
      utf8.decode(value.sublist(0, end), allowMalformed: true),
    );
  }

  /// The 16-bit UUID this string was read from.
  final int uuid;
  final String value;

  @override
  String toString() =>
      'GattString(0x${uuid.toRadixString(16).toUpperCase()}: $value)';
}
