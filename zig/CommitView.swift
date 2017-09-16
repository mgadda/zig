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

  func makeIterator() -> TreeishIterator {
    if let headId = repository.getHeadId() {
        return TreeishIterator(headId, repository: repository)
    } else {
      print("No commits yet")
      return TreeishIterator(nil, repository: repository)
    }
  }
}

struct TreeishIterator : IteratorProtocol {
  var maybeNextTreeishId: Data?
  let repository: Repository

  init(_ treeishId: Data?, repository: Repository) {
    self.maybeNextTreeishId = treeishId
    self.repository = repository
  }
  
  mutating func next() -> Treeish? {
    guard let nextTreeishId = maybeNextTreeishId else {
      return nil
    }

    let commit = repository.readObject(id: nextTreeishId)
    switch commit {
      case .some(.commit(let parentId, _, _, _, _)):
        maybeNextTreeishId = parentId
        return commit
      default:
        return nil
    }
  }
}
