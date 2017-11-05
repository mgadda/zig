//
//  Glob.swift
//  zig
//
//  Created by Matt Gadda on 11/2/17.
//

import Foundation

func glob(pattern: String, relativeTo: URL) -> [URL] {
  let matches = pattern.data(using: .utf8)!.withUnsafeBytes({ (patternBytes: UnsafePointer<Int8>) -> Array<String> in
    var globData = glob_t()
    glob(patternBytes, GLOB_BRACE, nil, &globData)

    
    let unsafeMatches = UnsafeBufferPointer(start: globData.gl_pathv, count: Int(globData.gl_matchc))
    let unsafeStrings = unsafeMatches.map { (matchPtr: UnsafeMutablePointer<Int8>!) -> String in
      let data = Data(bytes: matchPtr, count: strlen(matchPtr))
      return String(data: data, encoding: .utf8)!
    }
    globfree(&globData)
    return Array(unsafeStrings)
  })

  return matches.map {
    return URL(fileURLWithPath: $0, relativeTo: relativeTo).standardizedFileURL
  }
}

func glob(patterns: [String], relativeTo: URL) -> [URL] {
  return glob(pattern: "{" + patterns.joined(separator: ",") + "}", relativeTo: relativeTo)
}
