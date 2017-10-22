//
//  MessagePackDecoder.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 9/30/17.
//

import Foundation
import MessagePack

/// A class for decoding MessagePack encoded Data instances.
public class MessagePackDecoder {

  public init() {}

  open func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T {
    let rootObject: MessagePackValue = try MessagePack.unpackFirst(data)
    let decoder = _MessagePackDecoder()
    guard let value = try decoder.unbox(rootObject, type: T.self) else {
      throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "Failed to unbox value"))
    }
    return value
  }
}

internal class _MessagePackDecoder : Decoder {
  var codingPath: [CodingKey] = []

  var userInfo: [CodingUserInfoKey : Any] = [:]

  // A stack-order set of values in the process of being decoded
  var valuesToDecode: [MessagePackValue] = []

  init() {}

  init(container: MessagePackValue, at codingPath: [CodingKey] = []) {
    valuesToDecode.append(container)
    self.codingPath = codingPath
  }

  func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
    guard
      let maybeValue = self.valuesToDecode.last,
      let dictionaryValue = maybeValue.dictionaryValue else {
        throw DecodingError.typeMismatch([MessagePackValue : MessagePackValue].self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected container to be type MessagePackValue.map"))
    }
    let innerContainer = MessagePackKeyedDecodingContainer<Key>(decoder: self, container: dictionaryValue)
    return KeyedDecodingContainer(innerContainer)
  }

  func unkeyedContainer() throws -> UnkeyedDecodingContainer {
    guard
      let maybeValue = self.valuesToDecode.last,
      let arrayValue = maybeValue.arrayValue else {
        throw DecodingError.typeMismatch([MessagePackValue].self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected container to be type MessagePackValue.array"))
    }
    return MessagePackUnkeyedDecodingContainer(decoder: self, container: arrayValue)
  }

  func singleValueContainer() throws -> SingleValueDecodingContainer {
    guard let value = self.valuesToDecode.last else {
      preconditionFailure("BUG: _MessagePackDecoder expected value to decode but stack was empty")
    }
    return MessagePackSingleValueDecodingContainer(decoder: self, container: value, codingPath: self.codingPath)
  }
}

extension _MessagePackDecoder {
  func unbox<T : Decodable>(_ value: MessagePackValue, type: T.Type) throws -> T? {
    self.valuesToDecode.append(value) // this value is about to be decoded
    let decoded = try T(from: self) // we presume it will be decoded here
    self.valuesToDecode.removeLast() // it's been decoded now, so remove it from the stack
    return decoded
  }

  func unbox(_ value: MessagePackValue, type: Bool.Type) throws -> Bool {
    guard let boolValue = value.boolValue else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return boolValue
  }

  func unbox(_ value: MessagePackValue, type: Int.Type) throws -> Int {
    guard let intValue = value.intValue else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return intValue
  }

  func unbox(_ value: MessagePackValue, type: Int8.Type) throws -> Int8 {
    guard let intValue = value.int8Value else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return intValue
  }

  func unbox(_ value: MessagePackValue, type: Int16.Type) throws -> Int16 {
    guard let intValue = value.int16Value else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return intValue
  }

  func unbox(_ value: MessagePackValue, type: Int32.Type) throws -> Int32 {
    guard let intValue = value.int32Value else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return intValue
  }

  func unbox(_ value: MessagePackValue, type: Int64.Type) throws -> Int64 {
    guard let intValue = value.int64Value else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return intValue
  }

  func unbox(_ value: MessagePackValue, type: UInt.Type) throws -> UInt {
    guard let uintValue = value.uintValue else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return uintValue
  }

  func unbox(_ value: MessagePackValue, type: UInt8.Type) throws -> UInt8 {
    guard let uintValue = value.uint8Value else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return uintValue
  }

  func unbox(_ value: MessagePackValue, type: UInt16.Type) throws -> UInt16 {
    guard let uintValue = value.uint16Value else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return uintValue
  }

  func unbox(_ value: MessagePackValue, type: UInt32.Type) throws -> UInt32 {
    guard let uintValue = value.uint32Value else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return uintValue
  }
  
  func unbox(_ value: MessagePackValue, type: UInt64.Type) throws -> UInt64 {
    guard let uintValue = value.unsignedIntegerValue else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return uintValue
  }

  func unbox(_ value: MessagePackValue, type: Float.Type) throws -> Float {
    guard let floatValue = value.floatValue else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return floatValue
  }

  func unbox(_ value: MessagePackValue, type: Double.Type) throws -> Double {
    guard let doubleValue = value.doubleValue else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return doubleValue
  }

  func unbox(_ value: MessagePackValue, type: String.Type) throws -> String {
    guard let stringValue = value.stringValue else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unboxed value was not \(type)"))
    }
    return stringValue
  }
}

