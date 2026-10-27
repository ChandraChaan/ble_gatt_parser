part of '../values.dart';

/// RSC Measurement (0x2A53), sent by running foot pods and some watches.
final class RscMeasurement extends GattValue {
  const RscMeasurement({
    required this.speedMps,
    required this.cadence,
    this.strideLengthM,
    this.totalDistanceM,
    this.isRunning = false,
  });

  factory RscMeasurement.parse(List<int> value) {
    final reader = ByteReader(value, 'RSC Measurement');
    final flags = reader.uint8('flags');
    final speed = reader.uint16('instantaneous speed') / 256;
    final cadence = reader.uint8('instantaneous cadence');
    final stride = _has(flags, 0x01)
        ? reader.uint16('instantaneous stride length') / 100
        : null;
    final distance =
        _has(flags, 0x02) ? reader.uint32('total distance') / 10 : null;
    return RscMeasurement(
      speedMps: speed,
      cadence: cadence,
      strideLengthM: stride,
      totalDistanceM: distance,
      isRunning: _has(flags, 0x04),
    );
  }

  /// Speed in meters per second.
  final double speedMps;

  /// Steps per minute.
  final int cadence;
  final double? strideLengthM;
  final double? totalDistanceM;

  /// Whether the sensor thinks the user is running rather than walking.
  final bool isRunning;

  double get speedKmh => speedMps * 3.6;

  /// Time per kilometer at the current speed, or null when standing still.
  Duration? get pacePerKm => speedMps == 0
      ? null
      : Duration(microseconds: (1000 / speedMps * 1e6).round());

  @override
  String toString() => _describe('RscMeasurement', {
        'speedMps': speedMps,
        'cadence': cadence,
        'strideLengthM': strideLengthM,
        'totalDistanceM': totalDistanceM,
        'isRunning': isRunning,
      });
}
