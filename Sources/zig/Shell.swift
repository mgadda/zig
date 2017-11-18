//
//  Shell.swift
//  zigPackageDescription
//
//  Created by Matt Gadda on 11/14/17.
//

import Foundation

struct Shell {
  /// Run command at `path` with `arguments`. `run` does not use `Process`
  /// because it does not correctly set up `STDIN`, `STDOUT`, `STDERR` for the
  /// child process. Instead it uses posix_spawn directly.
  static func run(path: String, arguments: [String]) throws {
    var pid: pid_t = pid_t()
    let cPath = strdup("/usr/bin/env")
    let cArgs = ([path] + arguments).map { $0.withCString { strdup($0) }} + [nil]
    let cEnv = ProcessInfo.processInfo.environment.map { (key, value) in strdup("\(key)=\(value)") } + [nil]

    defer {
      free(cPath)
      cEnv.forEach { free($0) }
      cArgs.forEach { free($0) }
    }

    #if os(macOS)
      var fileActions: posix_spawn_file_actions_t? = nil
    #else
      var fileActions = posix_spawn_file_actions_t()
    #endif

    posix_spawn_file_actions_init(&fileActions)

    //  posix_spawn_file_actions_addinherit_np(&fileActions, STDIN_FILENO)
    posix_spawn_file_actions_adddup2(&fileActions, 0, 0)
    posix_spawn_file_actions_adddup2(&fileActions, 1, 1)
    posix_spawn_file_actions_adddup2(&fileActions, 2, 2)

    guard posix_spawn(&pid, cPath, &fileActions, nil, cArgs, cEnv) != -1 else {
      throw ZigError.genericError("Failed to execute \(path)")
    }

    var res: Int32 = 0
    waitpid(pid, &res, 0)
    guard res == 0 else {    
      throw ZigError.shellError(res)
    }
  }

  static func replace(with path: String, arguments: [String]) throws {
    let cPath = path.withCString { strdup($0) }
    let cArgs = arguments.map { $0.withCString { strdup($0) }} + [nil]
    guard execv(cPath, cArgs) != -1 else {
      let scriptName = String(describing: path.split(separator: "/").last)
      throw ZigError.genericError("Failed to load \(scriptName) with error \(errno)")
    }
  }
}

