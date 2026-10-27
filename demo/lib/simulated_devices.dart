import 'dart:math' as math;

import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter/material.dart';

/// What the playground shows for one parsed notification.
class Reading {
  const Reading(this.headline, this.unit, this.chartValue, this.details);

  final String headline;
  final String unit;
  final double chartValue;
  final Map<String, String> details;
}

/// A fake BLE device that sends spec-correct notifications.
///
/// ble_gatt_parser only parses, so the playground encodes its own bytes here.
/// Readings drift smoothly between realistic limits so the charts look alive.
abstract class SimulatedDevice {
  SimulatedDevice(this.name, this.icon, this.uuid);

  final String name;
  final IconData icon;
  final int uuid;

  int _tick = 0;
  final _random = math.Random(42);

  List<int> nextNotification() => encode(_tick++);

  List<int> encode(int tick);

  Reading describe(GattValue value);

  /// A value that drifts between [min] and [max] over [period] ticks.
  double wave(double min, double max, {double period = 30, double phase = 0}) {
    final position = (math.sin((_tick + phase) * 2 * math.pi / period) + 1) / 2;
    final noise = (_random.nextDouble() - 0.5) * 0.06;
    return min + (max - min) * (position + noise).clamp(0.0, 1.0);
  }
}

List<SimulatedDevice> simulatedDevices() => [
  HeartRateStrap(),
  BloodPressureCuff(),
  Thermometer(),
  PulseOximeter(),
  PowerMeter(),
  RunningPod(),
];

class HeartRateStrap extends SimulatedDevice {
  HeartRateStrap()
    : super(
        'Heart rate strap',
        Icons.favorite,
        GattCharacteristics.heartRateMeasurement,
      );

  @override
  List<int> encode(int tick) {
    final bpm = wave(68, 152).round();
    final rrRaw = (60000 / bpm * 1024 / 1000).round();
    // Flags: skin contact supported and detected, RR-intervals present.
    return [0x16, bpm, ..._uint16(rrRaw)];
  }

  @override
  Reading describe(GattValue value) {
    final hr = value as HeartRateMeasurement;
    return Reading('${hr.bpm}', 'bpm', hr.bpm.toDouble(), {
      'Skin contact': hr.sensorContact.name,
      'RR interval': '${hr.rrIntervalsMs.first.toStringAsFixed(0)} ms',
    });
  }
}

class BloodPressureCuff extends SimulatedDevice {
  BloodPressureCuff()
    : super(
        'Blood pressure cuff',
        Icons.monitor_heart,
        GattCharacteristics.bloodPressureMeasurement,
      );

  @override
  List<int> encode(int tick) {
    final systolic = wave(112, 138).roundToDouble();
    final diastolic = wave(72, 88, period: 23).roundToDouble();
    final meanArterial = (diastolic + (systolic - diastolic) / 3)
        .roundToDouble();
    final pulse = wave(62, 86, period: 17).roundToDouble();
    // Flags: mmHg, pulse rate present.
    return [
      0x04,
      ..._sfloat(systolic, 0),
      ..._sfloat(diastolic, 0),
      ..._sfloat(meanArterial, 0),
      ..._sfloat(pulse, 0),
    ];
  }

  @override
  Reading describe(GattValue value) {
    final bp = value as BloodPressureMeasurement;
    return Reading(
      '${bp.systolic.round()}/${bp.diastolic.round()}',
      bp.unit.name,
      bp.systolic,
      {
        'Mean arterial': '${bp.meanArterialPressure.round()} ${bp.unit.name}',
        'Pulse': '${bp.pulseRate!.round()} bpm',
      },
    );
  }
}

class Thermometer extends SimulatedDevice {
  Thermometer()
    : super(
        'Thermometer',
        Icons.thermostat,
        GattCharacteristics.temperatureMeasurement,
      );

  @override
  List<int> encode(int tick) {
    final celsius = (wave(36.3, 37.8, period: 40) * 10).round() / 10;
    // Flags: Celsius, temperature type present. Type 3 is "ear".
    return [0x04, ..._float(celsius, 1), 3];
  }

  @override
  Reading describe(GattValue value) {
    final t = value as TemperatureMeasurement;
    return Reading(t.celsius.toStringAsFixed(1), '°C', t.celsius, {
      'Body site': t.type!.name,
      'Fahrenheit': '${t.fahrenheit.toStringAsFixed(1)} °F',
    });
  }
}

