import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:test/test.dart';

/// Stands in for a plugin's UUID class, such as flutter_blue_plus's Guid.
class _FakeGuid {
  const _FakeGuid(this.text);
  final String text;

  @override
  String toString() => text;
}

void main() {
  group('GattCharacteristics.shortUuid', () {
    test('accepts every UUID form', () {
      for (final form in <Object>[
        0x2A37,
        '2a37',
        '2A37',
        '0x2A37',
        '00002a37',
        '00002a37-0000-1000-8000-00805f9b34fb',
        '00002A37-0000-1000-8000-00805F9B34FB',
        const _FakeGuid('00002a37-0000-1000-8000-00805f9b34fb'),
      ]) {
        expect(GattCharacteristics.shortUuid(form), 0x2A37, reason: '$form');
      }
    });

    test('rejects custom and malformed UUIDs', () {
      for (final form in <Object>[
        '6e400003-b5a3-f393-e0a9-e50e24dcca9e',
        'heart rate',
        '',
        0x12345,
        -1,
      ]) {
        expect(GattCharacteristics.shortUuid(form), isNull, reason: '$form');
      }
    });
  });

  group('GattParser', () {
    test('dispatches by UUID', () {
      expect(
        GattParser.parse('2a37', [0x00, 0x48]),
        isA<HeartRateMeasurement>().having((hr) => hr.bpm, 'bpm', 72),
      );
      expect(
        GattParser.parse(GattCharacteristics.batteryLevel, [0x55]),
        isA<BatteryLevel>().having((b) => b.percent, 'percent', 85),
      );
      expect(
        GattParser.parse('2a38', [0x01]),
        isA<BodySensorLocation>()
            .having((l) => l.location, 'location', SensorLocation.chest),
      );
      expect(
        GattParser.parse('0x2A1E', [0x00, 0x6C, 0x01, 0x00, 0xFF]),
        isA<TemperatureMeasurement>(),
      );
    });

    test('decodes text characteristics', () {
      final name = GattParser.parse(
        GattCharacteristics.manufacturerName,
        [0x41, 0x43, 0x4D, 0x45, 0x00, 0x00],
      );
      expect(
        name,
        isA<GattString>()
            .having((s) => s.value, 'value', 'ACME')
            .having((s) => s.uuid, 'uuid', 0x2A29),
      );
      expect((GattParser.parse('2a00', []) as GattString).value, '');
    });

    test('supports reports what it can parse', () {
      expect(GattParser.supports('2a37'), isTrue);
      expect(
          GattParser.supports(GattCharacteristics.weightMeasurement), isTrue);
      expect(GattParser.supports('2a34'), isFalse);
      expect(
        GattParser.supports('6e400003-b5a3-f393-e0a9-e50e24dcca9e'),
        isFalse,
      );
    });

    test('parse throws for unsupported characteristics', () {
      expect(() => GattParser.parse('2a34', [0]), throwsArgumentError);
    });

    test('tryParse returns null instead of throwing', () {
      expect(GattParser.tryParse('2a34', [0]), isNull);
      expect(GattParser.tryParse('2a37', []), isNull);
      expect(GattParser.tryParse('2a37', [0x00, 0x48]), isNotNull);
    });

    test('maps out-of-range enum codes to unknown', () {
      final location = GattParser.parse('2a38', [0x09]) as BodySensorLocation;
      expect(location.location, SensorLocation.unknown);
    });

    test('values describe themselves', () {
      expect(
        // A fractional interval prints the same on the VM and the web.
        GattParser.parse('2a37', [0x10, 0x48, 0x01, 0x00]).toString(),
        'HeartRateMeasurement(bpm: 72, sensorContact: notSupported, '
        'rrIntervalsMs: [0.9765625])',
      );
      expect(BatteryLevel.parse([0x55]).toString(), 'BatteryLevel(85%)');
    });

    test('sealed values can be switched over', () {
      String describe(GattValue value) => switch (value) {
            HeartRateMeasurement(:final bpm) => '$bpm bpm',
            BatteryLevel(:final percent) => '$percent%',
            _ => 'other',
          };
      expect(describe(GattParser.parse('2a37', [0x00, 0x48])), '72 bpm');
      expect(describe(GattParser.parse('2a19', [0x55])), '85%');
    });
  });
}
