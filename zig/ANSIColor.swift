//
//  ANSIColor.swift
//  zig
//
//  Created by Matt Gadda on 9/16/17.
//  Copyright © 2017 Matt Gadda. All rights reserved.
//

enum ANSIColor : String {
  case black = "\u{001B}[0;30m"
  case red = "\u{001B}[0;31m"
  case green = "\u{001B}[0;32m"
  case yellow = "\u{001B}[0;33m"
  case blue = "\u{001B}[0;34m"
  case magenta = "\u{001B}[0;35m"
  case cyan = "\u{001B}[0;36m"
  case white = "\u{001B}[1;37m"
  case gray = "\u{001B}[0;37m"
  case darkGray = "\u{001B}[1;30m"
  case lightBlue = "\u{001B}[1;34m"
  case lightGreen = "\u{001B}[1;32m"
  case lightCyan = "\u{001B}[1;36m"
  case lightRed = "\u{001B}[1;31m"
  case lightPurple = "\u{001B}[1;35m"
  case reset = "\u{001B}[0m"
}

extension String {
  func withANSIColor(color: ANSIColor) -> String {
    return color.rawValue + self + ANSIColor.reset.rawValue
  }
}
