//
//  CMPEncoder.swift
//  zig
//
//  Created by Matt Gadda on 10/28/17.
//

import Foundation
import CMP

protocol Serializable {
  func serialize(encoder: CMPEncoder)
//  static func deserialize(with decoder: CMPDecoder) -> Self
  init(with decoder: CMPDecoder) throws
}

func cmpWriter(ctx: UnsafeMutablePointer<cmp_ctx_s>!, data: UnsafeRawPointer!, count: Int) -> Int {
  let cmpJump = ctx.pointee.buf.bindMemory(to: CMPJump.self, capacity: 1).pointee
  if let encoder = cmpJump.encoder {
    return encoder.write(data, count)
  }
  return 0
}

func cmpSkipper(ctx: UnsafeMutablePointer<cmp_ctx_s>!, count: Int) -> Bool {
  let cmpJump = ctx.pointee.buf.bindMemory(to: CMPJump.self, capacity: 1).pointee
  if let encoder = cmpJump.encoder {
    return encoder.skip(count: count)
  } else if let decoder = cmpJump.decoder {
    return decoder.skip(count: count)
  }

  return false
}

func cmpReader(ctx: UnsafeMutablePointer<cmp_ctx_s>!, data: UnsafeMutableRawPointer!, limit: Int) -> Bool {
  let cmpJump = ctx.pointee.buf.bindMemory(to: CMPJump.self, capacity: 1).pointee
  if let decoder = cmpJump.decoder {
    return decoder.read(data, count: limit)
  }

  return false
}

fileprivate struct CMPJump {
  var encoder: CMPEncoder?
  var decoder: CMPDecoder?
  init() {}
}

// TODO: why is this necessary?
class CMPKeyedDecoderContainer {
  fileprivate var container: [String : Serializable] = [:]
  func write<T: Serializable>(key: String, value: T) {
    container[key] = value
  }
}

class CMPEncoder {
  var context = cmp_ctx_t()
  var buffer = Data()

  let userContext: Any?

  var bufferPosition = 0 // used for reading/skipping
  fileprivate var jump: CMPJump

  init(userContext: Any? = nil) {
    self.userContext = userContext
    jump = CMPJump()
    jump.encoder = self
    // `this` is guaranteed to be as valid as long as `self`
    withUnsafeMutablePointer(to: &jump) { (ptr) -> Void in
      cmp_init(&context, ptr, nil, cmpSkipper, cmpWriter)
    }
  }

  func read(_ data: UnsafeMutableRawPointer, count: Int) -> Bool {
    let range: Range<Int> = bufferPosition..<(bufferPosition + count)
    buffer.copyBytes(to: data.bindMemory(to: UInt8.self, capacity: count), from: range)
    bufferPosition += count
    return true
  }

  /// Append data to CMPEncoder's internal buffer
  func write(_ data: UnsafeRawPointer, _ count: Int) -> Int {
    // if this is too slow, we need to blit memory with copyBytes and using bufferPosition
    buffer.append(data.bindMemory(to: UInt8.self, capacity: count), count: count)
    return count
  }

  func skip(count: Int) -> Bool {
    bufferPosition += count
    return true
  }

  func write(_ value: Int) {
    cmp_write_s64(&context, Int64(value))
  }

  func write(_ value: Int64) {
    cmp_write_s64(&context, value)
  }

  func write(_ value: Double) {
    cmp_write_double(&context, value)
  }

  func write(_ value: Data) {
    value.withUnsafeBytes { ptr -> Void in
      cmp_write_bin(&context, ptr, UInt32(value.count))
    }
  }

  func write<T: Serializable>(_ value: T) {
    value.serialize(encoder: self)
  }

  func write<T: Serializable>(_ values: [T]) {
    cmp_write_array(&context, UInt32(values.count))
    values.forEach { value -> Void in
      value.serialize(encoder: self)
    }
  }

  func write<T: Serializable>(_ values: [String : T?]) {
    cmp_write_map(&context, UInt32(values.count))
    values.forEach { (key, value) in
      guard value != nil else { return }
      key.serialize(encoder: self)
      value!.serialize(encoder: self)
    }
  }

  func write(_ value: String) {
    let data = value.data(using: .utf8)!
    _ = data.withUnsafeBytes({ bytes in
      cmp_write_str(&context, bytes, UInt32(data.count))
    })
  }

  func keyedContainer() -> CMPKeyedDecoderContainer {
    return CMPKeyedDecoderContainer()
  }

  func write(_ value: CMPKeyedDecoderContainer) {
    cmp_write_map(&context, UInt32(value.container.count))
    value.container.forEach { key, value in
      write(key)
      value.serialize(encoder: self)
    }
  }
}

class CMPDecoder {
  var context = cmp_ctx_t()
  var buffer: Data
  let userContext: Any?

  var bufferPosition = 0 // used for reading/skipping
  fileprivate var jump: CMPJump

  init(from buffer: Data, userContext: Any? = nil) {
    self.buffer = buffer
    self.userContext = userContext

    jump = CMPJump()
    jump.decoder = self

    // `this` is guaranteed to be as valid as long as `self`
    withUnsafeMutablePointer(to: &jump) { (ptr) -> Void in
      cmp_init(&context, ptr, cmpReader, cmpSkipper, nil)
    }

  }

