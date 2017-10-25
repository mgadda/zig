//
//  Compression.swift
//  zig
//
//  Created by Matt Gadda on 10/24/17.
//

import Foundation
import Compression

extension Data {

  private func executeStream(operation: compression_stream_operation) -> Data? {
    let algorithm = COMPRESSION_ZLIB

    var stream = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1).pointee
    guard compression_stream_init(&stream, operation, algorithm) != COMPRESSION_STATUS_ERROR else {
      print("Unable to initialize compression stream for encoding")
      return nil
    }

    return self.withUnsafeBytes { (srcPtr: UnsafePointer<UInt8>) -> Data? in

      let bufferSize = 0x10000 // 64k
      let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
      stream.src_ptr = srcPtr
      stream.src_size = self.count
      stream.dst_ptr = buffer
      stream.dst_size = bufferSize

      let flags = operation == COMPRESSION_STREAM_ENCODE ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0

      var output = Data()
      while true {
        let result = compression_stream_process(&stream, flags)
        switch result {
        case COMPRESSION_STATUS_OK:
          guard stream.dst_size == 0 else {
            continue
          }
          output.append(stream.dst_ptr, count: stream.dst_size)
          stream.dst_ptr = buffer
          stream.dst_size = bufferSize

        case COMPRESSION_STATUS_ERROR:
          print("Failed to compress Data")
          return nil
        case COMPRESSION_STATUS_END:
          guard stream.dst_ptr > buffer else {
            continue
          }
          output.append(buffer, count: stream.dst_ptr - buffer)
          return output
        default:
          print("BUG: Unexpected status returned by compression_stream_process")
          return nil
        }
      }
    }
  }

  func uncompress() -> Data? {
    return executeStream(operation: COMPRESSION_STREAM_DECODE)
  }
  func compress() -> Data? {
    return executeStream(operation: COMPRESSION_STREAM_ENCODE)
  }
}
