# Basic Embodied AI

原版pdf: [https://github.com/knowaywood/Basic-Embodied-AI/releases/download/v1/Basic-Embodied-AI.pdf](https://github.com/knowaywood/Basic-Embodied-AI/releases/download/v1/Basic-Embodied-AI.pdf)


在线阅读：[https://knowaywood.github.io/Basic-Embodied-AI/](https://knowaywood.github.io/Basic-Embodied-AI/)

## 本地构建网站

需要 Python 3 与 Typst 0.15.1 或更新版本。首次构建时 Typst 会下载 [Manifesto 0.2.0](https://typst.app/universe/package/manifesto/) 模板。

```bash
python3 scripts/build_html.py
```

Typst 直接将 `main_html.typ` 编译为多页面 HTML bundle，输出到 `dist/`。四个章节分别是 `index.html`、`learning.html`、`systems.html` 和 `questions.html`，每页提供章节目录和上一篇、下一篇导航。PDF 仍使用 `main.typ`。

预览构建结果：

```bash
python3 -m http.server 8000 --directory dist
```

打开 `http://localhost:8000/`。修改内容后重新运行构建命令并刷新页面。

## GitHub Pages

推送到 `master` 后，GitHub Actions 安装 Typst、编译 HTML bundle，并将 `dist/` 发布到 `gh-pages` 分支。

首次部署后，在仓库 **Settings → Pages** 中选择 **Deploy from a branch**，分支选 `gh-pages`，目录选 `/(root)`。

## TODO

- [ ] typst引用时需要使用 图...
- [x] 直接使用 Typst 编译出 HTML

Manifesto 模板通过在线 Tailwind 和 Google Fonts 加载样式。Typst 的 HTML bundle 目前仍为实验功能；使用自定义 HTML 页面结构时，脚注在 HTML 中显示为行内括注，PDF 保持正常脚注。
