//
//  TypedMutableDictionary.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 9/28/17.
//

import Foundation
import MessagePack

/// MutableDictionaryReference is reference-typed wrapper around mutable Dictionary
internal class MutableDictionaryReference<K : Hashable, V> : ExpressibleByDictionaryLiteral {
  var dictionary = [K : V]()

  init() {}

  subscript(key: K) -> V? {
    get {
      return dictionary[key]
    }
    set {
      dictionary[key] = newValue
    }
  }

  public convenience required init(dictionaryLiteral elements: (K, V)...) {
    self.init()
    for (key, value) in elements {
      dictionary[key] = value
    }
  }  
}
