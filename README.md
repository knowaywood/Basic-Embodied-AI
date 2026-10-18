# Basic Embodied AI

以 Typst 编写的具身智能基础笔记。`main.typ` 是唯一需要维护的书稿来源。

在线阅读：[https://knowaywood.github.io/Basic-Embodied-AI/](https://knowaywood.github.io/Basic-Embodied-AI/)

## 本地构建网站

需要 Linux / WSL、Node.js、npm 与 Pandoc。

```bash
npm ci
npm run build
```

上述命令会自动完成：

1. 将 `main.typ` 转换并按一级章节切分为 `src/*.md`；
2. 将 VitePress 站点构建至 `dist/`。

预览构建结果：

```bash
npm run preview
```

开发时使用：

```bash
npm run dev
```

`src/`、`dist/` 与 `node_modules/` 都是生成目录，不提交到仓库。

## GitHub Pages

推送到 `master` 后，GitHub Actions 会执行 `npm run build`，并将 `dist/` 强制发布到 `gh-pages` 分支。

首次部署后，在仓库 **Settings → Pages** 中选择 **Deploy from a branch**，分支选 `gh-pages`，目录选 `/(root)`。
