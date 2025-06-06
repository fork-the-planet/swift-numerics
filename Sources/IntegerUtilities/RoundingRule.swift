//===--- RoundingRule.swift -----------------------------------*- swift -*-===//
//
// This source file is part of the Swift Numerics open source project
//
// Copyright (c) 2021-2025 Apple Inc. and the Swift Numerics project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A rule that defines how to select one of the two representable results
/// closest to a given value.
///
/// [Wikipedia](https://en.wikipedia.org/wiki/Rounding#Rounding_to_integer)
/// provides a good overview of different rounding rules.
///
/// Examples using rounding to integer to illustrate the various options:
/// ```
///                          Directed rounding rules
/// 
///  value |     down     |      up      |  towardZero  | awayFromZero |
/// =======+==============+==============+==============+==============+
///  -1.5  |      -2      |      -1      |      -1      |      -2      |
/// -------+--------------+--------------+--------------+--------------+
///  -0.5  |      -1      |       0      |       0      |      -1      |
/// -------+--------------+--------------+--------------+--------------+
///   0.5  |       0      |       1      |       0      |       1      |
/// -------+--------------+--------------+--------------+--------------+
///   0.7  |       0      |       1      |       0      |       1      |
/// -------+--------------+--------------+--------------+--------------+
///   1.2  |       1      |       2      |       1      |       2      |
/// -------+--------------+--------------+--------------+--------------+
///   2.0  |       2      |       2      |       2      |       2      |
/// -------+--------------+--------------+--------------+--------------+
///
///                      toNearestOr... rounding rules
///
///  value |  orDown  |   orUp   |  orZero  |  orAway  |  orEven  |
/// =======+==========+==========+==========+==========+==========+
///  -1.5  |    -2    |    -1    |    -1    |    -2    |    -2    |
/// -------+----------+----------+----------+----------+----------+
///  -0.5  |    -1    |     0    |     0    |    -1    |     0    |
/// -------+----------+----------+----------+----------+----------+
///   0.5  |     0    |     1    |     0    |     1    |     0    |
/// -------+----------+----------+----------+----------+----------+
///   0.7  |     1    |     1    |     1    |     1    |     1    |
/// -------+----------+----------+----------+----------+----------+
///   1.2  |     1    |     1    |     1    |     1    |     1    |
/// -------+----------+----------+----------+----------+----------+
///   2.0  |     2    |     2    |     2    |     2    |     2    |
/// -------+----------+----------+----------+----------+----------+
///
///            Specialized rounding rules
///
///  value |    toOdd     |  requireExact  |
/// =======+==============+================+
///  -1.5  |      -1      |      trap      |
/// -------+--------------+----------------+
///  -0.5  |      -1      |      trap      |
/// -------+--------------+----------------+
///   0.5  |       1      |      trap      |
/// -------+--------------+----------------+
///   0.7  |       1      |      trap      |
/// -------+--------------+----------------+
///   1.2  |       1      |      trap      |
/// -------+--------------+----------------+
///   2.0  |       2      |        2       |
/// -------+--------------+----------------+
/// ```
public enum RoundingRule {
  /// Produces the closest representable value that is less than or equal
  /// to the value being rounded.
  ///
  /// This is the default rounding mode for integer shifts, including the
  /// shift operators defined in the standard library. 
  ///
  /// Examples:
  /// - `(-4).divided(by: 3, rounding: .down)` is `-2`, because –2 is the
  /// largest integer less than –4/3 = –1.3̅
  /// - `5.shifted(rightBy: 1, rounding: .down)` is `2`, because 2 is the
  /// largest integer less than 5/2 = 2.5.
  case down
  
  /// Produces the closest representable value that is greater than or equal
  /// to the value being rounded.
  ///
  /// Examples:
  /// - `(-4).divided(by: 3, rounding: .up)` is `-1`, because –1 is the
  /// smallest integer greater than –4/3 = –1.3̅
  /// - `5.shifted(rightBy: 1, rounding: .up)` is `3`, because 3 is the
  /// smallest integer greater than 5/2 = 2.5.
  case up
  
