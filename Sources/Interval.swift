//
// Bits
//
// Copyright © 2016-2018 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

/// **Bits**
///
/// Represents a time interval.
public enum Interval {
  case nanoseconds(_: Int)
  case microseconds(_: Int)
  case milliseconds(_: Int)
  case minutes(_: Int)
  case seconds(_: Int)
  case hours(_: Int)
  case days(_: Int)

  /// Returns a `DispatchTimeInterval` representation.
  public var dispatchTimeInterval: DispatchTimeInterval {
    switch self {
    case .nanoseconds(let value): return .nanoseconds(value)
    case .microseconds(let value): return .microseconds(value)
    case .milliseconds(let value): return .milliseconds(value)
    case .seconds(let value): return .seconds(value)
    case .minutes(let value): return .seconds(value * 60)
    case .hours(let value): return .seconds(value * 3600)
    case .days(let value): return .seconds(value * 86400)
    }
  }

  /// Returns a `TimeInterval` representation.
  public var timeInterval: TimeInterval {
    switch self {
    case .nanoseconds(let value): return TimeInterval(value) / TimeInterval(1_000_000_000)
    case .microseconds(let value): return TimeInterval(value) / TimeInterval(1_000_000)
    case .milliseconds(let value): return TimeInterval(value) / TimeInterval(1000)
    case .seconds(let value): return TimeInterval(value)
    case .minutes(let value): return TimeInterval(value) * TimeInterval(60)
    case .hours(let value): return TimeInterval(value) * TimeInterval(3600)
    case .days(let value): return TimeInterval(value) * TimeInterval(86400)
    }
  }
}
