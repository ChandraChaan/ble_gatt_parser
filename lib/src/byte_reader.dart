import 'dart:typed_data';

import 'ieee11073.dart';

/// Thrown when a characteristic value is shorter than its flags say it is.
class GattFormatException extends FormatException {
  const GattFormatException(super.message, [super.source, super.offset]);
}

/// Reads little-endian GATT fields from a characteristic value, in order.
class ByteReader {
  ByteReader(List<int> value, this.characteristic)
      : bytes = Uint8List.fromList(value);

  /// Name used in error messages, such as "Heart Rate Measurement".
  final String characteristic;
  final Uint8List bytes;
  late final ByteData _data = ByteData.sublistView(bytes);
  int _offset = 0;

  int get remaining => bytes.length - _offset;

  void _need(int count, String field) {
    if (remaining < count) {
      throw GattFormatException(
        '$characteristic: needs $count byte(s) for $field at offset '
        '$_offset, but only $remaining left',
        bytes,
        _offset,
      );
    }
  }

  int uint8(String field) {
    _need(1, field);
    return _data.getUint8(_offset++);
  }

  int uint16(String field) {
    _need(2, field);
    final value = _data.getUint16(_offset, Endian.little);
    _offset += 2;
    return value;
  }

  int sint16(String field) {
    _need(2, field);
    final value = _data.getInt16(_offset, Endian.little);
    _offset += 2;
    return value;
  }

  int uint24(String field) {
    _need(3, field);
    final value = _data.getUint16(_offset, Endian.little) |
        (_data.getUint8(_offset + 2) << 16);
    _offset += 3;
    return value;
  }

  int uint32(String field) {
    _need(4, field);
    final value = _data.getUint32(_offset, Endian.little);
    _offset += 4;
    return value;
  }

  double sfloat(String field) => decodeSfloat(uint16(field));

  double float(String field) => decodeFloat(uint32(field));

  /// Reads a 7-byte GATT Date Time. Returns null when the device reports
  /// the year, month or day as unknown (zero).
  ///
  /// GATT times carry no time zone, so the result is in local time, as the
  /// device's clock showed it.
  DateTime? dateTime(String field) {
    _need(7, field);
    final year = uint16(field);
    final month = uint8(field);
    final day = uint8(field);
    final hours = uint8(field);
    final minutes = uint8(field);
    final seconds = uint8(field);
    if (year == 0 || month == 0 || day == 0) return null;
    return DateTime(year, month, day, hours, minutes, seconds);
  }
}
