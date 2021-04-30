import crowngui
import os,strformat,xlsx,strutils, tables, math

proc escapeHtml*(val: string; escapeQuotes = false): string =
  ## translates the characters `&`, `<` and `>` to their corresponding
  ## HTML entities. if `escapeQuotes` is `true`, also translates
  ## `"` and `'`.
  for c in val:
    case c:
    of '&': result &= "&amp;"
    of '<': result &= "&lt;"
    of '>': result &= "&gt;"
    of '"':
      if escapeQuotes: result &= "&quot;"
      else: result &= "\""
    of '\'':
      if escapeQuotes: result &= "&#39;"
      else: result &= "'"
    else:
      result &= c

proc onOpenFIle(webview:Webview; filePath:string):bool = 
  jsDebug(fmt"open with file {filePath}")
  let table = parseExcel(filePath)
  var content: string = ""
  for k, v in table.data.pairs:
    let d = $v
    content.add fmt"<h3>{k}</h3>"
    content.add """<table class="SpreadsheetJs">"""
    let rows = v.toSeq(false)
    for row in rows:
      content.add "<tr>"
      for col in row:
        content.add fmt"<td>{escapeHtml(col)}</td>"
      content.add "</tr>"
    content.add "</table>"
  let html = fmt"""<!DOCTYPE html><html><head><meta charset="utf-8"><meta content='width=device-width,initial-scale=1' name=viewport></head><body>{content}</body></html>"""
  let filename = extractFilename filePath
  webview.setTitle(filename.cstring)
  webview.loadHTML(html)
  return true

when isMainModule:
  let app = newApplication("<!DOCTYPE html><html><head><meta content='width=device-width,initial-scale=1' name=viewport></head><body id=body ><div id=ROOT ><div></body></html>")
  const cssSpreadSheet = staticRead(currentSourcePath.parentDir / "assets" / "spreadsheet.css").strip.unindent.cstring
  app.css cssSpreadSheet.cstring
  app.run()
  app.exit()
