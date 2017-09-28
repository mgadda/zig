//
//  _MessagePackEncoder+SingleValueEncodingContainer.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 9/27/17.
//

import Foundation
import MessagePack

extension _MessagePackEncoder : SingleValueEncodingContainer {
  fileprivate func assertCanEncodeNewValue() {
    precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
  }

  public func encodeNil() throws {
    assertCanEncodeNewValue()
    self.storage.push(container: MessagePackValue())
  }

  func encode(_ value: Bool) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Int) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Int8) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Int16) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Int32) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Int64) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: UInt) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: UInt8) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: UInt16) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: UInt32) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: UInt64) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Float) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: Double) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode(_ value: String) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: box(value))
  }

  func encode<T>(_ value: T) throws where T : Encodable {
    assertCanEncodeNewValue()
    try self.storage.push(container: box(value))
  }
}
