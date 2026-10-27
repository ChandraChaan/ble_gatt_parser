import 'characteristics.dart';
import 'values.dart';

/// Parses a characteristic value by its UUID.
abstract final class GattParser {
  /// Whether [characteristic] is one this package can parse.
  static bool supports(Object characteristic) =>
      _parsers.containsKey(GattCharacteristics.shortUuid(characteristic));

  /// Parses [value], the bytes read from or notified by [characteristic].
  ///
  /// [characteristic] can be an int, a short or full UUID string, or a UUID
  /// object from your BLE plugin (see [GattCharacteristics.shortUuid]).
  ///
  /// Throws an [ArgumentError] if the characteristic isn't supported, and a
  /// [FormatException] if [value] is shorter than its flags say it is.
  static GattValue parse(Object characteristic, List<int> value) {
    final uuid = GattCharacteristics.shortUuid(characteristic);
    final parser = _parsers[uuid];
    if (uuid == null || parser == null) {
      throw ArgumentError.value(
        characteristic,
        'characteristic',
        'Not a supported Bluetooth SIG characteristic',
      );
    }
    return parser(uuid, value);
  }

  /// Like [parse], but returns null instead of throwing.
  static GattValue? tryParse(Object characteristic, List<int> value) {
    try {
      return parse(characteristic, value);
    } on ArgumentError {
      return null;
    } on FormatException {
      return null;
    }
  }

  static final Map<int, GattValue Function(int uuid, List<int> value)>
      _parsers = {
    GattCharacteristics.heartRateMeasurement: (_, v) =>
        HeartRateMeasurement.parse(v),
    GattCharacteristics.bodySensorLocation: (_, v) =>
        BodySensorLocation.parse(v),
    GattCharacteristics.batteryLevel: (_, v) => BatteryLevel.parse(v),
    GattCharacteristics.temperatureMeasurement: (_, v) =>
        TemperatureMeasurement.parse(v),
    GattCharacteristics.intermediateTemperature: (_, v) =>
        TemperatureMeasurement.parse(v),
    GattCharacteristics.bloodPressureMeasurement: (_, v) =>
        BloodPressureMeasurement.parse(v),
    GattCharacteristics.intermediateCuffPressure: (_, v) =>
        BloodPressureMeasurement.parse(v),
    GattCharacteristics.weightMeasurement: (_, v) => WeightMeasurement.parse(v),
    GattCharacteristics.glucoseMeasurement: (_, v) =>
        GlucoseMeasurement.parse(v),
    GattCharacteristics.plxContinuousMeasurement: (_, v) =>
        PlxContinuousMeasurement.parse(v),
    GattCharacteristics.plxSpotCheckMeasurement: (_, v) =>
        PlxSpotCheckMeasurement.parse(v),
    GattCharacteristics.cscMeasurement: (_, v) => CscMeasurement.parse(v),
    GattCharacteristics.cyclingPowerMeasurement: (_, v) =>
        CyclingPowerMeasurement.parse(v),
    GattCharacteristics.rscMeasurement: (_, v) => RscMeasurement.parse(v),
    for (final uuid in const [
      GattCharacteristics.deviceName,
      GattCharacteristics.manufacturerName,
      GattCharacteristics.modelNumber,
      GattCharacteristics.serialNumber,
      GattCharacteristics.hardwareRevision,
      GattCharacteristics.firmwareRevision,
      GattCharacteristics.softwareRevision,
    ])
      uuid: GattString.parse,
  };
}
