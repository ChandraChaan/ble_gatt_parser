import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:test/test.dart';

void main() {
  group('decodeSfloat', () {
    test('decodes whole numbers', () {
      expect(decodeSfloat(0x0078), 120);
    });

    test('decodes a negative exponent exactly', () {
      expect(decodeSfloat(0xF4B5), 120.5);
    });

    test('decodes a positive exponent', () {
      expect(decodeSfloat(0x1001), 10);
    });

    test('decodes a negative mantissa', () {
      expect(decodeSfloat(0x0FFF), -1);
    });

    test('decodes reserved values', () {
      expect(decodeSfloat(0x07FF), isNaN);
      expect(decodeSfloat(0x0800), isNaN);
      expect(decodeSfloat(0x0801), isNaN);
      expect(decodeSfloat(0x07FE), double.infinity);
      expect(decodeSfloat(0x0802), double.negativeInfinity);
    });
  });

  group('decodeFloat', () {
    test('decodes a body temperature', () {
      expect(decodeFloat(0xFF00016C), 36.4);
    });

    test('decodes a negative mantissa', () {
      expect(decodeFloat(0x00FFFFFF), -1);
    });

    test('decodes reserved values', () {
      expect(decodeFloat(0x007FFFFF), isNaN);
      expect(decodeFloat(0x00800000), isNaN);
      expect(decodeFloat(0x007FFFFE), double.infinity);
      expect(decodeFloat(0x00800002), double.negativeInfinity);
    });
  });
}
