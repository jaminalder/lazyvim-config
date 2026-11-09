-- `|` must be written as `\|` inside markdown table cells; show it plainly in the PDF.
function Code(el)
  el.text = el.text:gsub("\\|", "|")
  return el
end
