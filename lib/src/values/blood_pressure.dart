part of '../values.dart';

enum PressureUnit { mmHg, kPa }

enum PulseRateRange {
  withinRange,
  exceedsUpperLimit,
  belowLowerLimit,
  reserved
}

/// Problems a blood pressure monitor noticed while measuring.
final class BloodPressureStatus {
  const BloodPressureStatus(this.raw);

  /// The 16-bit Measurement Status field as sent by the device.
  final int raw;

  bool get bodyMovementDetected => _has(raw, 0x01);
  bool get cuffTooLoose => _has(raw, 0x02);
  bool get irregularPulse => _has(raw, 0x04);
  PulseRateRange get pulseRateRange => PulseRateRange.values[(raw >> 3) & 0x03];
  bool get improperPosition => _has(raw, 0x20);

  @override
  String toString() {
    final problems = [
      if (bodyMovementDetected) 'bodyMovementDetected',
      if (cuffTooLoose) 'cuffTooLoose',
      if (irregularPulse) 'irregularPulse',
      if (pulseRateRange != PulseRateRange.withinRange) pulseRateRange.name,
      if (improperPosition) 'improperPosition',
    ];
    return 'BloodPressureStatus(${problems.join(', ')})';
  }
}

/// Blood Pressure Measurement (0x2A35) or Intermediate Cuff Pressure
/// (0x2A36), sent by blood pressure monitors.
///
/// For Intermediate Cuff Pressure, [systolic] holds the current cuff
/// pressure and [diastolic] and [meanArterialPressure] are NaN.
final class BloodPressureMeasurement extends GattValue {
  const BloodPressureMeasurement({
    required this.systolic,
    required this.diastolic,
    required this.meanArterialPressure,
    required this.unit,
    this.timestamp,
    this.pulseRate,
    this.userId,
    this.status,
  });

  factory BloodPressureMeasurement.parse(List<int> value) {
    final reader = ByteReader(value, 'Blood Pressure Measurement');
    final flags = reader.uint8('flags');
    final systolic = reader.sfloat('systolic');
    final diastolic = reader.sfloat('diastolic');
    final meanArterial = reader.sfloat('mean arterial pressure');
    final timestamp = _has(flags, 0x02) ? reader.dateTime('time stamp') : null;
    final pulseRate = _has(flags, 0x04) ? reader.sfloat('pulse rate') : null;
    final userId = _has(flags, 0x08) ? reader.uint8('user ID') : null;
    final status = _has(flags, 0x10)
        ? BloodPressureStatus(reader.uint16('measurement status'))
        : null;
    return BloodPressureMeasurement(
      systolic: systolic,
      diastolic: diastolic,
      meanArterialPressure: meanArterial,
      unit: _has(flags, 0x01) ? PressureUnit.kPa : PressureUnit.mmHg,
      timestamp: timestamp,
      pulseRate: pulseRate,
      userId: userId,
      status: status,
    );
  }

  final double systolic;
  final double diastolic;
  final double meanArterialPressure;
  final PressureUnit unit;
  final DateTime? timestamp;

  /// Pulse in beats per minute.
  final double? pulseRate;

  /// Which user on a shared monitor took the reading. 255 means unknown.
  final int? userId;
  final BloodPressureStatus? status;

  @override
  String toString() => _describe('BloodPressureMeasurement', {
        'systolic': systolic,
        'diastolic': diastolic,
        'meanArterialPressure': meanArterialPressure,
        'unit': unit.name,
        'timestamp': timestamp,
        'pulseRate': pulseRate,
        'userId': userId,
        'status': status,
      });
}
