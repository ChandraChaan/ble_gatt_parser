/// 16-bit UUIDs of the Bluetooth SIG characteristics this package parses.
abstract final class GattCharacteristics {
  static const deviceName = 0x2A00;
  static const glucoseMeasurement = 0x2A18;
  static const batteryLevel = 0x2A19;
  static const temperatureMeasurement = 0x2A1C;
  static const intermediateTemperature = 0x2A1E;
  static const modelNumber = 0x2A24;
  static const serialNumber = 0x2A25;
  static const firmwareRevision = 0x2A26;
  static const hardwareRevision = 0x2A27;
  static const softwareRevision = 0x2A28;
  static const manufacturerName = 0x2A29;
  static const bloodPressureMeasurement = 0x2A35;
  static const intermediateCuffPressure = 0x2A36;
  static const heartRateMeasurement = 0x2A37;
  static const bodySensorLocation = 0x2A38;
  static const rscMeasurement = 0x2A53;
  static const cscMeasurement = 0x2A5B;
  static const plxSpotCheckMeasurement = 0x2A5E;
  static const plxContinuousMeasurement = 0x2A5F;
  static const cyclingPowerMeasurement = 0x2A63;
  static const weightMeasurement = 0x2A9D;

  static const _baseUuidSuffix = '-0000-1000-8000-00805f9b34fb';

  /// Returns the 16-bit UUID of [characteristic], or null if it isn't a
  /// Bluetooth SIG UUID.
  ///
  /// Accepts an int (`0x2A37`), a short string (`'2a37'`, `'0x2A37'`), or a
  /// full 128-bit string (`'00002a37-0000-1000-8000-00805f9b34fb'`). Any
  /// object whose `toString()` gives one of those also works, such as a
  /// `Guid` from flutter_blue_plus or a `Uuid` from flutter_reactive_ble.
  static int? shortUuid(Object characteristic) {
    if (characteristic is int) {
      return characteristic >= 0 && characteristic <= 0xFFFF
          ? characteristic
          : null;
    }
    var text = characteristic.toString().trim().toLowerCase();
    if (text.startsWith('0x')) text = text.substring(2);
    if (text.length == 36 &&
        text.startsWith('0000') &&
        text.endsWith(_baseUuidSuffix)) {
      text = text.substring(4, 8);
    } else if (text.length == 8 && text.startsWith('0000')) {
      text = text.substring(4);
    }
    if (text.length != 4) return null;
    return int.tryParse(text, radix: 16);
  }
}
