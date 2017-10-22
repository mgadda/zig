//
//  MessagePackValue.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 10/8/17.
//

import Foundation
import MessagePack

extension MessagePackValue {
  // MARK: Signed Integers

  public var intValue: Int? {
    switch self {
    case let .int(intValue): return Int(exactly: intValue)
    case let .uint(uintValue): return Int(exactly: uintValue)
    default: return nil
    }
  }

  public var int8Value: Int8? {
    switch self {
    case let .int(intValue): return Int8(exactly: intValue)
    case let .uint(uintValue): return Int8(exactly: uintValue)
    default: return nil
    }
  }

  public var int16Value: Int16? {
    switch self {
    case let .int(intValue): return Int16(exactly: intValue)
    case let .uint(uintValue): return Int16(exactly: uintValue)
    default: return nil
    }
  }

  public var int32Value: Int32? {
    switch self {
    case let .int(intValue): return Int32(exactly: intValue)
    case let .uint(uintValue): return Int32(exactly: uintValue)
    default: return nil
    }
  }

  public var int64Value: Int64? {
    switch self {
    case let .int(intValue): return intValue
    case let .uint(uintValue): return Int64(exactly: uintValue)
    default: return nil
    }
  }

  // MARK: Unsigned Integers

    public var uintValue: UInt? {
        switch self {
        case let .int(intValue): return UInt(exactly: intValue)
        case let .uint(uintValue): return UInt(exactly: uintValue)
        default: return nil
        }
    }

  public var uint8Value: UInt8? {
    switch self {
    case let .int(intValue): return UInt8(exactly: intValue)
    case let .uint(uintValue): return UInt8(exactly: uintValue)
    default: return nil
    }
  }

  public var uint16Value: UInt16? {
    switch self {
    case let .int(intValue): return UInt16(exactly: intValue)
    case let .uint(uintValue): return UInt16(exactly: uintValue)
    default: return nil
    }
  }

  public var uint32Value: UInt32? {
    switch self {
    case let .int(intValue): return UInt32(exactly: intValue)
    case let .uint(uintValue): return UInt32(exactly: uintValue)
    default: return nil
    }
  }

  public var uint64Value: UInt64? {
    switch self {
    case let .int(intValue): return UInt64(exactly: intValue)
    case let .uint(uintValue): return uintValue
    default: return nil
    }
  }

  

}
