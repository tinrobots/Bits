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

public enum LimitInterval {
  case nanoseconds(_: Int)
  case microseconds(_: Int)
  case milliseconds(_: Int)
  case minutes(_: Int)
  case seconds(_: Int)
  case hours(_: Int)
  case days(_: Int)

  internal var dispatchTimeInterval: DispatchTimeInterval {
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
}

/// Debouncing enforces that a function not be called again until a certain amount of time has passed without it being called.
/// As in "execute this function only if 100 milliseconds have passed without it being called."
public final class Debouncer {

  // MARK: - Properties
  public let limit: DispatchTimeInterval
  public let queue: DispatchQueue

  private var workItem: DispatchWorkItem?
  private let underlyingQueue = DispatchQueue(label: "\(identifier).Debouncer")


  // MARK: - Initializers
  public init(limit: LimitInterval, queue: DispatchQueue = .main) {
    self.limit = limit.dispatchTimeInterval
    self.queue = queue
  }


  // MARK: - Limiter
  public func execute(_ block: @escaping () -> Void) {
    underlyingQueue.async { [weak self] in
      if let workItem = self?.workItem {
        workItem.cancel()
        self?.workItem = nil
      }

      guard
        let queue = self?.queue,
        let limit = self?.limit
        else { return }

      let workItem = DispatchWorkItem(block: block)
      queue.asyncAfter(deadline: .now() + limit, execute: workItem)

      self?.workItem = workItem
    }
  }

  public func reset() {
    underlyingQueue.async { [weak self] in
      if let workItem = self?.workItem {
        workItem.cancel()
        self?.workItem = nil
      }
    }
  }
}

/// Throttling enforces a maximum number of times a function can be called over time. As in "execute this function at most once every 100 milliseconds."
public final class TimedLimiter {

  // MARK: - Properties
  public let limit: DispatchTimeInterval
  public private(set) var lastExecutedAt: DispatchTime?

  private let underlyingQueue = DispatchQueue(label: "\(identifier).TimedLimiter")

  // MARK: - Initializers
  public init(limit: LimitInterval) {
    self.limit = limit.dispatchTimeInterval
  }

  // MARK: - Limiter
  @discardableResult
  public func execute(_ block: () -> Void) -> Bool {
    let executed = underlyingQueue.sync { () -> Bool in
      let now = DispatchTime.now()
      var canBeExecuted = true

      if let lastExecutionTime = lastExecutedAt {
        let deadline = lastExecutionTime + limit
        canBeExecuted = now > deadline
      }

      if canBeExecuted {
        lastExecutedAt = now
      }

      return canBeExecuted
    }

    if executed {
      block()
    }

    return executed
  }

  public func reset() {
    underlyingQueue.sync {
      lastExecutedAt = nil
    }
  }
}

public final class CountedLimiter {

  // MARK: - Properties
  public let limit: UInt
  public private(set) var count: UInt = 0

  private let underlyingQueue = DispatchQueue(label: "\(identifier).CountedLimiter")

  // MARK: - Initializers
  public init(limit: UInt) {
    self.limit = limit
  }

  // MARK: - Limiter
  @discardableResult
  public func execute(_ block: () -> Void) -> Bool {
    let executed = underlyingQueue.sync { () -> Bool in
      if count < limit {
        count += 1
        return true
      }
      return false
    }

    if executed {
      block()
    }

    return executed
  }

  public func reset() {
    underlyingQueue.sync {
      count = 0
    }
  }
}
