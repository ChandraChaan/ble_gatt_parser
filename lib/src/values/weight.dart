part of '../values.dart';

enum WeightUnit { kilograms, pounds }

/// Weight Measurement (0x2A9D), sent by smart scales.
final class WeightMeasurement extends GattValue {
  const WeightMeasurement({
    required this.weight,
    required this.unit,
    this.timestamp,
    this.userId,
    this.bmi,
    this.height,
  });

  factory WeightMeasurement.parse(List<int> value) {
    final reader = ByteReader(value, 'Weight Measurement');
    final flags = reader.uint8('flags');
    final imperial = _has(flags, 0x01);
    final rawWeight = reader.uint16('weight');
    final timestamp = _has(flags, 0x02) ? reader.dateTime('time stamp') : null;
    final userId = _has(flags, 0x04) ? reader.uint8('user ID') : null;
    double? bmi;
    double? height;
    if (_has(flags, 0x08)) {
      bmi = reader.uint16('BMI') / 10;
      final rawHeight = reader.uint16('height');
      height = imperial ? rawHeight / 10 : rawHeight / 1000;
    }
    return WeightMeasurement(
      // 0xFFFF means the scale couldn't take a measurement.
      weight: rawWeight == 0xFFFF
          ? null
          : imperial
              ? rawWeight / 100
              : rawWeight / 200,
      unit: imperial ? WeightUnit.pounds : WeightUnit.kilograms,
      timestamp: timestamp,
      userId: userId,
      bmi: bmi,
      height: height,
    );
  }

  /// The weight in [unit], or null if the measurement failed.
  final double? weight;
  final WeightUnit unit;
  final DateTime? timestamp;

  /// Which user on a shared scale stepped on. 255 means unknown.
  final int? userId;
  final double? bmi;

  /// Height in meters for [WeightUnit.kilograms], or inches for
  /// [WeightUnit.pounds].
  final double? height;

  double? get kilograms => switch (weight) {
        null => null,
        final weight when unit == WeightUnit.kilograms => weight,
        final weight => weight * 0.45359237,
      };

  @override
  String toString() => _describe('WeightMeasurement', {
        'weight': weight,
        'unit': unit.name,
        'timestamp': timestamp,
        'userId': userId,
        'bmi': bmi,
        'height': height,
      });
}
