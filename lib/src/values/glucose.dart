part of '../values.dart';

enum GlucoseUnit { kgPerLiter, molPerLiter }

/// What kind of sample a glucose reading came from.
enum GlucoseType {
  capillaryWholeBlood,
  capillaryPlasma,
  venousWholeBlood,
  venousPlasma,
  arterialWholeBlood,
  arterialPlasma,
  undeterminedWholeBlood,
  undeterminedPlasma,
  interstitialFluid,
  controlSolution,
  unknown;

  static GlucoseType _fromCode(int code) =>
      code >= 1 && code <= 10 ? values[code - 1] : unknown;
}

/// Where on the body a glucose sample was taken.
enum SampleLocation {
  finger,
  alternateSiteTest,
  earlobe,
  controlSolution,
  notAvailable,
  unknown;

  static SampleLocation _fromCode(int code) => switch (code) {
        >= 1 && <= 4 => values[code - 1],
        15 => notAvailable,
        _ => unknown,
      };
}

/// Glucose Measurement (0x2A18), sent by blood glucose meters.
final class GlucoseMeasurement extends GattValue {
  const GlucoseMeasurement({
    required this.sequenceNumber,
    required this.baseTime,
    this.timeOffset,
    this.concentration,
    this.unit = GlucoseUnit.kgPerLiter,
    this.type,
    this.sampleLocation,
    this.sensorStatus,
    this.hasContext = false,
  });

  factory GlucoseMeasurement.parse(List<int> value) {
    final reader = ByteReader(value, 'Glucose Measurement');
    final flags = reader.uint8('flags');
    final sequenceNumber = reader.uint16('sequence number');
    final baseTime = reader.dateTime('base time');
    final offset = _has(flags, 0x01)
        ? Duration(minutes: reader.sint16('time offset'))
        : null;
    double? concentration;
    GlucoseType? type;
    SampleLocation? location;
    if (_has(flags, 0x02)) {
      concentration = reader.sfloat('glucose concentration');
      final typeAndLocation = reader.uint8('type-sample location');
      type = GlucoseType._fromCode(typeAndLocation & 0x0F);
      location = SampleLocation._fromCode(typeAndLocation >> 4);
    }
    final sensorStatus =
        _has(flags, 0x08) ? reader.uint16('sensor status annunciation') : null;
    return GlucoseMeasurement(
      sequenceNumber: sequenceNumber,
      baseTime: baseTime,
      timeOffset: offset,
      concentration: concentration,
      unit:
          _has(flags, 0x04) ? GlucoseUnit.molPerLiter : GlucoseUnit.kgPerLiter,
      type: type,
      sampleLocation: location,
      sensorStatus: sensorStatus,
      hasContext: _has(flags, 0x10),
    );
  }

  /// Increases by one with each reading. Use it to match a Glucose
  /// Measurement Context (0x2A34) to its reading.
  final int sequenceNumber;
  final DateTime? baseTime;
  final Duration? timeOffset;

  /// The concentration in [unit].
  final double? concentration;
  final GlucoseUnit unit;
  final GlucoseType? type;
  final SampleLocation? sampleLocation;

  /// The raw Sensor Status Annunciation bit field, if the meter sent one.
  final int? sensorStatus;

  /// Whether a Glucose Measurement Context notification follows.
  final bool hasContext;

  /// When the reading was taken: [baseTime] plus [timeOffset].
  DateTime? get time => baseTime?.add(timeOffset ?? Duration.zero);

  /// The concentration in mg/dL, the unit used in the US and India.
  double? get mgPerDl => switch (concentration) {
        null => null,
        final c when unit == GlucoseUnit.kgPerLiter => c * 100000,
        final c => c * 1000 * _mgPerDlPerMmol,
      };

  /// The concentration in mmol/L, the unit used in the UK, Canada and
  /// Australia.
  double? get mmolPerL => switch (concentration) {
        null => null,
        final c when unit == GlucoseUnit.molPerLiter => c * 1000,
        final c => c * 100000 / _mgPerDlPerMmol,
      };

  // Glucose has a molar mass of 180.156 g/mol.
  static const _mgPerDlPerMmol = 18.0156;

  @override
  String toString() => _describe('GlucoseMeasurement', {
        'sequenceNumber': sequenceNumber,
        'time': time,
        'concentration': concentration,
        'unit': concentration == null ? null : unit.name,
        'type': type?.name,
        'sampleLocation': sampleLocation?.name,
        'sensorStatus': sensorStatus,
        'hasContext': hasContext ? true : null,
      });
}
