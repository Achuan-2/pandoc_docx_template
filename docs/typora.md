# Typora 导出 DOCX

## Typora 导出参数

```text
-f native -s -o ${outputPath} -t docx --toc --toc-depth=3 --metadata toc-title=目录 --metadata "typora-source=${currentPath}" --reference-doc "D:\01-工作\@文档模板\pandoc_word_template\templates\template_标题编号-列表第二行顶格.docx" --lua-filter "D:\01-工作\@文档模板\pandoc_word_template\markdown-to-docx.lua"
```

`--toc` 会在文档开头生成目录，`--toc-depth=3` 显示三级，改为 `2` 显示二级。启用 `--toc` 时，Typora 从 `[toc]` 生成的静态目录会被移除，避免重复。没有 `[toc]` 时也会生成目录。Word 目录域需要在 Word 中更新，以生成目录条目和页码。标题编号沿用模板自动编号，Markdown 标题无需手动编号。

## Mermaid 图题

在 Mermaid 代码块内写注释：

````markdown
```mermaid
%% 图题：业务处理流程
flowchart LR
    A[开始] --> B[结束]
```
````

使用全角冒号，名称不能为空。注释不显示在 Typora 图形中；导出后由现有图片编号规则生成“图 1：业务处理流程”。普通图片仍使用 `![描述](test.png "测试流程图")`。

Typora 在转换为 Pandoc native 时会丢弃 Mermaid 源代码，因此过滤器使用 `${currentPath}` 读取**已保存**的 Markdown。导出前请保存文件；未保存的变更可能导致图题与显示内容不一致。源文件的 Mermaid 数量与 Typora 导出的 Mermaid 图片数量不一致时，过滤器会发出警告并跳过图题设置，避免错配。
