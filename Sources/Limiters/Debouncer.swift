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
/// Enforces a function to not be called again until a certain amount of time has passed without it being called.
/// As in "execute this function only if 100 milliseconds have passed without it being called."
/// - Important: Debouncer will not fire immediately but it will wait the specified time period before executing the function call.
class Debouncer {

  public let limit: Interval
  private weak var timer: Timer?

  /// Debouncer
  ///
  /// - Parameters:
  ///   - limit: Amount of time that needs to be passed without the block being called.
  ///   - qos: The Quality Of Service of the Debouncer.
  public init(limit: Interval) {
    self.limit = limit
  }

  public func execute(_ block: @escaping () -> Void) {
    self.timer?.invalidate()
    let nextTimer = Timer.scheduledTimer(withTimeInterval: limit.timeInterval, repeats: false) { _ in block() }
    self.timer = nextTimer
  }

  public func reset() {
    timer?.invalidate()
    timer = nil
  }
}