  /// Produces the closest representable value whose magnitude is less than
  /// or equal to that of the value being rounded.
  ///
  /// Examples:
  /// - `(-4).divided(by: 3, rounding: .towardZero)` is `-1`, because –1
  /// is the closest integer to –4/3 = –1.3̅ with smaller magnitude.
  /// - `5.shifted(rightBy: 1, rounding: .towardZero)` is `2`, because 2
  /// is the closest integer to 5/2 = 2.5 with smaller magnitude.
  case towardZero
  
  /// Produces the closest representable value whose magnitude is greater
  /// than or equal to that of the value being rounded.
  ///
  /// Examples:
  /// - `(-4).divided(by: 3, rounding: .awayFromZero)` is `-2`, because –2
  /// is the closest integer to –4/3 = –1.3̅ with greater magnitude.
  /// - `5.shifted(rightBy: 1, rounding: .awayFromZero)` is `3`, because 3
  /// is the closest integer to 5/2 = 2.5 with greater magnitude.
  case awayFromZero
  
  /// If the value being rounded is representable, that value is returned.
  /// Otherwise, whichever of the two closest representable values has its
  /// least significant bit set is returned.
  ///
  /// This is also called _sticky rounding_, and it is useful as an
  /// implementation detail because it has the property that if we do
  /// rounding in two steps, first to intermediate precision p₁ with .toOdd,
  /// then to the final precision p₂ with any other rounding mode, the result
  /// we get is the same as if we rounded directly to p₂ in the desired mode
  /// so long as p₂ + 1 < p₁. Other rounding modes do not have this property,
  /// and admit _double roundings_ when interoperating with some modes.
  ///
  /// Examples:
  /// - `(-4).divided(by: 3, rounding: .toOdd)` is `-1`, because –4/3 = –1.3̅
  /// is not an exact integer, and –1 is the closest odd integer.
  /// - `4.shifted(rightBy: 1, rounding: .toOdd)` is `2`,
  /// even though 2 is even, because 4/2 is exactly 2 and no rounding occurs.
  case toOdd
  
  /// Produces the representable value that is closest to the value being
  /// rounded. If two values are equally close, the one that is less than
  /// the value being rounded is chosen.
  ///
  /// Examples:
  /// - `(-4).divided(by: 3, rounding: .toNearestOrDown)`
  /// is `-1`, because –4/3 = –1.3̅ is closer to –1 than it is to –2.
  ///
  /// - `5.shifted(rightBy: 1, rounding: .toNearestOrDown)` is `2`,
  /// because 5/2 = 2.5 is equally close to 2 and 3, and 2 is less.
  case toNearestOrDown
  
  /// Produces the representable value that is closest to the value being
  /// rounded. If two values are equally close, the one that is greater than
  /// the value being rounded is chosen.
  ///
  /// Examples:
  /// - `(-4).divided(by: 3, rounding: .toNearestOrUp)`
  /// is `-1`, because –4/3 = –1.3̅ is closer to –1 than it is to –2.
  ///
  /// - `5.shifted(rightBy: 1, rounding: .toNearestOrUp)` is `3`,
  /// because 5/2 = 2.5 is equally close to 2 and 3, and 3 is greater.
  case toNearestOrUp
  
  /// Produces the representable value that is closest to the value being
  /// rounded. If two values are equally close, the one that has smaller
  /// magnitude is returned.
  ///
  /// Examples:
  /// - `(-4).divided(by: 3, rounding: .toNearestOrZero)`
  /// is `-1`, because –4/3 = –1.3̅ is closer to –1 than it is to –2.
  ///
  /// - `5.shifted(rightBy: 1, rounding: .toNearestOrZero)` is `3`,
  /// because 5/2 = 2.5 is equally close to 2 and 3, and 2 is closer to zero.
  case toNearestOrZero
  
