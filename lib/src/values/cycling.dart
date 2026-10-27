part of '../values.dart';

// Revolution counters and event times wrap around. `%` keeps the
// difference correct across a wrap on every platform, including the web.
const _uint16Range = 0x10000;
const _uint32Range = 0x100000000;

double? _revolutionsPerMinute(
  int? revolutions,
  int? eventTime,
  int? previousRevolutions,
  int? previousEventTime,
  int ticksPerSecond,
) {
  if (revolutions == null ||
      eventTime == null ||
      previousRevolutions == null ||
      previousEventTime == null) {
    return null;
  }
  final ticks = (eventTime - previousEventTime) % _uint16Range;
  if (ticks == 0) return null;
  final revs = (revolutions - previousRevolutions) % _uint16Range;
  return revs * 60 * ticksPerSecond / ticks;
}

/// Cycling Speed and Cadence Measurement (0x2A5B), sent by wheel and crank
/// sensors.
///
/// Each notification carries running totals. Use [cadenceSince] and
/// [speedSince] with the previous notification to get cadence and speed.
final class CscMeasurement extends GattValue {
  const CscMeasurement({
    this.wheelRevolutions,
    this.lastWheelEventTime,
    this.crankRevolutions,
    this.lastCrankEventTime,
  });

  factory CscMeasurement.parse(List<int> value) {
    final reader = ByteReader(value, 'CSC Measurement');
    final flags = reader.uint8('flags');
    int? wheelRevolutions, wheelTime, crankRevolutions, crankTime;
    if (_has(flags, 0x01)) {
      wheelRevolutions = reader.uint32('cumulative wheel revolutions');
      wheelTime = reader.uint16('last wheel event time');
    }
    if (_has(flags, 0x02)) {
      crankRevolutions = reader.uint16('cumulative crank revolutions');
      crankTime = reader.uint16('last crank event time');
    }
    return CscMeasurement(
      wheelRevolutions: wheelRevolutions,
      lastWheelEventTime: wheelTime,
      crankRevolutions: crankRevolutions,
      lastCrankEventTime: crankTime,
    );
  }

  final int? wheelRevolutions;

  /// In 1/1024ths of a second. Wraps around every 64 seconds.
  final int? lastWheelEventTime;
  final int? crankRevolutions;

  /// In 1/1024ths of a second. Wraps around every 64 seconds.
  final int? lastCrankEventTime;

  /// Pedalling cadence in RPM since [previous], or null if there was no
  /// new crank event in between.
  double? cadenceSince(CscMeasurement previous) => _revolutionsPerMinute(
        crankRevolutions,
        lastCrankEventTime,
        previous.crankRevolutions,
        previous.lastCrankEventTime,
        1024,
      );

  /// Speed in meters per second since [previous], or null if there was no
  /// new wheel event in between.
  ///
  /// A 700x25c road wheel is about 2.105 m around.
  double? speedSince(
    CscMeasurement previous, {
    required double wheelCircumferenceM,
  }) {
    final revolutions = wheelRevolutions;
    final time = lastWheelEventTime;
    final previousRevolutions = previous.wheelRevolutions;
    final previousTime = previous.lastWheelEventTime;
    if (revolutions == null ||
        time == null ||
        previousRevolutions == null ||
        previousTime == null) {
      return null;
    }
    final ticks = (time - previousTime) % _uint16Range;
    if (ticks == 0) return null;
    final revs = (revolutions - previousRevolutions) % _uint32Range;
    return revs * wheelCircumferenceM * 1024 / ticks;
  }

  @override
  String toString() => _describe('CscMeasurement', {
        'wheelRevolutions': wheelRevolutions,
        'lastWheelEventTime': lastWheelEventTime,
        'crankRevolutions': crankRevolutions,
        'lastCrankEventTime': lastCrankEventTime,
      });
}

/// Cycling Power Measurement (0x2A63), sent by power meters and smart
/// trainers.
final class CyclingPowerMeasurement extends GattValue {
  const CyclingPowerMeasurement({
    required this.powerWatts,
    this.pedalPowerBalancePercent,
    this.pedalPowerBalanceIsLeft = false,
    this.accumulatedTorqueNm,
    this.accumulatedTorqueFromCrank = false,
    this.wheelRevolutions,
    this.lastWheelEventTime,
    this.crankRevolutions,
    this.lastCrankEventTime,
    this.maxForceN,
    this.minForceN,
    this.maxTorqueNm,
    this.minTorqueNm,
    this.maxAngleDeg,
    this.minAngleDeg,
    this.topDeadSpotAngleDeg,
    this.bottomDeadSpotAngleDeg,
    this.accumulatedEnergyKj,
    this.offsetCompensationIndicator = false,
  });

