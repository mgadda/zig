//
//  ObjectLike.swift
//  zig
//
//  Created by Matt Gadda on 9/16/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation
import CryptoSwift

protocol ObjectLike : Codable, Serializable {
  var type: String { get }
  var id: Data { get }
  func description(repository: Repository, verbose: Bool) -> String
}

extension ObjectLike {
  func hash(data: Data) -> Data {
    return data.sha1()    
  }
}
