//
//  BoxedValue.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 9/30/17.
//

import Foundation
import MessagePack

// This enum exists solely to ensure that array and map contain reference-type
// associated values.
internal indirect enum BoxedValue {
  case `nil`
  case bool(Bool)
  case int(Int64)
  case uint(UInt64)
  case float(Float)
  case double(Double)
  case string(String)
  case binary(Data)
  case array(MutableArrayReference<BoxedValue>)
  case map(MutableDictionaryReference<BoxedValue, BoxedValue>)
  case extended(Int8, Data)

  init(messagePackValue: MessagePackValue) {
    switch messagePackValue {
    case .`nil`: self = .`nil`
    case let .bool(b): self = .bool(b)
    case let .int(i): self = .int(i)
    case let .uint(ui): self = .uint(ui)
    case let .float(f): self = .float(f)
    case let .double(d): self = .double(d)
    case let .string(s): self = .string(s)
    case let .binary(b): self = .binary(b)
    case let .array(array):
      let arrayRef = MutableArrayReference<BoxedValue>()
      arrayRef.array = array.map { BoxedValue(messagePackValue: $0) }
      self = .array(arrayRef)
    case let .map(dict):
      let dictRef = MutableDictionaryReference<BoxedValue, BoxedValue>()

      for (key, value) in dict {
        dictRef[BoxedValue(messagePackValue: key)] = BoxedValue(messagePackValue: value)
      }
      self = .map(dictRef)
    case let .extended(type, data): self = .extended(type, data)
    }
  }
}

func ==(left: MutableDictionaryReference<BoxedValue, BoxedValue>, right: MutableDictionaryReference<BoxedValue, BoxedValue>) -> Bool {
  return left.dictionary == right.dictionary
}

func ==(left: MutableArrayReference<BoxedValue>, right: MutableArrayReference<BoxedValue>) -> Bool {
  return left.array == right.array
}

extension BoxedValue: Equatable {
  public static func ==(lhs: BoxedValue, rhs: BoxedValue) -> Bool {
    switch (lhs, rhs) {
    case (.nil, .nil):
      return true
    case (.bool(let lhv), .bool(let rhv)):
      return lhv == rhv
    case (.int(let lhv), .int(let rhv)):
      return lhv == rhv
    case (.uint(let lhv), .uint(let rhv)):
      return lhv == rhv
    case (.int(let lhv), .uint(let rhv)):
      return lhv >= 0 && UInt64(lhv) == rhv
    case (.uint(let lhv), .int(let rhv)):
      return rhv >= 0 && lhv == UInt64(rhv)
    case (.float(let lhv), .float(let rhv)):
      return lhv == rhv
    case (.double(let lhv), .double(let rhv)):
      return lhv == rhv
    case (.string(let lhv), .string(let rhv)):
      return lhv == rhv
    case (.binary(let lhv), .binary(let rhv)):
      return lhv == rhv
    case (.array(let lhv), .array(let rhv)):
      return lhv == rhv
    case (.map(let lhv), .map(let rhv)):
      return lhv == rhv
    case (.extended(let lht, let lhb), .extended(let rht, let rhb)):
      return lht == rht && lhb == rhb
    default:
      return false
    }
  }
}

extension BoxedValue: Hashable {
  public var hashValue: Int {
    switch self {
    case .nil: return 0
    case .bool(let value): return value.hashValue
    case .int(let value): return value.hashValue
    case .uint(let value): return value.hashValue
    case .float(let value): return value.hashValue
    case .double(let value): return value.hashValue
    case .string(let string): return string.hashValue
    case .binary(let data): return data.count
    case .array(let array): return array.count
    case .map(let dict): return dict.dictionary.count
    case .extended(let type, let data): return 31 &* type.hashValue &+ data.count
    }
  }
}

extension MessagePackValue {
  init(boxedValue: BoxedValue) {
    switch boxedValue {
    case .`nil`: self = .`nil`
    case let .bool(b): self = .bool(b)
    case let .int(i): self = .int(i)
    case let .uint(ui): self = .uint(ui)
    case let .float(f): self = .float(f)
    case let .double(d): self = .double(d)
    case let .string(s): self = .string(s)
    case let .binary(b): self = .binary(b)
    case let .array(arrayRef):
      self = .array(arrayRef.array.map { MessagePackValue(boxedValue: $0) })
    case let .map(dictRef):
      var mpDict = [MessagePackValue : MessagePackValue](minimumCapacity: dictRef.dictionary.count)
      for (key, value) in dictRef.dictionary {
        mpDict[MessagePackValue(boxedValue: key)] = MessagePackValue(boxedValue: value)
      }
      self = .map(mpDict)
    case let .extended(type, data): self = .extended(type, data)
    }
  }
}