  factory CyclingPowerMeasurement.parse(List<int> value) {
    final reader = ByteReader(value, 'Cycling Power Measurement');
    final flags = reader.uint16('flags');
    final power = reader.sint16('instantaneous power');
    final balance =
        _has(flags, 0x0001) ? reader.uint8('pedal power balance') / 2 : null;
    final torque =
        _has(flags, 0x0004) ? reader.uint16('accumulated torque') / 32 : null;
    int? wheelRevolutions, wheelTime, crankRevolutions, crankTime;
    if (_has(flags, 0x0010)) {
      wheelRevolutions = reader.uint32('cumulative wheel revolutions');
      wheelTime = reader.uint16('last wheel event time');
    }
    if (_has(flags, 0x0020)) {
      crankRevolutions = reader.uint16('cumulative crank revolutions');
      crankTime = reader.uint16('last crank event time');
    }
    int? maxForce, minForce;
    if (_has(flags, 0x0040)) {
      maxForce = reader.sint16('maximum force magnitude');
      minForce = reader.sint16('minimum force magnitude');
    }
    double? maxTorque, minTorque;
    if (_has(flags, 0x0080)) {
      maxTorque = reader.sint16('maximum torque magnitude') / 32;
      minTorque = reader.sint16('minimum torque magnitude') / 32;
    }
    int? maxAngle, minAngle;
    if (_has(flags, 0x0100)) {
      // Two 12-bit angles packed into three bytes.
      final angles = reader.uint24('extreme angles');
      maxAngle = angles & 0xFFF;
      minAngle = (angles >> 12) & 0xFFF;
    }
    final topDeadSpot =
        _has(flags, 0x0200) ? reader.uint16('top dead spot angle') : null;
    final bottomDeadSpot =
        _has(flags, 0x0400) ? reader.uint16('bottom dead spot angle') : null;
    final energy =
        _has(flags, 0x0800) ? reader.uint16('accumulated energy') : null;
    return CyclingPowerMeasurement(
      powerWatts: power,
      pedalPowerBalancePercent: balance,
      pedalPowerBalanceIsLeft: _has(flags, 0x0002),
      accumulatedTorqueNm: torque,
      accumulatedTorqueFromCrank: _has(flags, 0x0008),
      wheelRevolutions: wheelRevolutions,
      lastWheelEventTime: wheelTime,
      crankRevolutions: crankRevolutions,
      lastCrankEventTime: crankTime,
      maxForceN: maxForce,
      minForceN: minForce,
      maxTorqueNm: maxTorque,
      minTorqueNm: minTorque,
      maxAngleDeg: maxAngle,
      minAngleDeg: minAngle,
      topDeadSpotAngleDeg: topDeadSpot,
      bottomDeadSpotAngleDeg: bottomDeadSpot,
      accumulatedEnergyKj: energy,
      offsetCompensationIndicator: _has(flags, 0x1000),
    );
  }

  /// Instantaneous power in watts.
  final int powerWatts;

  /// Share of power from one pedal, in percent. See
  /// [pedalPowerBalanceIsLeft] for which one.
  final double? pedalPowerBalancePercent;

  /// Whether [pedalPowerBalancePercent] is the left pedal's share. When
  /// false, the device doesn't say which pedal it is.
  final bool pedalPowerBalanceIsLeft;
  final double? accumulatedTorqueNm;

  /// Whether [accumulatedTorqueNm] is measured at the crank rather than
  /// the wheel.
  final bool accumulatedTorqueFromCrank;
  final int? wheelRevolutions;

  /// In 1/2048ths of a second (not 1/1024 as in [CscMeasurement]).
  final int? lastWheelEventTime;
  final int? crankRevolutions;

  /// In 1/1024ths of a second.
  final int? lastCrankEventTime;
  final int? maxForceN;
  final int? minForceN;
  final double? maxTorqueNm;
  final double? minTorqueNm;
  final int? maxAngleDeg;
  final int? minAngleDeg;
  final int? topDeadSpotAngleDeg;
  final int? bottomDeadSpotAngleDeg;
  final int? accumulatedEnergyKj;
  final bool offsetCompensationIndicator;

  /// Pedalling cadence in RPM since [previous], or null if there was no
  /// new crank event in between.
  double? cadenceSince(CyclingPowerMeasurement previous) =>
      _revolutionsPerMinute(
        crankRevolutions,
        lastCrankEventTime,
        previous.crankRevolutions,
        previous.lastCrankEventTime,
        1024,
      );

  @override
  String toString() => _describe('CyclingPowerMeasurement', {
        'powerWatts': powerWatts,
        'pedalPowerBalancePercent': pedalPowerBalancePercent,
        'pedalPowerBalanceIsLeft':
            pedalPowerBalancePercent == null ? null : pedalPowerBalanceIsLeft,
        'accumulatedTorqueNm': accumulatedTorqueNm,
        'wheelRevolutions': wheelRevolutions,
        'lastWheelEventTime': lastWheelEventTime,
        'crankRevolutions': crankRevolutions,
        'lastCrankEventTime': lastCrankEventTime,
        'maxForceN': maxForceN,
        'minForceN': minForceN,
        'maxTorqueNm': maxTorqueNm,
        'minTorqueNm': minTorqueNm,
        'maxAngleDeg': maxAngleDeg,
        'minAngleDeg': minAngleDeg,
        'topDeadSpotAngleDeg': topDeadSpotAngleDeg,
        'bottomDeadSpotAngleDeg': bottomDeadSpotAngleDeg,
        'accumulatedEnergyKj': accumulatedEnergyKj,
      });
}
