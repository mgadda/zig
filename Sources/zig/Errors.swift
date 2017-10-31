//
//  Errors.swift
//  zig
//
//  Created by Matt Gadda on 9/16/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

enum ZigError : Error {
  case dataError(String)
  case genericError(String)
  case decodingError(String)
}
