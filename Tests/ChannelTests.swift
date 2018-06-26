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

import XCTest
@testable import Bits

class ChannelTests: XCTestCase {

  enum Event {
    case event1
    case event2(String)
    case event3(Int)
  }

  func testSimpleBroadcast() {
    // Given
    let channel = Channel<Event>()
    let object1 = NSObject()
    let object2 = NSObject()
    let expectation1 = self.expectation(description: "\(#function)\(#line)")
    let expectation2 = self.expectation(description: "\(#function)\(#line)")

    // When, Then
    channel.subscribe(object1, queue: .global()) { event in
      XCTAssertFalse(Thread.isMainThread)
      switch event {
      case .event1: expectation1.fulfill()
      default: break
      }
    }
    channel.subscribe(object2, queue: .main) { event in
      XCTAssertTrue(Thread.isMainThread)
      switch event {
      case .event1: expectation2.fulfill()
      default: break
      }
    }

    channel.broadcast(.event1)
    waitForExpectations(timeout: 1)
    XCTAssertEqual(channel.subscriptions.count, 2)
  }

  func testUnsuscribeSubscriptions() {
    // Given
    let channel = Channel<Event>()
    let object1 = NSObject()
    let object2 = NSObject()
    var object3: NSObject? = NSObject()

    let expectation1 = self.expectation(description: "\(#function)\(#line)")
    let expectation2 = self.expectation(description: "\(#function)\(#line)")
    let expectation3 = self.expectation(description: "\(#function)\(#line)")

    expectation2.isInverted = true
    expectation3.isInverted = true

    // When, Then
    channel.subscribe(object1) { event in
      XCTAssertTrue(Thread.isMainThread)
      switch event {
      case .event1: expectation1.fulfill()
      default: break
      }
    }
    channel.subscribe(object2, queue: .main) { event in
      expectation2.fulfill()
    }
    channel.subscribe(object3, queue: .main) { event in
      expectation3.fulfill()
    }
    channel.unsubscribe(object2)
    object3 = nil


    channel.broadcast(.event1)
    waitForExpectations(timeout: 1)
    XCTAssertEqual(channel.subscriptions.count, 1)
  }

  func testUnsuscribeInvalidSubscriber() {
    // Given
    class Object { }
    let channel = Channel<Event>()
    var object1: NSObject? = NSObject()
    var object2: Object? = Object()

    let expectation1 = self.expectation(description: "\(#function)\(#line)")
    let expectation2 = self.expectation(description: "\(#function)\(#line)")
    let expectation3 = self.expectation(description: "\(#function)\(#line)")
    let expectation4 = self.expectation(description: "\(#function)\(#line)")
    let expectation5 = self.expectation(description: "\(#function)\(#line)")
    let expectation6 = self.expectation(description: "\(#function)\(#line)")

    expectation3.isInverted = true
    expectation4.isInverted = true

    // When, Then
    channel.subscribe(object1, completion: {
      expectation1.fulfill()
    }) { _ in
      expectation3.fulfill()
    }

    channel.subscribe(object2, completion: {
      expectation2.fulfill()
    }) { _ in
      expectation4.fulfill()
    }

    wait(for: [expectation1, expectation2], timeout: 2)
    XCTAssertEqual(channel.subscriptions.count, 2)

    /// making sure that a nil object can still be used to unsuscribe

    let subscriptionUUIDObject1 = channel.subscriptions.filter { $0.object === object1 }[0].uuid
    let subscriptionUUIDObject2 = channel.subscriptions.filter { $0.object === object2 }[0].uuid

    object2 = nil
    channel.unsubscribe(object2) {
      expectation5.fulfill()
    }

    wait(for: [expectation5], timeout: 2)
    XCTAssertEqual(channel.subscriptions.count, 1)
    XCTAssertEqual(channel.subscriptions.filter { $0.uuid == subscriptionUUIDObject1 }.count, 1)
    XCTAssertTrue(channel.subscriptions.filter { $0.uuid == subscriptionUUIDObject2 }.isEmpty)

    object1 = nil
    channel.unsubscribe(object1) {
      expectation6.fulfill()
    }

    wait(for: [expectation6], timeout: 2)
    XCTAssertTrue(channel.subscriptions.isEmpty)

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertTrue(channel.subscriptions.isEmpty)
  }

  func testInvalidSubscriber() {
    // Given
    let channel = Channel<Event>()
    var object: NSObject? = NSObject()
    let expectation = self.expectation(description: "\(#function)\(#line)")
    expectation.isInverted = true

    // When
    channel.subscribe(object) { _ in
      expectation.fulfill()
    }
    object = nil
    channel.broadcast(.event1)

    // Then
    waitForExpectations(timeout: 1)
    XCTAssertTrue(channel.subscriptions.isEmpty)
  }

  func testMultipleBroadcasts() {
    // Given
    let channel = Channel<Event>()
    let object1 = NSObject()
    let iterations = 1000

    let expectation1 = self.expectation(description: "\(#function)\(#line)")
    var count = 0
    let lock = NSLock()

    // When
    channel.subscribe(object1, queue: .global()) { event in
      XCTAssertFalse(Thread.isMainThread)
      switch event {
      case .event3(let value):
        lock.lock(); defer { lock.unlock() }
        count += 1

        if value == 999 {
          expectation1.fulfill()
        }
      default: break
      }
    }

    DispatchQueue.concurrentPerform(iterations: iterations) { index in
      channel.broadcast(.event3(index))
    }

    // Then
    waitForExpectations(timeout: 2)
    XCTAssertEqual(count, iterations)
  }

  func testUnsuscribeBetweenTheBroadcastingOfTwoEvents() {
    // Given
    let channel = Channel<Event>()
    let object1 = NSObject()
    let expectation1 = self.expectation(description: "\(#function)\(#line)")
    let expectation2 = self.expectation(description: "\(#function)\(#line)")

    // When
    channel.subscribe(object1) { event in
      switch event {
      case .event1:
        expectation1.fulfill()
      default: break
      }
    }

    channel.broadcast(.event1)

    channel.unsubscribe(object1) {
      expectation2.fulfill()
    }

    wait(for: [expectation2], timeout: 2)
    channel.broadcast(.event1)

    // Then
    waitForExpectations(timeout: 5)
  }

  func testUnsuscribeWhileBroadcasting() {
    // Given
    let channel = Channel<Event>()
    let object1 = NSObject()
    let iterations = 1000
    let expectation1 = self.expectation(description: "\(#function)\(#line)")
    let expectation2 = self.expectation(description: "\(#function)\(#line)")
    let expectation4 = self.expectation(description: "\(#function)\(#line)")
    expectation4.isInverted = true

    var count = 0
    let lock = NSLock()

    // When
    channel.subscribe(object1) { event in
      switch event {
      case .event3(let value):
        lock.lock(); defer { lock.unlock() }
        count += 1
      default: break
      }
    }

    DispatchQueue(label: "\(#function)\(#line)").async {
      DispatchQueue.concurrentPerform(iterations: iterations) { index in
        Thread.sleep(forTimeInterval: 0.01)
        channel.broadcast(.event3(index))
        if index == 999 {
          expectation1.fulfill()
        }
      }
    }

    /// Object1 will receive some events the events
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
      channel.unsubscribe(object1) {
        expectation2.fulfill()
      }
    }

    // Then
    waitForExpectations(timeout: 2)
    lock.lock()
    XCTAssertTrue(1...999 ~= count, "\(count) should be >= 1 and <= 999")
    lock.unlock()
  }

}
