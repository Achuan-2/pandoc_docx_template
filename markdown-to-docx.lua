-- Author：Achuan-2
-- 调用：pandoc input.md -o output.docx --lua-filter=markdown-to-docx.lua

-- =================================================================
-- 路径处理：动态获取当前脚本所在目录，确保 require 能找到子模块
-- =================================================================
local script_path = debug.getinfo(1, "S").source:sub(2) -- 获取脚本文件路径
-- 兼容 Windows (\) 和 Unix (/) 路径，获取所在目录
local script_dir = script_path:match("(.*[/\\])") or "./"
-- 将脚本所在目录添加到 Lua 的搜索路径中
-- 这样 require('lua/xxx') 就会相对于本脚本所在位置查找
package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path


-- 通过一个按顺序维护的模块列表来组织需要加载的 Pandoc 过滤器。
-- 在此列表中添加/调整顺序即可，无需再手写多段 require 与循环。
local modules = {
	-- markdown 里的html语法识别：上下标、img标签等
	-- 'lua/markdown-html-recognition',
	-- 为文本添加字体颜色支持
	'lua/preserve_font_color',
	-- 为mermaid图表添加标题支持
	'lua/diagram-caption',
	-- pandoc默认把图片alt作为图片标题，改为title作为图片标题
	-- 'lua/image-title-to-caption',
	-- pandoc默认把图片alt作为图片标题，改为caption作为图片标题，用于typora导出
	'lua/image-title-to-caption-add-number-typora',
	-- 为行内代码添加自定义样式
	'lua/add-inline-code',
	-- 在下方继续追加模块名称，例如：
	-- 'your-extra-filter-module',
}

-- 收集最终要返回给 Pandoc 的过滤器（数组形式）。
local filters = {}

-- 判断一个 table 是否是“数组” (连续的整数索引)。
local function is_array(t)
	if type(t) ~= 'table' then return false end
	local n = #t
	local count = 0
	for k, _ in pairs(t) do
		if type(k) ~= 'number' then return false end
		count = count + 1
	end
	return count == n
end

-- 将一个模块返回的内容追加到 filters：
-- 支持：
-- 1) 单个过滤器 table (如 { Para = function(...) ... end })
-- 2) 过滤器数组 { {Para=...}, {Image=...} }
-- 3) 单个函数（极少见，但也容忍）
local function append_filter(ret, name)
	local kind = type(ret)
	if kind == 'table' then
		if is_array(ret) then
			for i = 1, #ret do
				filters[#filters + 1] = ret[i]
			end
		else
			filters[#filters + 1] = ret
		end
	elseif kind == 'function' then
		filters[#filters + 1] = ret
	elseif ret ~= nil then
		io.stderr:write(string.format('[markdown-to-docx] 警告: 模块 %s 返回不支持的类型: %s\n', name, kind))
	end
end

for _, m in ipairs(modules) do
	local ok, ret = pcall(require, m)
	if ok then
		append_filter(ret, m)
	else
		io.stderr:write(string.format('[markdown-to-docx] 警告: 加载模块 %s 失败: %s\n', m, ret))
	end
end

return filters