  /// Produces the representable value that is closest to the value being
  /// rounded. If two values are equally close, the one that has greater
  /// magnitude is returned.
  ///
  /// Examples:
  /// - `(-4).divided(by: 3, rounding: .toNearestOrAway)`
  /// is `-1`, because –4/3 = –1.3̅ is closer to –1 than it is to –2.
  ///
  /// - `5.shifted(rightBy: 1, rounding: .toNearestOrAway)` is `3`,
  /// because 5/2 = 2.5 is equally close to 2 and 3, and 3 is further away
  /// from zero.
  case toNearestOrAway
  
  /// Produces the representable value that is closest to the value being
  /// rounded. If two values are equally close, the one whose least
  /// significant bit is not set is returned.
  ///
  /// Examples:
  /// - `(-4).divided(by: 3, rounding: .toNearestOrEven)`
  /// is `-1`, because –4/3 = –1.3̅ is closer to –1 than it is to –2.
  ///
  /// - `5.shifted(rightBy: 1, rounding: .toNearestOrEven)` is `2`,
  /// because 5/2 = 2.5 is equally close to 2 and 3, and 2 is even.
  case toNearestOrEven
  
  /// If the value being rounded is representable, that value is returned.
  /// Otherwise, a precondition failure occurs.
  ///
  /// Examples:
  /// - `(-4).divided(by: 3, rounding: .requireExact)` will trap,
  /// because –4/3 = –1.3̅ is not an integer.
  case requireExact
}

extension RoundingRule {
  /// Produces the representable value that is closest to the value being
  /// rounded. If two values are equally close, the one that has greater
  /// magnitude is returned.
  ///
  /// > Deprecated: Use `.toNearestOrAway` instead.
  @inlinable
  @available(*, deprecated, renamed: "toNearestOrAway")
  public static var toNearestOrAwayFromZero: Self { .toNearestOrAway }
}

extension FloatingPoint {
  /// `self` rounded to integer according to `rule`.
  ///
  /// This mirrors the standard library `rounded` API, providing access to
  /// the expanded set of rounding rules defined in IntegerUtilities. It is
  /// not just a shadow because that would lead to ambiguity errors in
  /// existing code that uses the shortened `rounded(.down)` form.
  @inlinable @inline(__always)
  public func rounding(_ rule: RoundingRule) -> Self {
    switch rule {
    case .down:
      return rounded(.down)
    case .up:
      return rounded(.up)
    case .towardZero:
      return rounded(.towardZero)
    case .awayFromZero:
      return rounded(.awayFromZero)
    case .toNearestOrDown:
      // FP doesn't have toNearestOrDown, so round toNearestOrEven and fixup
      // any exact-halfway cases.
      let nearest = rounded(.toNearestOrEven)
      return nearest - self == 1/2 ? rounded(.down) : nearest
    case .toNearestOrUp:
      // FP doesn't have toNearestOrUp, so round toNearestOrEven and fixup
      // any exact-halfway cases.
      let nearest = rounded(.toNearestOrEven)
      return self - nearest == 1/2 ? rounded(.up) : nearest
    case .toNearestOrZero:
      // FP doesn't have toNearestOrZero, so round toNearestOrEven and fixup
      // any exact-halfway cases.
      let nearest = rounded(.toNearestOrEven)
      return (self - nearest).magnitude == 1/2 ? rounded(.towardZero) : nearest
    case .toNearestOrAway:
      return self.rounded(.toNearestOrAwayFromZero)
    case .toNearestOrEven:
      return self.rounded(.toNearestOrEven)
    case .toOdd:
      let trunc = rounded(.towardZero)
      if trunc == self { return trunc }
      let one = Self(signOf: self, magnitudeOf: 1)
      // We have eliminated all large values at this point; add ±0.5, and see
      // which way that rounds, then select the other value.
      let even = (trunc + one/2).rounded(.toNearestOrEven)
      return trunc == even ? trunc + one : trunc
    case .requireExact:
      let trunc = rounded(.towardZero)
      precondition(isInfinite || trunc == self, "\(self) is not an exact integer.")
      return self
    }
  }
}
