import 'package:ble_gatt_parser/ble_gatt_parser.dart';

/// Parses a few notifications the way you would inside a BLE plugin's
/// `onValueReceived` or `subscribeToCharacteristic` callback.
void main() {
  final notifications = <(String, List<int>)>[
    // A chest strap: 80 bpm, skin contact, two RR-intervals.
    ('2a37', [0x16, 0x50, 0x00, 0x04, 0x80, 0x03]),
    // A blood pressure cuff: 120/80 mmHg, pulse 72.
    ('2a35', [0x04, 0x78, 0x00, 0x50, 0x00, 0x5D, 0x00, 0x48, 0x00]),
    // A thermometer: 36.4 °C.
    ('2a1c', [0x00, 0x6C, 0x01, 0x00, 0xFF]),
    // A pulse oximeter: SpO2 98%, pulse 64.
    ('2a5f', [0x00, 0x62, 0x00, 0x40, 0x00]),
    // A battery at 85%.
    ('2a19', [0x55]),
  ];

  for (final (uuid, bytes) in notifications) {
    final value = GattParser.tryParse(uuid, bytes);
    final description = switch (value) {
      HeartRateMeasurement(:final bpm, :final rrIntervalsMs) =>
        'Heart rate $bpm bpm, RR $rrIntervalsMs ms',
      BloodPressureMeasurement(:final systolic, :final diastolic) =>
        'Blood pressure ${systolic.round()}/${diastolic.round()}',
      TemperatureMeasurement(:final celsius) => 'Temperature $celsius °C',
      PlxContinuousMeasurement(:final spo2) => 'SpO2 ${spo2.round()}%',
      BatteryLevel(:final percent) => 'Battery $percent%',
      null => 'Could not parse $uuid',
      _ => value.toString(),
    };
    print(description);
  }
}
