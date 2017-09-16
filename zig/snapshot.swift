//
//  snapshot.swift
//  zig
//
//  Created by Matt Gadda on 9/14/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

import Foundation

func snapshotAgainst(treeId: Data) {

}

func snapshotAll(startingAt dir: URL) -> Treeish {
  let urls = try! FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [], options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)

  let entries = urls.map { (url: URL) -> Entry in
    let attributes = try! FileManager.default.attributesOfItem(atPath: url.path)
    let perms = attributes[FileAttributeKey.posixPermissions] as? Int ?? 0

    let treeish: Treeish
    if url.hasDirectoryPath {

      // recurse to produce treeish
      treeish = snapshotAll(startingAt: url)
    } else {
      treeish = Treeish.blob(content: try! Data(contentsOf: url))
    }
    treeish.writeObject()
    return Entry(permissions: perms, treeishId: treeish.id, name: url.lastPathComponent)
  }

  let topLevelTree = Treeish.tree(entries: entries)
  topLevelTree.writeObject()
  return topLevelTree
}
