//
//  Set.swift
//  zig
//
//  Created by Matt Gadda on 11/24/17.
//

extension Set {
  func groupBy<S: Hashable, T: Hashable>(fn: (Element) -> (S, T)) -> [S : Set<T>] {
    var groups: [S : Set<T>] = [:]
    self.forEach { element in
      let (key, value) = fn(element)
      let s = Set<T>([value])

      groups.merge([key : s]) { $0.union($1) }
    }
    return groups
  }

  func groupBy<S: Hashable>(fn: (Element) -> S) -> [S : Set<Element>] {
    return groupBy { element in
      (fn(element), element)
    }
  }
}

