//
//  Reference.swift
//  zig
//
//  Created by Matt Gadda on 10/23/17.
//

indirect enum Reference {
  case unknown(String)
  case head
  case branch(String)
  case tag(String)
  case commit(String)

  var fullyQualifiedName: String {
    switch self {
    case let .unknown(name): return name
    case .head: return "HEAD"
    case let .branch(name): return "refs/heads/\(name)"
    case let .tag(name): return "refs/tags/\(name)"
    case let .commit(id): return id
    }
  }

  func description() -> String {
    return fullyQualifiedName
  }

  func resolve(repository: Repository) -> Reference? {
    return repository.resolve(self)
  }

  var unknown: String? {
    if case let .unknown(value) = self {
      return value
    } else {
      return nil
    }
  }

  var head: Bool {
    if case .head = self {
      return true
    } else {
      return false
    }
  }

  var branch: String? {
    if case let .branch(value) = self {
      return value
    } else {
      return nil
    }
  }

  var tag: String? {
    if case let .tag(value) = self {
      return value
    } else {
      return nil
    }
  }

  var commit: String? {
    if case let .commit(value) = self {
      return value
    } else {
      return nil
    }
  }
}
