//
//  Gpg.swift
//  zig
//
//  Created by Matt Gadda on 11/7/17.
//

import Foundation

struct Gpg {
  let maybeHomedir: URL?

  init(homedir: URL? = nil) {
    maybeHomedir = homedir
  }

  func sign(data: Data, keyName: String?) throws -> Data {
    let dataUrl = URL(fileURLWithPath: "/tmp/zigdata", isDirectory: false)
    let sigUrl = dataUrl.appendingPathExtension("sig")
    try data.write(to: dataUrl)

    var arguments = ["gpg"]
    if let keyName = keyName {
      arguments += ["--default-key", "\(keyName)!"]
    }
    if let homedir = maybeHomedir {
      arguments += ["--homedir", homedir.path]
    }
    arguments += ["--output", sigUrl.path, "--detach-sign", dataUrl.path]
    try! Shell.run(path: "/usr/bin/env", arguments: arguments)

    defer {
      // TODO: handle failures here with more grace
      try! FileManager.default.removeItem(at: dataUrl)
      try! FileManager.default.removeItem(at: sigUrl)
    }

    return try Data(contentsOf: sigUrl)
  }

  func verify(data: Data, signature: Data) throws -> Bool {
    let dataUrl = URL(fileURLWithPath: "/tmp/zigdata", isDirectory: false)
    let sigUrl = dataUrl.appendingPathExtension("sig")

    try data.write(to: dataUrl)
    try signature.write(to: sigUrl)

    let gpg = Process()
    gpg.launchPath = "/usr/bin/env"
    var arguments = ["gpg"]
    if let homedir = maybeHomedir {
      arguments += ["--homedir", homedir.path]
    }
    arguments += ["--verify", sigUrl.path, "/tmp/zigdata"]
    gpg.arguments = arguments

    let pipe = Pipe()
    gpg.standardOutput = pipe
    gpg.standardError = pipe

    gpg.launch()
    gpg.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()

    try FileManager.default.removeItem(at: sigUrl)
    try FileManager.default.removeItem(at: dataUrl)

    return String(data: data, encoding: .utf8)?.range(of: "Good") != nil
  }
}
