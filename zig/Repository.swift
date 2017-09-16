//
//  Repository.swift
//  zig
//
//  Created by Matt Gadda on 9/16/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

// TODO: move this into a Repository class
func getHeadId() -> Data? {
  let rootURL = getRepositoryRoot()!
  let HEADURL = rootURL.appendingPathComponent(".zig").appendingPathComponent("HEAD")
  if let file = FileHandle(forUpdatingAtPath: HEADURL.path) {
    return String(data: file.readDataToEndOfFile(), encoding: .utf8)?.base16DecodedData()
  }
  return nil
}
