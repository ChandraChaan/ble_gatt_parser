import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:test/test.dart';

// 2026-10-27 09:30:00 as a GATT Date Time.
const _timestamp = [0xEA, 0x07, 0x0A, 0x1B, 0x09, 0x1E, 0x00];
final _time = DateTime(2026, 10, 27, 9, 30);

void main() {
  group('HeartRateMeasurement', () {
    test('reads an 8-bit heart rate', () {
      final hr = HeartRateMeasurement.parse([0x00, 0x48]);
      expect(hr.bpm, 72);
      expect(hr.sensorContact, SensorContact.notSupported);
      expect(hr.energyExpendedKj, isNull);
      expect(hr.rrIntervalsMs, isEmpty);
    });

    test('reads a 16-bit heart rate', () {
      expect(HeartRateMeasurement.parse([0x01, 0x2C, 0x01]).bpm, 300);
    });

    test('reads sensor contact and RR-intervals', () {
      final hr = HeartRateMeasurement.parse(
        [0x16, 0x50, 0x00, 0x04, 0x80, 0x03],
      );
      expect(hr.bpm, 80);
      expect(hr.sensorContact, SensorContact.detected);
      expect(hr.rrIntervalsMs, [1000, 875]);
    });

    test('reports contact supported but not detected', () {
      final hr = HeartRateMeasurement.parse([0x04, 0x48]);
      expect(hr.sensorContact, SensorContact.notDetected);
    });

    test('reads energy expended', () {
      final hr = HeartRateMeasurement.parse([0x08, 0x5A, 0x10, 0x27]);
      expect(hr.bpm, 90);
      expect(hr.energyExpendedKj, 10000);
    });

    test('throws when the value is too short', () {
      expect(
        () => HeartRateMeasurement.parse([0x01, 0x2C]),
        throwsA(isA<GattFormatException>()),
      );
      expect(
        () => HeartRateMeasurement.parse([]),
        throwsA(isA<GattFormatException>()),
      );
    });
  });

  group('TemperatureMeasurement', () {
    test('reads Celsius with time stamp and type', () {
      final t = TemperatureMeasurement.parse(
        [0x06, 0x6C, 0x01, 0x00, 0xFF, ..._timestamp, 0x02],
      );
      expect(t.value, 36.4);
      expect(t.unit, TemperatureUnit.celsius);
      expect(t.timestamp, _time);
      expect(t.type, TemperatureType.body);
      expect(t.fahrenheit, closeTo(97.52, 1e-9));
    });

    test('reads Fahrenheit', () {
      final t = TemperatureMeasurement.parse([0x01, 0xDA, 0x03, 0x00, 0xFF]);
      expect(t.value, 98.6);
      expect(t.unit, TemperatureUnit.fahrenheit);
      expect(t.celsius, closeTo(37, 1e-9));
      expect(t.timestamp, isNull);
      expect(t.type, isNull);
    });

    test('maps unknown types to unknown', () {
      final t = TemperatureMeasurement.parse(
        [0x04, 0x6C, 0x01, 0x00, 0xFF, 0x42],
      );
      expect(t.type, TemperatureType.unknown);
    });

    test('returns a null time stamp when the date is unknown', () {
      final t = TemperatureMeasurement.parse(
        [0x02, 0x6C, 0x01, 0x00, 0xFF, 0, 0, 0, 0, 0, 0, 0],
      );
      expect(t.timestamp, isNull);
    });
  });

  group('BloodPressureMeasurement', () {
    test('reads a minimal mmHg reading', () {
      final bp = BloodPressureMeasurement.parse(
        [0x00, 0x78, 0x00, 0x50, 0x00, 0x5D, 0x00],
      );
      expect(bp.systolic, 120);
      expect(bp.diastolic, 80);
      expect(bp.meanArterialPressure, 93);
      expect(bp.unit, PressureUnit.mmHg);
      expect(bp.pulseRate, isNull);
      expect(bp.status, isNull);
    });

    test('reads every optional field', () {
      final bp = BloodPressureMeasurement.parse([
        0x1E,
        0x78, 0x00, 0x50, 0x00, 0x5D, 0x00, //
        ..._timestamp,
        0x48, 0x00,
        0x01,
        0x0C, 0x00,
      ]);
      expect(bp.timestamp, _time);
      expect(bp.pulseRate, 72);
      expect(bp.userId, 1);
      final status = bp.status!;
      expect(status.irregularPulse, isTrue);
      expect(status.pulseRateRange, PulseRateRange.exceedsUpperLimit);
      expect(status.bodyMovementDetected, isFalse);
      expect(status.cuffTooLoose, isFalse);
      expect(status.improperPosition, isFalse);
    });

    test('reads kPa', () {
      final bp = BloodPressureMeasurement.parse(
        [0x01, 0xA0, 0xF0, 0x6A, 0xF0, 0x7C, 0xF0],
      );
      expect(bp.unit, PressureUnit.kPa);
      expect(bp.systolic, 16);
      expect(bp.diastolic, 10.6);
      expect(bp.meanArterialPressure, 12.4);
    });

    test('reads an Intermediate Cuff Pressure with NaN fields', () {
      final bp = GattParser.parse(
        GattCharacteristics.intermediateCuffPressure,
        [0x00, 0x8C, 0x00, 0xFF, 0x07, 0xFF, 0x07],
      ) as BloodPressureMeasurement;
      expect(bp.systolic, 140);
      expect(bp.diastolic, isNaN);
      expect(bp.meanArterialPressure, isNaN);
    });
  });

  group('WeightMeasurement', () {
    test('reads kilograms', () {
      final w = WeightMeasurement.parse([0x00, 0xB0, 0x36]);
      expect(w.weight, 70);
      expect(w.unit, WeightUnit.kilograms);
      expect(w.kilograms, 70);
    });

    test('reads user, BMI and height', () {
      final w = WeightMeasurement.parse(
        [0x0C, 0xB0, 0x36, 0x02, 0xE5, 0x00, 0xD6, 0x06],
      );
      expect(w.userId, 2);
      expect(w.bmi, 22.9);
      expect(w.height, 1.75);
    });

    test('reads pounds', () {
      final w = WeightMeasurement.parse([0x01, 0x48, 0x3C]);
      expect(w.weight, 154.32);
      expect(w.unit, WeightUnit.pounds);
      expect(w.kilograms, closeTo(70, 0.01));
    });

    test('reports a failed measurement as null', () {
      final w = WeightMeasurement.parse([0x00, 0xFF, 0xFF]);
      expect(w.weight, isNull);
      expect(w.kilograms, isNull);
    });
  });

  group('GlucoseMeasurement', () {
    const baseTime = [0xEA, 0x07, 0x0A, 0x1B, 0x07, 0x00, 0x00];

    test('reads a reading in kg/L', () {
      final g = GlucoseMeasurement.parse(
        [0x03, 0x01, 0x00, ...baseTime, 0x05, 0x00, 0x5F, 0xB0, 0x12],
      );
      expect(g.sequenceNumber, 1);
      expect(g.baseTime, DateTime(2026, 10, 27, 7));
      expect(g.timeOffset, const Duration(minutes: 5));
      expect(g.time, DateTime(2026, 10, 27, 7, 5));
      expect(g.unit, GlucoseUnit.kgPerLiter);
      expect(g.mgPerDl, closeTo(95, 1e-9));
      expect(g.mmolPerL, closeTo(5.27, 0.01));
      expect(g.type, GlucoseType.capillaryPlasma);
      expect(g.sampleLocation, SampleLocation.finger);
      expect(g.hasContext, isFalse);
    });

    test('reads a reading in mol/L', () {
      final g = GlucoseMeasurement.parse(
        [0x06, 0x02, 0x00, ...baseTime, 0x35, 0xC0, 0xF9],
      );
      expect(g.timeOffset, isNull);
      expect(g.time, g.baseTime);
      expect(g.unit, GlucoseUnit.molPerLiter);
      expect(g.mmolPerL, closeTo(5.3, 1e-9));
      expect(g.mgPerDl, closeTo(95.48, 0.01));
      expect(g.type, GlucoseType.interstitialFluid);
      expect(g.sampleLocation, SampleLocation.notAvailable);
    });

    test('reads sensor status and the context flag', () {
      final g = GlucoseMeasurement.parse(
        [0x1A, 0x03, 0x00, ...baseTime, 0x5F, 0xB0, 0x12, 0x01, 0x00],
      );
      expect(g.sensorStatus, 1);
      expect(g.hasContext, isTrue);
    });

    test('allows a reading without a concentration', () {
      final g = GlucoseMeasurement.parse([0x00, 0x04, 0x00, ...baseTime]);
      expect(g.concentration, isNull);
      expect(g.mgPerDl, isNull);
      expect(g.mmolPerL, isNull);
    });
  });

  group('PlxContinuousMeasurement', () {
    test('reads SpO2 and pulse rate', () {
      final plx = PlxContinuousMeasurement.parse(
        [0x00, 0x62, 0x00, 0x40, 0x00],
      );
      expect(plx.spo2, 98);
      expect(plx.pulseRate, 64);
      expect(plx.pulseAmplitudeIndex, isNull);
    });

    test('reads fast, slow, status and perfusion index', () {
      final plx = PlxContinuousMeasurement.parse([
        0x1F,
        0x62, 0x00, 0x40, 0x00, //
        0x61, 0x00, 0x41, 0x00,
        0x63, 0x00, 0x3F, 0x00,
        0x20, 0x00,
        0x01, 0x00, 0x00,
        0x19, 0xF0,
      ]);
      expect(plx.spo2Fast, 97);
      expect(plx.pulseRateFast, 65);
      expect(plx.spo2Slow, 99);
      expect(plx.pulseRateSlow, 63);
      expect(plx.measurementStatus, 0x20);
      expect(plx.deviceAndSensorStatus, 1);
      expect(plx.pulseAmplitudeIndex, 2.5);
    });
  });

  group('PlxSpotCheckMeasurement', () {
    test('reads a reading with time stamp and unset clock', () {
      final plx = PlxSpotCheckMeasurement.parse(
        [0x11, 0x61, 0x00, 0x48, 0x00, ..._timestamp],
      );
      expect(plx.spo2, 97);
      expect(plx.pulseRate, 72);
      expect(plx.timestamp, _time);
      expect(plx.deviceClockNotSet, isTrue);
    });
  });
}
