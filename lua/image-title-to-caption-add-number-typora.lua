-- Author: Achuan-2
-- https://github.com/Achuan-2/pandoc_word_template/blob/main/image-title-to-caption-add-number.lua
-- Pandoc Lua过滤器，将图片标题设置为caption，并在只有alt文本时确保无caption，同时为图片添加编号

-- 全局图片计数器
local figure_counter = 0
-- 用于跟踪已处理图片的表
local processed_images = {}

-- 创建caption的函数
function create_caption(text, img_src)
    -- 检查图片是否已经被处理过
    if processed_images[img_src] then
        -- 如果已处理，返回已有的编号
        local existing_number = processed_images[img_src]
        if text and text ~= "" and not text:find("^%s*$") then
            local numbered_text = "图 " .. existing_number .. "：" .. text
            return {pandoc.Str(numbered_text)}
        else
            local numbered_text = "图 " .. existing_number
            return {pandoc.Str(numbered_text)}
        end
    else
        -- 如果未处理，增加计数器并记录
        figure_counter = figure_counter + 1
        processed_images[img_src] = figure_counter
        
        if text and text ~= "" and not text:find("^%s*$") then
            -- 有标题时，在标题前添加编号
            local numbered_text = "图 " .. figure_counter .. "：" .. text
            return {pandoc.Str(numbered_text)}
        else
            -- 无标题时，只显示编号
            local numbered_text = "图 " .. figure_counter
            return {pandoc.Str(numbered_text)}
        end
    end
end

-- 处理Para块
function Para(para)
    -- 检查段落是否只包含一个图片
    if #para.content == 1 and para.content[1].t == "Image" then
        local img = para.content[1]
        -- 所有图片都包装为Figure并添加编号caption
        local content = {pandoc.Plain({img})}
        local caption = create_caption(pandoc.utils.stringify(img.caption), img.src)
        return pandoc.Figure(content, caption)
    end
    -- 如果不是单独的图片，返回未更改的段落
    return para
end

-- 处理Figure块
function Figure(fig)
    -- 查找Figure中的图片
    for i, block in ipairs(fig.content) do
        if block.t == "Plain" then
            for j, inline in ipairs(block.content) do
                if inline.t == "Image" then
                    local img = inline
                    -- 使用图片源作为唯一标识，避免重复计数
                    fig.caption = create_caption(pandoc.utils.stringify(img.caption), img.src)
                end
            end
        end
    end
    return fig
end

-- 返回过滤器
return {{Para = Para}, {Figure = Figure}}