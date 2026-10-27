import 'dart:math' as math;

/// Decodes a 16-bit IEEE 11073 SFLOAT, the number format most Bluetooth
/// health devices use for readings like blood pressure and SpO2.
///
/// The value is a 12-bit signed mantissa and a 4-bit signed base-10
/// exponent. The reserved values NaN, NRes and the reserved code decode to
/// [double.nan]; +INFINITY and -INFINITY decode to the matching infinity.
double decodeSfloat(int raw) {
  raw &= 0xFFFF;
  switch (raw) {
    case 0x07FF || 0x0800 || 0x0801:
      return double.nan;
    case 0x07FE:
      return double.infinity;
    case 0x0802:
      return double.negativeInfinity;
  }
  var mantissa = raw & 0x0FFF;
  if (mantissa >= 0x0800) mantissa -= 0x1000;
  var exponent = raw >> 12;
  if (exponent >= 0x8) exponent -= 0x10;
  return _scale(mantissa, exponent);
}

/// Decodes a 32-bit IEEE 11073 FLOAT, used by thermometers.
///
/// The value is a 24-bit signed mantissa and an 8-bit signed base-10
/// exponent. Reserved values decode the same way as in [decodeSfloat].
double decodeFloat(int raw) {
  raw &= 0xFFFFFFFF;
  switch (raw) {
    case 0x007FFFFF || 0x00800000 || 0x00800001:
      return double.nan;
    case 0x007FFFFE:
      return double.infinity;
    case 0x00800002:
      return double.negativeInfinity;
  }
  var mantissa = raw & 0xFFFFFF;
  if (mantissa >= 0x800000) mantissa -= 0x1000000;
  var exponent = raw >> 24;
  if (exponent >= 0x80) exponent -= 0x100;
  return _scale(mantissa, exponent);
}

// Dividing for negative exponents keeps values like 120.5 exact, where
// multiplying by 0.1 would not.
double _scale(int mantissa, int exponent) => exponent >= 0
    ? mantissa * math.pow(10, exponent).toDouble()
    : mantissa / math.pow(10, -exponent);
