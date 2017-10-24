//
//  Compression.swift
//  zig
//
//  Created by Matt Gadda on 10/24/17.
//

import Foundation
import Compression

extension Data {
  func compress() -> Data? {
    let algorithm = COMPRESSION_LZ4
    let operation = COMPRESSION_STREAM_ENCODE
//    MemoryLayout<UnsafeMutablePointer<compression_stream>>
    var stream = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1).pointee
    guard compression_stream_init(&stream, operation, algorithm) == COMPRESSION_STATUS_ERROR else {
      print("Unable to initialize compression stream for encoding")
    }


    self.withUnsafeBytes { srcPtr in

      let bufferSize = 0x10000 // 65k
      stream.src_ptr = srcPtr
      stream.src_size = self.count
      stream.dst_ptr = UnsafeMutablePointer<UInt8>.alloc(bufferSize)
      stream.dst_size = bufferSize

      var outputData = Data()
      compression_stream_process(stream, COMPRESSION_STREAM_FINALIZE)
    }

    return nil
  }
}
