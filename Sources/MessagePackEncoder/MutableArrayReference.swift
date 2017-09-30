//
//  MutableArrayReference.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 9/29/17.
//

/// MutableArrayReference is reference-typed wrapper around mutable Array
class MutableArrayReference<T> : MutableCollection, ExpressibleByArrayLiteral {

  var array: [T] = [T]()
  init() {}

  subscript(index: Int) -> T {
    get {
      return array[index]
    }
    set {
      array[index] = newValue
    }
  }

  var startIndex: Int { return array.startIndex }
  var endIndex: Int { return array.endIndex }
  func index(after: Int) -> Int {
    return array.index(after: after)
  }

  func append(_ newElement: T) {
    array.append(newElement)
  }

  func insert(_ newElement: T, at index: Int) {
    array.insert(newElement, at: index)
  }
  
  public required init(arrayLiteral elements: T...) {
    self.array = elements
  }
}

