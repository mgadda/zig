//
//  MessagePackKey.swift
//  MessagePackEncoder
//
//  Created by Matt Gadda on 9/27/17.
//

import Foundation

internal struct MessagePackKey : CodingKey {
  public var stringValue: String
  public var intValue: Int?

  public init?(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = nil
  }

  public init?(intValue: Int) {
    self.stringValue = "\(intValue)"
    self.intValue = intValue
  }

  internal init(index: Int) {
    self.stringValue = "index=\(index)"
    self.intValue = index
  }

  internal static let superKey = MessagePackKey(stringValue: "super")!
}
