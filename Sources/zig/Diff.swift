//
//  Diff.swift
//  zig
//
//  Created by Matt Gadda on 11/24/17.
//
import Foundation

// apply as defined in: https://www.drivenbycode.com/the-missing-apply-function-in-swift/
func apply<T, U>(fn: (T...) -> U, args: [T]) -> U {
  typealias FunctionType = ([T]) -> U
  return withoutActuallyEscaping(fn) { fn2 in
    return unsafeBitCast(fn2, to: FunctionType.self)(args)
  }

}

// TODO: find more specific name for what is essentially a 2-tuple
// Maybe Node?
struct Object : Hashable {
  typealias Path = String
  typealias Id = Data

  enum FileType {
    case file, directory
    init?(from: String) {
      switch from {
      case "tree": self = .directory
      case "blob": self = .file
      default: return nil
      }
    }
  }

  let path: Object.Path
  let id: Object.Id
  let type: FileType

  var hashValue: Int {
    return id.hashValue ^ path.hashValue &* 16777619
  }

  static func ==(left: Object, right: Object) -> Bool {
    return left.id == right.id && left.path == right.path
  }
}


enum Diffable<T: Hashable> : Hashable {
  case left(T), right(T)

  var value: T {
    switch self {
    case let .left(o): return o
    case let .right(o): return o
    }
  }

  var left: T? {
    switch self {
    case let .left(o): return o
    default:
      return nil
    }
  }

  var right: T? {
    switch self {
    case let .right(o): return o
    default:
      return nil
    }
  }

  var hashValue: Int {
    switch self {
    case .left: return 0 ^ self.value.hashValue
    case .right: return 1 ^ self.value.hashValue
    }
  }

  func flatMap<U>(_ fn: (T) -> Diffable<U>) -> Diffable<U> {
    return fn(self.value)

  }

  func map<U>(_ fn: (T) -> U) -> Diffable<U> {
    switch self {
    case let .left(v): return Diffable<U>.left(fn(v))
    case let .right(v): return Diffable<U>.right(fn(v))
    }
  }
  
  static func ==(left: Diffable, right: Diffable) -> Bool {
    switch (left, right) {
    case (.left, .right): fallthrough
    case (.right, .left):
      return left.value == right.value
    default:
      return false
    }
  }
}

enum Change {
  case added(path: Object.Path, id: Object.Id, fileType: Object.FileType)
  case removed(path: Object.Path, id: Object.Id, fileType: Object.FileType)
  case modified(path: Object.Path, from: Object.Id, to: Object.Id, fromFileType: Object.FileType, toFileType: Object.FileType)
  case renamed(from: Object.Path, to: Object.Path, id: Object.Id, fromFileType: Object.FileType, toFileType: Object.FileType)
}

struct Diff {
  // Files deleted -- Includes files that were renamed. Probably not what you want.
  static func deleted(old: Set<Object>, new: Set<Object>) -> Set<Object> {
    return old.subtracting(new).subtracting(old.intersection(new))
  }

  // Files that changed
  static func changed(old: Set<Object>, new: Set<Object>) -> Set<Diffable<Object>> {
    let left = Set(old.map { Diffable.left($0) })
    let right = Set(new.map { Diffable.right($0) })
    return left.union(right).subtracting(right.intersection(left))
  }

  // Goal: tease about "changed" into added, removed, modified and renamed

  // Return Entries whose content has changed
  static func modified(old: Set<Object>, new: Set<Object>) -> [String : Set<Diffable<Object>>] {
    let groupedByName = changed(old: old, new: new).groupBy { $0.value.path }
    return groupedByName.filter { $1.count > 1 }
  }

  // Return Entries whose name changed. This also includes added files whose contents
  // are Object.Identical to files that have been removed
  static func renamed(old: Set<Object>, new: Set<Object>) -> [String : Set<Diffable<Object>>] {
    let groupedByObjectId = changed(old: old, new: new).groupBy { diffable -> String in
      diffable.value.id.base16EncodedString()
    }
    return groupedByObjectId.filter { $1.count > 1 }
  }

  static func added(old: Set<Object>, new: Set<Object>) -> Set<Diffable<Object>> {
    let left = Set(old.map { Diffable.left($0) })
    let right = Set(new.map { Diffable.right($0) })

    let mod = Set(modified(old: old, new: new).flatMap { $1 })
    let ren = Set(renamed(old: old, new: new).flatMap { $1 })

    return right.subtracting(left).subtracting(mod.union(ren))
  }

  // Return Entries that were removed. Excludes added files with the same content.
  static func removed(old: Set<Object>, new: Set<Object>) -> Set<Diffable<Object>> {
    let left = Set(old.map { Diffable.left($0) })
    let right = Set(new.map { Diffable.right($0) })

    let mod = Set(modified(old: old, new: new).flatMap { $1 })
    let ren = Set(renamed(old: old, new: new).flatMap { $1 })
    return left.subtracting(right).subtracting(mod.union(ren))
  }

//  func withUrls<T>(paths: String..., operation: (URL...) -> T) -> T {
//    let urls = paths.map { URL(fileURLWithPath: $0) }
//    defer {
//      urls.forEach { url in
//        try? FileManager.default.removeItem(at: url)
//      }
//    }
//    return apply(fn: operation, args: urls)
//  }

  static func compareBlobs(old: Blob, new: String) -> Data {
    let oldDataUrl = URL(fileURLWithPath: "/tmp/zigdata.old", isDirectory: false)

    try! old.content.write(to: oldDataUrl)

    let diff = Process()
    diff.launchPath = "/usr/bin/env"
    var arguments = ["diff", "-y", oldDataUrl.path, new]
    diff.arguments = arguments

    let pipe = Pipe()
    diff.standardOutput = pipe
    diff.standardError = pipe

    diff.launch()
    diff.waitUntilExit()

    let diffOutput = pipe.fileHandleForReading.readDataToEndOfFile()

    defer {
      try? FileManager.default.removeItem(at: oldDataUrl)
    }
    return diffOutput
  }

  static func compareBlobs(old: Blob, new: Blob) -> Data {
    let oldDataUrl = URL(fileURLWithPath: "/tmp/zigdata.old", isDirectory: false)
    let newDataUrl = URL(fileURLWithPath: "/tmp/zigdata.new", isDirectory: false)

    try! old.content.write(to: oldDataUrl)
    try! new.content.write(to: newDataUrl)

    let diff = Process()
    diff.launchPath = "/usr/bin/env"
    var arguments = ["diff", "-y", oldDataUrl.path, newDataUrl.path]
    diff.arguments = arguments

    let pipe = Pipe()
    diff.standardOutput = pipe
    diff.standardError = pipe

    diff.launch()
    diff.waitUntilExit()

    let diffOutput = pipe.fileHandleForReading.readDataToEndOfFile()

    defer {
      try? FileManager.default.removeItem(at: oldDataUrl)
      try? FileManager.default.removeItem(at: newDataUrl)
    }
    return diffOutput
  }
}


