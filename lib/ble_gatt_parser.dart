/// Parses standard Bluetooth Low Energy GATT characteristics into typed
/// Dart objects.
///
/// Works with any BLE plugin: pass the characteristic's UUID and the bytes
/// you received to [GattParser.parse].
library;

export 'src/byte_reader.dart' show GattFormatException;
export 'src/characteristics.dart';
export 'src/gatt_parser.dart';
export 'src/ieee11073.dart';
export 'src/values.dart';
