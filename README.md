# ble_gatt_parser

[![pub package](https://img.shields.io/pub/v/ble_gatt_parser.svg)](https://pub.dev/packages/ble_gatt_parser)
[![CI](https://github.com/ChandraChaan/ble_gatt_parser/actions/workflows/ci.yml/badge.svg)](https://github.com/ChandraChaan/ble_gatt_parser/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Turn the raw bytes from Bluetooth heart-rate straps, blood pressure cuffs, thermometers, scales, glucose meters, pulse oximeters and cycling or running sensors into typed Dart objects.

Your BLE plugin hands you a `List<int>`. This package tells you what it means.

```dart
final value = GattParser.parse('2a37', [0x16, 0x50, 0x00, 0x04, 0x80, 0x03]);
// HeartRateMeasurement(bpm: 80, sensorContact: detected, rrIntervalsMs: [1000.0, 875.0])
```

- **Works with any BLE plugin**: flutter_blue_plus, flutter_reactive_ble, universal_ble, or your own platform channels
- **Pure Dart**: no native code, so it runs on Android, iOS, web, desktop and the server
- **No dependencies**
- **Follows the Bluetooth SIG specs**: every optional field, flag, unit and IEEE 11073 SFLOAT/FLOAT special value
- **Type-safe**: results are a sealed class, so a `switch` can handle every case

## Supported characteristics

| Characteristic | UUID | Devices | Result |
|---|---|---|---|
| Heart Rate Measurement | `2A37` | Chest straps, watches | `HeartRateMeasurement` (bpm, RR-intervals for HRV, energy, skin contact) |
| Body Sensor Location | `2A38` | Heart-rate sensors | `BodySensorLocation` |
| Blood Pressure Measurement | `2A35` | BP monitors | `BloodPressureMeasurement` (systolic, diastolic, MAP, pulse, status flags) |
| Intermediate Cuff Pressure | `2A36` | BP monitors | `BloodPressureMeasurement` |
| Temperature Measurement | `2A1C` | Thermometers | `TemperatureMeasurement` (°C/°F, body site) |
| Intermediate Temperature | `2A1E` | Thermometers | `TemperatureMeasurement` |
| Weight Measurement | `2A9D` | Smart scales | `WeightMeasurement` (kg/lb, BMI, height, user) |
| Glucose Measurement | `2A18` | Glucose meters | `GlucoseMeasurement` (mg/dL and mmol/L, sample type and site) |
| PLX Continuous Measurement | `2A5F` | Pulse oximeters | `PlxContinuousMeasurement` (SpO2, pulse, perfusion index) |
| PLX Spot-check Measurement | `2A5E` | Pulse oximeters | `PlxSpotCheckMeasurement` |
| Cycling Speed and Cadence | `2A5B` | Wheel and crank sensors | `CscMeasurement` (with speed and cadence helpers) |
| Cycling Power Measurement | `2A63` | Power meters, smart trainers | `CyclingPowerMeasurement` (all 13 optional fields) |
| RSC Measurement | `2A53` | Running foot pods | `RscMeasurement` (speed, pace, cadence, stride, distance) |
| Battery Level | `2A19` | Almost everything | `BatteryLevel` |
| Device Name and Device Information strings | `2A00`, `2A24`–`2A29` | Almost everything | `GattString` |

## Install

```bash
dart pub add ble_gatt_parser
```

## Usage

### With flutter_blue_plus

```dart
import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

Future<void> listen(BluetoothCharacteristic characteristic) async {
  characteristic.onValueReceived.listen((bytes) {
    final value = GattParser.tryParse(characteristic.uuid, bytes);
    if (value is HeartRateMeasurement) {
      print('${value.bpm} bpm');
    }
  });
  await characteristic.setNotifyValue(true);
}
```

### With flutter_reactive_ble

```dart
ble.subscribeToCharacteristic(characteristic).listen((bytes) {
  switch (GattParser.tryParse(characteristic.characteristicId, bytes)) {
    case BloodPressureMeasurement(:final systolic, :final diastolic):
      print('$systolic/$diastolic');
    case _:
      break;
  }
});
```

`GattParser` accepts the UUID as an int (`0x2A37`), a short string (`'2a37'`), a full 128-bit string, or your plugin's UUID object.

### Parse one characteristic directly

If you already know what you're reading, call its `parse` constructor:

```dart
final bp = BloodPressureMeasurement.parse(bytes);
if (bp.status?.irregularPulse ?? false) {
  showWarning('Irregular heartbeat detected');
}
```

### Cadence and speed from cycling sensors

Cycling sensors send running totals that wrap around. Compare two notifications to get live numbers, and the wrap-around is handled for you:

```dart
CscMeasurement? previous;

void onCsc(List<int> bytes) {
  final current = CscMeasurement.parse(bytes);
  if (previous != null) {
    final rpm = current.cadenceSince(previous!);
    final speed = current.speedSince(previous!, wheelCircumferenceM: 2.105);
    print('Cadence: $rpm rpm, speed: ${(speed ?? 0) * 3.6} km/h');
  }
  previous = current;
}
```

### Errors

- `GattParser.parse` throws an `ArgumentError` for characteristics it doesn't support, and a `GattFormatException` if the bytes are shorter than their flags say they are.
- `GattParser.tryParse` returns `null` instead of throwing.
- `GattParser.supports(uuid)` tells you in advance.

### Good to know

- Time stamps from devices carry no time zone, so they're returned as local `DateTime`s, as the device's clock showed them.
- Readings a device marks as unavailable (IEEE 11073 NaN or NRes) come back as `double.nan`.
- Enum codes newer than the spec this package follows come back as `unknown`, not as an error.

## Contributing

Issues and pull requests are welcome, especially byte captures from real devices that parse incorrectly.

## About the author

Built by [Chandra ObulaReddy](https://chandrachaan.com), a Flutter architect who has shipped Bluetooth LE and wearable integrations for safety, healthcare and fitness products.
