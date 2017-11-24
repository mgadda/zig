# Zig

A simple tool for tracking changes to your files.

Zig employs the same underlying storage concepts as git but provides
a much easier command line interface.

## Features

* Secure commits using gpg
* Simple command line interface
* Scriptable via JSON output


## Current status

At the risk of scaring potential useres away, it's critical to note that **Zig is not ready for production use**. It's entirely possible the object storage format may change as well as the command line interface. That said, if you're interested in contributing or even just critizing, shoot me a [tweet or DM](https://twitter.com/mgadda).

## How to use

For now, you'll need to be running macOS and (probably) Xcode 8 or higher.
```
git clone https://github.com/mgadda/zig.git
cd zig
xcodebuild
```

### Dependencies

These tools must be installed and present in your path.

* jq 1.4 or higher
* A recent version of GnuPG

If all goes well, zig will be placed in your `~/bin` directory, which is hopefully in your shell's $PATH.

### Commands

**Initialize repository**: `zig init`  
**Save your changes**: `zig snapshot`  
**View a history of changes**: `zig log`  
**View files which have changed since last snapshot**: `zig status`  
**Ignore a file, directory or glob:** `zig ignore [filename]`  
**Create a branch:** `zig branch [name]`  
**Create a tag:** `zig tag [name] [branch]|[commit-id]|[tag]|HEAD`  
**Checkout a commit or branch:** `zig checkout [commit]|[branch]`

### Low-level commands

**View object from database:**: `zig cat commit|tree|blob [object-id] [--json]`  
**View raw object data from database:** `zig rawcat [object-id] | hexdump`  
**Resolve a string into a commit:** `zig resolve [branch]|[commit-id]|[tag]|HEAD`  
**Store a file or tree of files in the database:** `zig hash [file]|[directory]`

