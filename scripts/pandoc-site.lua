-- Keep figures as Markdown blocks so VitePress can render math in captions.
local references = {}
local chapter = 0
local figure_number = 0

function Para(paragraph)
  local blocks = pandoc.List()
  local pending = pandoc.List()
  local found_display_math = false

  local function flush()
    while #pending > 0 and (pending[#pending].t == "Space" or pending[#pending].t == "SoftBreak") do
      pending:remove(#pending)
    end
    if #pending > 0 then
      blocks:insert(pandoc.Para(pending))
      pending = pandoc.List()
    end
  end

  for _, inline in ipairs(paragraph.content) do
    if inline.t == "Math" and inline.mathtype == "DisplayMath" then
      found_display_math = true
      flush()
      blocks:insert(pandoc.Para({ inline }))
    else
      pending:insert(inline)
    end
  end
  if not found_display_math then
    return paragraph
  end
  flush()
  return blocks
end

function Div(div)
  return div.content
end

function Image(image)
  if image.src:sub(1, 8) == "/images/" then
    image.src = "./images/" .. image.src:sub(9):gsub(" ", "%%20")
  end
  return image
end

function Header(header)
  if header.level == 1 then
    chapter = chapter + 1
    figure_number = 0
  end
  if header.identifier ~= "" then
    references[header.identifier] = pandoc.utils.stringify(header.content)
    return {
      pandoc.RawBlock("html", '<a id="' .. header.identifier .. '"></a>'),
      header,
    }
  end
  return header
end

function Figure(figure)
  local blocks = pandoc.List()
  figure_number = figure_number + 1
  local label = "图 " .. chapter .. "." .. figure_number
  if figure.identifier ~= "" then
    references[figure.identifier] = label
    blocks:insert(pandoc.RawBlock("html", '<a id="' .. figure.identifier .. '"></a>'))
  end
  blocks:extend(figure.content)
  if #figure.caption.long > 0 then
    local first = figure.caption.long[1]
    if first.t == "Para" or first.t == "Plain" then
      first.content:insert(1, pandoc.Space())
      first.content:insert(1, pandoc.Str(label .. ":"))
    end
    blocks:extend(figure.caption.long)
  end
  return blocks
end

function Pandoc(document)
  return document:walk({
    Link = function(link)
      for _, class in ipairs(link.classes) do
        if class == "ref" then
          local target = link.target:match("^#(.+)$")
          if target and references[target] then
            link.content = { pandoc.Str(references[target]) }
          end
          break
        end
      end
      return link
    end,
  })
end