class PulseOximeter extends SimulatedDevice {
  PulseOximeter()
    : super(
        'Pulse oximeter',
        Icons.air,
        GattCharacteristics.plxContinuousMeasurement,
      );

  @override
  List<int> encode(int tick) {
    final spo2 = wave(94, 99.4, period: 26).roundToDouble();
    final pulse = wave(60, 88, period: 19).roundToDouble();
    final perfusion = (wave(1.5, 4.5) * 10).round() / 10;
    // Flags: pulse amplitude index present.
    return [
      0x10,
      ..._sfloat(spo2, 0),
      ..._sfloat(pulse, 0),
      ..._sfloat(perfusion, 1),
    ];
  }

  @override
  Reading describe(GattValue value) {
    final plx = value as PlxContinuousMeasurement;
    return Reading('${plx.spo2.round()}', '% SpO₂', plx.spo2, {
      'Pulse': '${plx.pulseRate.round()} bpm',
      'Perfusion index': '${plx.pulseAmplitudeIndex}%',
    });
  }
}

class PowerMeter extends SimulatedDevice {
  PowerMeter()
    : super(
        'Power meter',
        Icons.directions_bike,
        GattCharacteristics.cyclingPowerMeasurement,
      );

  double _revolutions = 0;
  CyclingPowerMeasurement? _previous;

  @override
  List<int> encode(int tick) {
    // Each tick stands for one second of riding.
    final rpm = wave(76, 98, period: 21);
    _revolutions += rpm / 60;
    final fraction = _revolutions - _revolutions.floor();
    final lastEventTime = ((tick + 1 - fraction / (rpm / 60)) * 1024).round();
    final power = wave(180, 330).round();
    // Flags: crank revolution data present.
    return [
      ..._uint16(0x0020),
      ..._uint16(power),
      ..._uint16(_revolutions.floor() % 0x10000),
      ..._uint16(lastEventTime % 0x10000),
    ];
  }

  @override
  Reading describe(GattValue value) {
    final power = value as CyclingPowerMeasurement;
    final cadence = switch (_previous) {
      null => null,
      final previous => power.cadenceSince(previous),
    };
    _previous = power;
    return Reading('${power.powerWatts}', 'W', power.powerWatts.toDouble(), {
      'Cadence': cadence == null ? '…' : '${cadence.round()} rpm',
      'Crank revolutions': '${power.crankRevolutions}',
    });
  }
}

class RunningPod extends SimulatedDevice {
  RunningPod()
    : super(
        'Running pod',
        Icons.directions_run,
        GattCharacteristics.rscMeasurement,
      );

  double _distance = 0;

  @override
  List<int> encode(int tick) {
    final speed = wave(2.7, 3.9, period: 28);
    _distance += speed;
    // Flags: total distance present, running.
    return [
      0x06,
      ..._uint16((speed * 256).round()),
      wave(160, 184).round(),
      ..._uint32((_distance * 10).round()),
    ];
  }

  @override
  Reading describe(GattValue value) {
    final run = value as RscMeasurement;
    final pace = run.pacePerKm!;
    final seconds = (pace.inSeconds % 60).toString().padLeft(2, '0');
    return Reading('${pace.inMinutes}:$seconds', '/km', run.speedKmh, {
      'Speed': '${run.speedKmh.toStringAsFixed(1)} km/h',
      'Cadence': '${run.cadence} spm',
      'Distance': '${(run.totalDistanceM! / 1000).toStringAsFixed(2)} km',
    });
  }
}

List<int> _uint16(int value) => [value & 0xFF, (value >> 8) & 0xFF];

List<int> _uint32(int value) => [
  value & 0xFF,
  (value >> 8) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 24) & 0xFF,
];

/// IEEE 11073 SFLOAT: 12-bit mantissa, 4-bit base-10 exponent.
List<int> _sfloat(double value, int decimals) {
  final mantissa = (value * math.pow(10, decimals)).round();
  return _uint16(((-decimals & 0xF) << 12) | (mantissa & 0x0FFF));
}

/// IEEE 11073 FLOAT: 24-bit mantissa, 8-bit base-10 exponent.
List<int> _float(double value, int decimals) {
  final mantissa = (value * math.pow(10, decimals)).round();
  return [
    ..._uint16(mantissa & 0xFFFF),
    (mantissa >> 16) & 0xFF,
    -decimals & 0xFF,
  ];
}
