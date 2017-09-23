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
    if case let .commit(headId)? = repository.resolve(.head) {
        return CommitIterator(headId.base16DecodedData(), repository: repository)
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
      let commit = repository.readObject(id: nextObjectId, type: Commit.self) else {
        return nil
    }

    
    maybeNextObjectId = commit.parentId
    return commit
  }
}
