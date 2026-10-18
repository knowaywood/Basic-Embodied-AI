import { defineConfig } from 'vitepress'
import footnote from 'markdown-it-footnote'

function githubPagesBase() {
  const repository = process.env.GITHUB_REPOSITORY?.split('/')[1]
  if (!repository || repository.endsWith('.github.io')) return '/'
  return `/${repository}/`
}

export default defineConfig({
  lang: 'zh-CN',
  title: 'Basic Embodied AI',
  description: '具身智能与机器人学基础笔记',
  base: process.env.GITHUB_ACTIONS ? githubPagesBase() : '/',
  lastUpdated: true,
  srcDir: 'site-src',
  outDir: 'dist',
  markdown: {
    math: true,
    config(md) {
      md.use(footnote)
    }
  },
  ignoreDeadLinks: [/localhost/],
  themeConfig: {
    siteTitle: 'Basic Embodied AI',
    nav: [],
    sidebar: [
      { text: '机器人学基础', link: '/index' },
      { text: '机器人学习', link: '/learning' },
      { text: '系统与部署', link: '/systems' },
      { text: '简单问题', link: '/questions' }
    ],
    sidebarDepth: 2,
    docFooter: { prev: '上一篇', next: '下一篇' },
    outlineTitle: '本页目录',
    lastUpdatedText: '最后更新',
    returnToTopLabel: '回到顶部',
    sidebarMenuLabel: '目录',
    darkModeSwitchLabel: '主题',
    lightModeSwitchTitle: '切换到浅色模式',
    darkModeSwitchTitle: '切换到深色模式'
  }
})
