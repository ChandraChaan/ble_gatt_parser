part of '../values.dart';

/// PLX Continuous Measurement (0x2A5F), streamed by pulse oximeters.
final class PlxContinuousMeasurement extends GattValue {
  const PlxContinuousMeasurement({
    required this.spo2,
    required this.pulseRate,
    this.spo2Fast,
    this.pulseRateFast,
    this.spo2Slow,
    this.pulseRateSlow,
    this.measurementStatus,
    this.deviceAndSensorStatus,
    this.pulseAmplitudeIndex,
  });

  factory PlxContinuousMeasurement.parse(List<int> value) {
    final reader = ByteReader(value, 'PLX Continuous Measurement');
    final flags = reader.uint8('flags');
    final spo2 = reader.sfloat('SpO2');
    final pulseRate = reader.sfloat('pulse rate');
    double? spo2Fast, pulseRateFast, spo2Slow, pulseRateSlow;
    if (_has(flags, 0x01)) {
      spo2Fast = reader.sfloat('SpO2 (fast)');
      pulseRateFast = reader.sfloat('pulse rate (fast)');
    }
    if (_has(flags, 0x02)) {
      spo2Slow = reader.sfloat('SpO2 (slow)');
      pulseRateSlow = reader.sfloat('pulse rate (slow)');
    }
    final measurementStatus =
        _has(flags, 0x04) ? reader.uint16('measurement status') : null;
    final deviceStatus =
        _has(flags, 0x08) ? reader.uint24('device and sensor status') : null;
    final amplitude =
        _has(flags, 0x10) ? reader.sfloat('pulse amplitude index') : null;
    return PlxContinuousMeasurement(
      spo2: spo2,
      pulseRate: pulseRate,
      spo2Fast: spo2Fast,
      pulseRateFast: pulseRateFast,
      spo2Slow: spo2Slow,
      pulseRateSlow: pulseRateSlow,
      measurementStatus: measurementStatus,
      deviceAndSensorStatus: deviceStatus,
      pulseAmplitudeIndex: amplitude,
    );
  }

  /// Blood oxygen saturation in percent.
  final double spo2;

  /// Pulse in beats per minute.
  final double pulseRate;
  final double? spo2Fast;
  final double? pulseRateFast;
  final double? spo2Slow;
  final double? pulseRateSlow;

  /// The raw Measurement Status bit field.
  final int? measurementStatus;

  /// The raw Device and Sensor Status bit field.
  final int? deviceAndSensorStatus;

  /// Perfusion index in percent.
  final double? pulseAmplitudeIndex;

  @override
  String toString() => _describe('PlxContinuousMeasurement', {
        'spo2': spo2,
        'pulseRate': pulseRate,
        'spo2Fast': spo2Fast,
        'pulseRateFast': pulseRateFast,
        'spo2Slow': spo2Slow,
        'pulseRateSlow': pulseRateSlow,
        'measurementStatus': measurementStatus,
        'deviceAndSensorStatus': deviceAndSensorStatus,
        'pulseAmplitudeIndex': pulseAmplitudeIndex,
      });
}

/// PLX Spot-check Measurement (0x2A5E), a single reading from a pulse
/// oximeter.
final class PlxSpotCheckMeasurement extends GattValue {
  const PlxSpotCheckMeasurement({
    required this.spo2,
    required this.pulseRate,
    this.timestamp,
    this.measurementStatus,
    this.deviceAndSensorStatus,
    this.pulseAmplitudeIndex,
    this.deviceClockNotSet = false,
  });

  factory PlxSpotCheckMeasurement.parse(List<int> value) {
    final reader = ByteReader(value, 'PLX Spot-check Measurement');
    final flags = reader.uint8('flags');
    final spo2 = reader.sfloat('SpO2');
    final pulseRate = reader.sfloat('pulse rate');
    final timestamp = _has(flags, 0x01) ? reader.dateTime('time stamp') : null;
    final measurementStatus =
        _has(flags, 0x02) ? reader.uint16('measurement status') : null;
    final deviceStatus =
        _has(flags, 0x04) ? reader.uint24('device and sensor status') : null;
    final amplitude =
        _has(flags, 0x08) ? reader.sfloat('pulse amplitude index') : null;
    return PlxSpotCheckMeasurement(
      spo2: spo2,
      pulseRate: pulseRate,
      timestamp: timestamp,
      measurementStatus: measurementStatus,
      deviceAndSensorStatus: deviceStatus,
      pulseAmplitudeIndex: amplitude,
      deviceClockNotSet: _has(flags, 0x10),
    );
  }

  /// Blood oxygen saturation in percent.
  final double spo2;

  /// Pulse in beats per minute.
  final double pulseRate;
  final DateTime? timestamp;

  /// The raw Measurement Status bit field.
  final int? measurementStatus;

  /// The raw Device and Sensor Status bit field.
  final int? deviceAndSensorStatus;

  /// Perfusion index in percent.
  final double? pulseAmplitudeIndex;

  /// Whether the oximeter's clock was never set, so [timestamp] can't be
  /// trusted.
  final bool deviceClockNotSet;

  @override
  String toString() => _describe('PlxSpotCheckMeasurement', {
        'spo2': spo2,
        'pulseRate': pulseRate,
        'timestamp': timestamp,
        'measurementStatus': measurementStatus,
        'deviceAndSensorStatus': deviceAndSensorStatus,
        'pulseAmplitudeIndex': pulseAmplitudeIndex,
        'deviceClockNotSet': deviceClockNotSet ? true : null,
      });
}
