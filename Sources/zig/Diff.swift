//
//  Diff.swift
//  zig
//
//  Created by Matt Gadda on 11/24/17.
//
import Foundation

// TODO: find more specific name for what is essentially a 2-tuple
struct Object : Hashable {
  let path: String
  let id: Data
  var hashValue: Int {
    return id.hashValue ^ path.hashValue &* 16777619
  }

  static func ==(left: Object, right: Object) -> Bool {
    return left.id == right.id && left.path == right.path
  }
}

struct Diff {
  // Files deleted -- includes files that were renamed
  static func deleted(old: Set<Object>, new: Set<Object>) -> Set<Object> {
    return old.subtracting(new).subtracting(old.intersection(new))
  }

  // Files that changed
  static func changed(old: Set<Object>, new: Set<Object>) -> Set<Object> {
    return old.union(new).subtracting(new.intersection(old))
  }

  // Goal: tease about "changed" into added, removed, modified and renamed

  // Return Entries whose content has changed
  static func modified(old: Set<Object>, new: Set<Object>) -> [String : Set<Object>] {
    let groupedByName = changed(old: old, new: new).groupBy { ($0.path, $0) }
    return groupedByName.filter { $1.count > 1 }/*.mapValues { (values) in
     return values.map { $0.id }.joined(separator: " <-> ")
     }*/
  }

  // Return Entries whose name changed. This also includes added files whose contents
  // are identical to files that have been removed
  static func renamed(old: Set<Object>, new: Set<Object>) -> [String : Set<Object>] {
    let groupedById = changed(old: old, new: new).groupBy { ($0.id.base16EncodedString(), $0) }
    return groupedById.filter { $1.count > 1 }/*.mapValues { values in
     return values.map { $0.path }.joined(separator: " <-> ")
     }*/
  }

  static func added(old: Set<Object>, new: Set<Object>) -> Set<Object> {
    let mod = Set(modified(old: old, new: new).flatMap { $1 })
    let ren = Set(renamed(old: old, new: new).flatMap { $1 })
    return new.subtracting(old).subtracting(mod.union(ren))
  }

  // Return Entries that were removed. Excludes added files with the same content.
  static func removed(old: Set<Object>, new: Set<Object>) -> Set<Object> {
    let mod = Set(modified(old: old, new: new).flatMap { $1 })
    let ren = Set(renamed(old: old, new: new).flatMap { $1 })
    return old.subtracting(new).subtracting(mod.union(ren))
  }
}

enum Change {
  typealias ObjectPath = String
  typealias ObjectId = Data
  case added(ObjectPath, ObjectId)
  case removed(ObjectPath, ObjectId)
  case modified(ObjectPath, from: ObjectId, to: ObjectId)
  case renamed(from: ObjectPath, to: ObjectPath, id: ObjectId)
}
