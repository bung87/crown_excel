# Package

version       = "0.1.0"
author        = "bung87"
description   = "crowngui based excel viewer"
license       = "LGPL-2.1-or-later"
srcDir        = "src"
installExt    = @["nim","css"]
bin           = @["crown_excel"]


# Dependencies

requires "nim >= 1.4.4"
requires "xlsx"
requires "https://github.com/bung87/crowngui"

task macos,"build macos":
  exec "crowncli build --target macos"