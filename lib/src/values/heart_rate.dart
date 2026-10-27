part of '../values.dart';

/// Whether a heart-rate sensor reports skin contact.
enum SensorContact { notSupported, notDetected, detected }

/// Heart Rate Measurement (0x2A37), sent by chest straps, watches and
/// armbands.
final class HeartRateMeasurement extends GattValue {
  const HeartRateMeasurement({
    required this.bpm,
    this.sensorContact = SensorContact.notSupported,
    this.energyExpendedKj,
    this.rrIntervalsMs = const [],
  });

  factory HeartRateMeasurement.parse(List<int> value) {
    final reader = ByteReader(value, 'Heart Rate Measurement');
    final flags = reader.uint8('flags');
    final bpm = _has(flags, 0x01)
        ? reader.uint16('heart rate')
        : reader.uint8('heart rate');
    final contact = !_has(flags, 0x04)
        ? SensorContact.notSupported
        : _has(flags, 0x02)
            ? SensorContact.detected
            : SensorContact.notDetected;
    final energy = _has(flags, 0x08) ? reader.uint16('energy expended') : null;
    final rrIntervals = <double>[];
    if (_has(flags, 0x10)) {
      while (reader.remaining >= 2) {
        rrIntervals.add(reader.uint16('RR-interval') * 1000 / 1024);
      }
    }
    return HeartRateMeasurement(
      bpm: bpm,
      sensorContact: contact,
      energyExpendedKj: energy,
      rrIntervalsMs: List.unmodifiable(rrIntervals),
    );
  }

  /// Heart rate in beats per minute.
  final int bpm;

  final SensorContact sensorContact;

  /// Energy expended since the sensor was last reset, in kilojoules.
  final int? energyExpendedKj;

  /// Beat-to-beat (RR) intervals in milliseconds, oldest first. These are
  /// what heart-rate variability (HRV) is calculated from.
  final List<double> rrIntervalsMs;

  @override
  String toString() => _describe('HeartRateMeasurement', {
        'bpm': bpm,
        'sensorContact': sensorContact.name,
        'energyExpendedKj': energyExpendedKj,
        'rrIntervalsMs': rrIntervalsMs.isEmpty ? null : rrIntervalsMs,
      });
}
