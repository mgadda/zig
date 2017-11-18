//
//  Config.swift
//  zig
//
//  Created by Matt Gadda on 11/5/17.
//

import Foundation

struct Config : Codable {
  let author: Author
  var gpg: GPGConfig?
}

struct GPGConfig : Codable {
  var homedir: URL?
  let key: String?
}