  func read(_ data: UnsafeMutableRawPointer, count: Int) -> Bool {
    let range: Range<Int> = bufferPosition..<(bufferPosition + count)
    buffer.copyBytes(to: data.bindMemory(to: UInt8.self, capacity: count), from: range)
    bufferPosition += count
    return true
  }

  func skip(count: Int) -> Bool {
    bufferPosition += count
    return true
  }

  func read() -> Int {
    var value: Int64 = 0
    cmp_read_s64(&context, &value)

    // TODO: correctly handle decoding 64-bit ints on 32-bit systems
    return Int(value)
  }

  func read() -> Int64 {
    var value: Int64 = 0
    cmp_read_s64(&context, &value)
    return value
  }

  func read() -> Double {
    var value: Double = 0.0
    cmp_read_double(&context, &value)
    return value
  }

  func read() -> Data {
    var size: UInt32 = 0
    freezingPosition { cmp_read_bin_size(&context, &size) }
    var value = Data(count: Int(size)) // TODO: potential data loss here for values > Int.max and < UInt32.max
    let _ = value.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<UInt8>) -> Bool in
      cmp_read_bin(&context, ptr, &size)
    }
    return value
  }

  func freezingPosition(fn: () -> Void) {
    let oldBufferPosition = bufferPosition
    fn()
    bufferPosition = oldBufferPosition
  }

  func read() throws -> String {
    var size: UInt32 = 0
    freezingPosition { cmp_read_str_size(&context, &size) }
    size += 1 // cmp_read_str apparently expects this
    var value = Data(count: Int(size)) // TODO: potential data loss here for values > Int.max and < UInt32.max
    let result = value.withUnsafeMutableBytes { ptr in
      cmp_read_str(&context, ptr, &size)
    }

    if !result {
      throw ZigError.decodingError("Error code \(context.error)")
    }

    return String(data: value.subdata(in: 0..<(value.count - 1)), encoding: .utf8)!
  }

  /// Read a homoegeneous array of values
  func read<T : Serializable>() throws -> [T] {
    var size: UInt32 = 0
    cmp_read_array(&context, &size)
    return try Array((0..<size)).map { (_) -> T in
      try T(with: self)
    }
  }

  /// Read heterogeneous dictionary of Serializable values
  func read(_ fields: [String : Serializable.Type]) throws -> [String : Any] {
    var size: UInt32 = 0
    cmp_read_map(&context, &size)
    let keysAndValues = try Array((0..<size)).flatMap { (_) -> (String, Serializable) in
      let key = try String(with: self)
      let value = (try fields[key]?.init(with: self))!
      return (key, value)
    }
    return Dictionary<String, Serializable>(uniqueKeysWithValues: keysAndValues)
  }

  /// Deserialize a homogeneous map of String -> T (probably of limited utility)
  /// This method should not be confused with a type-less keyed decoding container
  func read<T : Serializable>() throws -> [String : T] {
    var size: UInt32 = 0
    cmp_read_map(&context, &size)
    let keysAndValues = try Array((0..<size)).flatMap { (_) -> (String, T) in
      (try String(with: self), try T(with: self))
    }
    return Dictionary<String, T>(uniqueKeysWithValues: keysAndValues)
  }
}

extension Data : Serializable {
  func serialize(encoder: CMPEncoder) {
    encoder.write(self)
  }
  init(with decoder: CMPDecoder) throws {
    self = decoder.read()
  }
}

extension String : Serializable {
  func serialize(encoder: CMPEncoder) {
    encoder.write(self)
  }
  init(with decoder: CMPDecoder) throws {
    self = try decoder.read()
  }
}

extension Double : Serializable {
  func serialize(encoder: CMPEncoder) {
    encoder.write(self)
  }
  init(with decoder: CMPDecoder) throws {
    self = decoder.read()
  }
}

extension Int : Serializable {
  func serialize(encoder: CMPEncoder) {
    encoder.write(self)
  }
  init(with decoder: CMPDecoder) throws {
    self = decoder.read()
  }
}

func cmpFileWriter(ctx: UnsafeMutablePointer<cmp_ctx_s>!, data: UnsafeRawPointer!, count: Int) -> Int {
  let fileHandlePtr = ctx.pointee.buf.bindMemory(to: FileHandle.self, capacity: 1)
  fileHandlePtr.pointee.write(Data(bytes: data, count: count))
  return count
}

func cmpFileSkipper(ctx: UnsafeMutablePointer<cmp_ctx_s>!, count: Int) -> Bool {
  let fileHandlePtr = ctx.pointee.buf.bindMemory(to: FileHandle.self, capacity: 1)
  fileHandlePtr.pointee.seek(toFileOffset: UInt64(count))
  return true
}

func cmpFileReader(ctx: UnsafeMutablePointer<cmp_ctx_s>!, data: UnsafeMutableRawPointer!, limit: Int) -> Bool {
  let fileHandlePtr = ctx.pointee.buf.bindMemory(to: FileHandle.self, capacity: 1)
  fileHandlePtr.pointee
    .readData(ofLength: limit)
    .copyBytes(to: data.bindMemory(to: UInt8.self, capacity: limit), count: limit)
  return true
}
