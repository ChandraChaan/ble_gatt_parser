import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:test/test.dart';

void main() {
  group('CscMeasurement', () {
    test('reads wheel and crank data', () {
      final csc = CscMeasurement.parse(
        [0x03, 0xE8, 0x03, 0x00, 0x00, 0x00, 0x08, 0x32, 0x00, 0x00, 0x04],
      );
      expect(csc.wheelRevolutions, 1000);
      expect(csc.lastWheelEventTime, 2048);
      expect(csc.crankRevolutions, 50);
      expect(csc.lastCrankEventTime, 1024);
    });

    test('reads crank data only', () {
      final csc = CscMeasurement.parse([0x02, 0x32, 0x00, 0x00, 0x04]);
      expect(csc.wheelRevolutions, isNull);
      expect(csc.crankRevolutions, 50);
    });

    test('calculates cadence and speed', () {
      const previous = CscMeasurement(
        wheelRevolutions: 1000,
        lastWheelEventTime: 1024,
        crankRevolutions: 50,
        lastCrankEventTime: 1024,
      );
      const current = CscMeasurement(
        wheelRevolutions: 1002,
        lastWheelEventTime: 2048,
        crankRevolutions: 51,
        lastCrankEventTime: 2048,
      );
      expect(current.cadenceSince(previous), 60);
      expect(
        current.speedSince(previous, wheelCircumferenceM: 2.1),
        closeTo(4.2, 1e-9),
      );
    });

    test('handles counters wrapping around', () {
      const previous = CscMeasurement(
        wheelRevolutions: 0xFFFFFFFF,
        lastWheelEventTime: 65000,
        crankRevolutions: 0xFFFF,
        lastCrankEventTime: 65000,
      );
      const current = CscMeasurement(
        wheelRevolutions: 1,
        lastWheelEventTime: 488,
        crankRevolutions: 1,
        lastCrankEventTime: 488,
      );
      expect(current.cadenceSince(previous), 120);
      expect(
        current.speedSince(previous, wheelCircumferenceM: 2),
        closeTo(4, 1e-9),
      );
    });

    test('returns null when there is no new event', () {
      const measurement = CscMeasurement(
        crankRevolutions: 50,
        lastCrankEventTime: 1024,
      );
      expect(measurement.cadenceSince(measurement), isNull);
      expect(
        measurement.speedSince(measurement, wheelCircumferenceM: 2),
        isNull,
      );
    });
  });

  group('CyclingPowerMeasurement', () {
    test('reads power only', () {
      final cp = CyclingPowerMeasurement.parse([0x00, 0x00, 0xFA, 0x00]);
      expect(cp.powerWatts, 250);
      expect(cp.pedalPowerBalancePercent, isNull);
      expect(cp.crankRevolutions, isNull);
    });

    test('reads negative power', () {
      final cp = CyclingPowerMeasurement.parse([0x00, 0x00, 0xFB, 0xFF]);
      expect(cp.powerWatts, -5);
    });

    test('reads pedal balance and crank data', () {
      final cp = CyclingPowerMeasurement.parse(
        [0x23, 0x00, 0xFA, 0x00, 0x64, 0x0A, 0x00, 0x00, 0x04],
      );
      expect(cp.pedalPowerBalancePercent, 50);
      expect(cp.pedalPowerBalanceIsLeft, isTrue);
      expect(cp.crankRevolutions, 10);
      expect(cp.lastCrankEventTime, 1024);
    });

    test('reads extreme angles and accumulated energy', () {
      final cp = CyclingPowerMeasurement.parse(
        [0x00, 0x09, 0xFA, 0x00, 0x5A, 0xE0, 0x10, 0x64, 0x00],
      );
      expect(cp.maxAngleDeg, 90);
      expect(cp.minAngleDeg, 270);
      expect(cp.accumulatedEnergyKj, 100);
    });

    test('reads every field in order', () {
      final cp = CyclingPowerMeasurement.parse([
        0xFD, 0x1F, // every flag except the balance reference
        0xFA, 0x00,
        0x64,
        0x40, 0x00,
        0xE8, 0x03, 0x00, 0x00, 0x00, 0x10,
        0x0A, 0x00, 0x00, 0x04,
        0xC8, 0x00, 0x9C, 0xFF,
        0x80, 0x00, 0xE0, 0xFF,
        0x5A, 0xE0, 0x10,
        0x0A, 0x00,
        0xC8, 0x00,
        0x64, 0x00,
      ]);
      expect(cp.powerWatts, 250);
      expect(cp.pedalPowerBalancePercent, 50);
      expect(cp.pedalPowerBalanceIsLeft, isFalse);
      expect(cp.accumulatedTorqueNm, 2);
      expect(cp.accumulatedTorqueFromCrank, isTrue);
      expect(cp.wheelRevolutions, 1000);
      expect(cp.lastWheelEventTime, 4096);
      expect(cp.crankRevolutions, 10);
      expect(cp.lastCrankEventTime, 1024);
      expect(cp.maxForceN, 200);
      expect(cp.minForceN, -100);
      expect(cp.maxTorqueNm, 4);
      expect(cp.minTorqueNm, -1);
      expect(cp.maxAngleDeg, 90);
      expect(cp.minAngleDeg, 270);
      expect(cp.topDeadSpotAngleDeg, 10);
      expect(cp.bottomDeadSpotAngleDeg, 200);
      expect(cp.accumulatedEnergyKj, 100);
      expect(cp.offsetCompensationIndicator, isTrue);
    });

    test('calculates cadence', () {
      const previous = CyclingPowerMeasurement(
        powerWatts: 200,
        crankRevolutions: 10,
        lastCrankEventTime: 0,
      );
      const current = CyclingPowerMeasurement(
        powerWatts: 210,
        crankRevolutions: 12,
        lastCrankEventTime: 1536,
      );
      expect(current.cadenceSince(previous), 80);
    });
  });

  group('RscMeasurement', () {
    test('reads every field', () {
      final rsc = RscMeasurement.parse(
        [0x07, 0x80, 0x03, 0xAA, 0x7D, 0x00, 0x50, 0xC3, 0x00, 0x00],
      );
      expect(rsc.speedMps, 3.5);
      expect(rsc.speedKmh, closeTo(12.6, 1e-9));
      expect(rsc.cadence, 170);
      expect(rsc.strideLengthM, 1.25);
      expect(rsc.totalDistanceM, 5000);
      expect(rsc.isRunning, isTrue);
      expect(rsc.pacePerKm!.inSeconds, 285);
    });

    test('reads a minimal walking reading', () {
      final rsc = RscMeasurement.parse([0x00, 0x00, 0x01, 0x64]);
      expect(rsc.speedMps, 1);
      expect(rsc.cadence, 100);
      expect(rsc.strideLengthM, isNull);
      expect(rsc.totalDistanceM, isNull);
      expect(rsc.isRunning, isFalse);
    });

    test('has no pace when standing still', () {
      final rsc = RscMeasurement.parse([0x00, 0x00, 0x00, 0x00]);
      expect(rsc.pacePerKm, isNull);
    });
  });
}
