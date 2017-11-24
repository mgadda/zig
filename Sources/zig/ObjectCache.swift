//
//  ObjectCache.swift
//  zigPackageDescription
//
//  Created by Matt Gadda on 11/19/17.
//

import Foundation

/// Provides in-memory caching of filepaths to object ids.
/// Any operation that instantiates an object should write resulting it through
/// this cache
class ObjectCache {
  init() {}

  var cache: [String : Data] = [:]

  func read(filePath: String) -> Data? {
    return cache[filePath]
  }
  func write(filePath: String, object: Data) {
    cache[filePath] = object
  }
}
