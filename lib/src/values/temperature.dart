part of '../values.dart';

enum TemperatureUnit { celsius, fahrenheit }

/// Where on the body a temperature was taken.
enum TemperatureType {
  armpit,
  body,
  ear,
  finger,
  gastrointestinalTract,
  mouth,
  rectum,
  toe,
  tympanum,
  unknown;

  static TemperatureType _fromCode(int code) =>
      code >= 1 && code <= 9 ? values[code - 1] : unknown;
}

/// Temperature Measurement (0x2A1C) or Intermediate Temperature (0x2A1E),
/// sent by Bluetooth thermometers.
final class TemperatureMeasurement extends GattValue {
  const TemperatureMeasurement({
    required this.value,
    required this.unit,
    this.timestamp,
    this.type,
  });

  factory TemperatureMeasurement.parse(List<int> value) {
    final reader = ByteReader(value, 'Temperature Measurement');
    final flags = reader.uint8('flags');
    final temperature = reader.float('temperature');
    final timestamp = _has(flags, 0x02) ? reader.dateTime('time stamp') : null;
    final type = _has(flags, 0x04)
        ? TemperatureType._fromCode(reader.uint8('temperature type'))
        : null;
    return TemperatureMeasurement(
      value: temperature,
      unit: _has(flags, 0x01)
          ? TemperatureUnit.fahrenheit
          : TemperatureUnit.celsius,
      timestamp: timestamp,
      type: type,
    );
  }

  /// The temperature in [unit].
  final double value;
  final TemperatureUnit unit;
  final DateTime? timestamp;
  final TemperatureType? type;

  double get celsius =>
      unit == TemperatureUnit.celsius ? value : (value - 32) * 5 / 9;

  double get fahrenheit =>
      unit == TemperatureUnit.fahrenheit ? value : value * 9 / 5 + 32;

  @override
  String toString() => _describe('TemperatureMeasurement', {
        'value': value,
        'unit': unit.name,
        'timestamp': timestamp,
        'type': type?.name,
      });
}
