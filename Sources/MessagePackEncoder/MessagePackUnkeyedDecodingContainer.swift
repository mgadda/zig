//
//  MessagePackUnkeyedDecodingContainer.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 10/9/17.
//

import Foundation
import MessagePack

class MessagePackUnkeyedDecodingContainer : UnkeyedDecodingContainer {
  var codingPath: [CodingKey]
  var currentIndex: Int
  var container: [MessagePackValue]
  var count: Int? { return container.count }
  var isAtEnd: Bool { return self.currentIndex >= self.count! }

  private var decoder: _MessagePackDecoder

  init(decoder: _MessagePackDecoder, container: [MessagePackValue]) {
    self.decoder = decoder
    self.container = container
    self.codingPath = decoder.codingPath
    self.currentIndex = 0
  }

  func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
    guard !self.isAtEnd else {
      throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nested keyed container is unavailable because isAtEnd was unexpectedly true."))
    }

    guard case let .map(mapContainer) = self.container[self.currentIndex] else {
      throw DecodingError.typeMismatch([MessagePackValue : MessagePackValue].self, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Container value at \(self.currentIndex) is not a MessagePackValue.map"))
    }

    self.currentIndex += 1
    let decodingContainer = MessagePackKeyedDecodingContainer<NestedKey>(decoder: self.decoder, container: mapContainer)
    return KeyedDecodingContainer(decodingContainer)
  }

  func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
    guard !self.isAtEnd else {
      throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nested unkeyed container unavailable because isAtEnd was unexpectedly true."))
    }

    guard case let .array(arrayContainer) = self.container[self.currentIndex] else {
      throw DecodingError.typeMismatch([MessagePackValue].self, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Container value at \(self.currentIndex) is not a MessagePackValue.array"))
    }

    self.currentIndex += 1
    return MessagePackUnkeyedDecodingContainer(decoder: self.decoder, container: arrayContainer)
  }

  func superDecoder() throws -> Decoder {
    self.decoder.codingPath.append(MessagePackKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard !self.isAtEnd else {
      throw DecodingError.valueNotFound(Decoder.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "superDecoder unavailable because container isAtEnd."))
    }

    let value = self.container[self.currentIndex]
    self.currentIndex += 1
    return _MessagePackDecoder(container: value, at: self.decoder.codingPath)
  }

  /// Decode non-standard types (i.e. your own types)
  func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    guard let value = try decoder.unbox(self.container[self.currentIndex], type: type) else {
      throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found nil"))
    }
    return value
  }

  func decodeNil() throws -> Bool {
    guard !self.isAtEnd else {
      throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: self.decoder.codingPath + [MessagePackKey(index: self.currentIndex)], debugDescription: "Cannot decode Nil. Unkeyed container isAtEnd."))
    }

    self.currentIndex += 1
    return self.container[self.currentIndex].isNil
  }

  func expectNotAtEnd(_ type: Any.Type) throws {
    guard !self.isAtEnd else {
      throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: self.decoder.codingPath + [MessagePackKey(index: self.currentIndex)], debugDescription: "Expected to not be at end of unkeyed container."))
    }
  }

  func decode(_ type: Bool.Type) throws -> Bool {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: Int.Type) throws -> Int {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: Int8.Type) throws -> Int8 {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: Int16.Type) throws -> Int16 {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: Int32.Type) throws -> Int32 {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: Int64.Type) throws -> Int64 {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: UInt.Type) throws -> UInt {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: UInt8.Type) throws -> UInt8 {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: UInt16.Type) throws -> UInt16 {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: UInt32.Type) throws -> UInt32 {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: UInt64.Type) throws -> UInt64 {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: Float.Type) throws -> Float {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: Double.Type) throws -> Double {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }

  func decode(_ type: String.Type) throws -> String {
    try expectNotAtEnd(type)
    self.currentIndex += 1
    return try decoder.unbox(self.container[self.currentIndex], type: type)
  }
}
