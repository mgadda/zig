//
//  CommitView.swift
//  zig
//
//  Created by Matt Gadda on 9/16/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

class CommitView : Sequence {
  let repository: Repository
  init(repository: Repository) {
    self.repository = repository
  }

  func makeIterator() -> CommitIterator {
    if let headId = repository.getHeadId() {
        return CommitIterator(headId, repository: repository)
    } else {
      print("No commits yet")
      return CommitIterator(nil, repository: repository)
    }
  }
}

struct CommitIterator : IteratorProtocol {
  var maybeNextObjectId: Data?
  let repository: Repository

  init(_ objectId: Data?, repository: Repository) {
    self.maybeNextObjectId = objectId
    self.repository = repository
  }
  
  mutating func next() -> Commit? {
    guard
      let nextObjectId = maybeNextObjectId,
      let object = repository.readObject(id: nextObjectId) else {
        return nil
    }

    switch object {
      case let commit as Commit:
        maybeNextObjectId = commit.parentId
        return commit
      default: break
    }
    return nil
  }
}
