import crowngui
import os,strformat,xlsx,strutils, tables, math, oids, datauri

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

proc onOpenFile(webview: Webview; filePath: string, filename = ""): bool = 
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
  let filename = if filename.len > 0 :filename else :extractFilename filePath
  webview.setTitle(filename.cstring)
  webview.loadHTML(html)
  return true

type DropData = object
  name: string
  dataurl: string

proc onDrop(webview: Webview; data: DropData) =
  let tmpDir = getTempDir()
  let path = tmpDir / $genOid()
  jsDebug(("onDrop:" & data.name).cstring)
  discard datauri2file(data.dataurl, path)
  discard onOpenFile(webview, path, data.name)

when isMainModule:
  let app = newApplication("<!DOCTYPE html><html><head><meta content='width=device-width,initial-scale=1' name=viewport></head><body id=body ><div id=ROOT ><div></body></html>")
  const cssSpreadSheet = staticRead(currentSourcePath.parentDir / "assets" / "spreadsheet.css").strip.unindent.cstring
  app.css cssSpreadSheet.cstring
  app.bindProcs("api"):
    proc onDrop(data:DropData) =  onDrop(app.webview, data)
  app.js """
    document.body.addEventListener('dragover', (event) => {
    event.stopPropagation();
    event.preventDefault();
      // Style the drag-and-drop as a "copy file" operation.
      event.dataTransfer.dropEffect = 'copy';
    });
    document.body.addEventListener('drop', (event) => {
      event.stopPropagation();
      event.preventDefault();
      const fileList = event.dataTransfer.files;
      console.log(fileList);
      for (let i = 0; i < fileList.length; i++) {
        readExcel(fileList[i]);
      }
      
    });
  function readExcel(file) {
    if (file.type && !file.type.startsWith('application/vnd')) {
      console.log('File is not an Excel.', file.type, file);
      return;
    }

  const reader = new FileReader();
  reader.addEventListener('load', (event) => {
    const data = {name:file.name,dataurl:event.target.result};
    console.log("data",data)
    api.onDrop(data);
  });
  reader.readAsDataURL(file);
}
  """
  app.run()
  app.exit()
