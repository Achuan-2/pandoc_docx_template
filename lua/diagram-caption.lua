-- Typora 将 Mermaid 转为带 mermaid class 的图片，源码注释需从保存的 Markdown 读取。
local function warn(msg)
  io.stderr:write('[typora-docx] ' .. msg .. '\n')
end

function Pandoc(doc)
  local source = pandoc.utils.stringify(doc.meta['typora-source'] or '')
  doc.meta['typora-source'] = nil

  local titles, diagrams = {}, 0
  if source ~= '' then
    local ok, _, content = pcall(pandoc.mediabag.fetch, source)
    if ok then
      local parsed = pandoc.read(content, 'markdown')
      parsed:walk({CodeBlock = function(block)
        if block.classes:includes('mermaid') then
          local title = ''
          for line in (block.text .. '\n'):gmatch('(.-)\r?\n') do
            local value = line:match('^%s*%%%%%s*图题：%s*(.-)%s*$')
            if value then title = value; break end
          end
          titles[#titles + 1] = title
        end
      end})
    else
      warn('无法读取 Markdown 源文件；Mermaid 图题未设置：' .. source)
    end
  end

  doc:walk({Image = function(img)
    if img.classes:includes('mermaid') then diagrams = diagrams + 1 end
  end})
  if diagrams > 0 and #titles ~= diagrams then
    warn('源文件 Mermaid 数量与 Typora 导出的图片数量不一致；为避免图题错配，本次不设置 Mermaid 图题。请保存文件后重试。')
    titles = {}
  end
  local index = 0
  doc = doc:walk({Image = function(img)
    if img.classes:includes('mermaid') then
      index = index + 1
      if titles[index] and titles[index] ~= '' then
        img.caption = {pandoc.Str(titles[index])}
      end
      return img
    end
  end})

  -- Pandoc 自动生成目录时，移除 Typora 从 [toc] 生成的静态目录，避免重复。
  if PANDOC_WRITER_OPTIONS.table_of_contents then
    doc = doc:walk({Div = function(div)
      if div.identifier == 'toc' then return {} end
    end})
  end
  return doc
end
return {{Pandoc = Pandoc}}
