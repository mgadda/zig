//
//  _MessagePackDecoder +SingleValueDecodingContainer.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 10/1/17.
//

import Foundation
import MessagePack

class MessagePackSingleValueDecodingContainer : SingleValueDecodingContainer {
  var codingPath: [CodingKey]

  private let decoder: _MessagePackDecoder
  private let container: MessagePackValue

  init(decoder: _MessagePackDecoder, container: MessagePackValue, codingPath: [CodingKey]) {
    self.decoder = decoder
    self.container = container
    self.codingPath = codingPath
  }

  func decodeNil() -> Bool {
    return container.isNil
  }

  func decode(_ type: Bool.Type) throws -> Bool {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: Int.Type) throws -> Int {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: Int8.Type) throws -> Int8 {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: Int16.Type) throws -> Int16 {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: Int32.Type) throws -> Int32 {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: Int64.Type) throws -> Int64 {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: UInt.Type) throws -> UInt {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: UInt8.Type) throws -> UInt8 {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: UInt16.Type) throws -> UInt16 {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: UInt32.Type) throws -> UInt32 {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: UInt64.Type) throws -> UInt64 {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: Float.Type) throws -> Float {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: Double.Type) throws -> Double {
    return try self.decoder.unbox(container, as: type)
  }

  func decode(_ type: String.Type) throws -> String {
    return try self.decoder.unbox(container, as: type)
  }

  func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
    return try self.decoder.unbox(container, as: type)!
  }
}
