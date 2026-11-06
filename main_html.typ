#import "@preview/manifesto:0.2.0": template
#import "_symbols.typ": *

// HTML 导出不显示公式编号, 因此公式引用不能用编号, 改为指向公式的文本链接.
#show ref: it => {
  if it.element != none and it.element.func() == math.equation {
    link(it.element.location())[（见下式）]
  } else {
    it
  }
}

#show footnote: note => html.elem("span", attrs: (class: "html-footnote"))[（#note.body）]
#let chapters = (
  (path: "index.html", name: [机器人学基础]),
  (path: "learning.html", name: [机器人学习]),
  (path: "systems.html", name: [系统与部署]),
  (path: "questions.html", name: [简单问题]),
)

#let chapter-nav(current) = html.nav(class: "mb-8 flex flex-col gap-2")[
  #strong[章节目录]
  #for chapter in chapters {
    html.div(class: if chapter.path == current { "font-bold" } else { "" }, link(chapter.path, chapter.name))
  }
]

#let book-page(path, body, previous: none, next: none) = document(path, title: [Basic Embodied AI])[
  #show: template.with(
    name: "Basic Embodied AI",
    description: chapter-nav(path),
    repository: "https://github.com/knowaywood/Basic-Embodied-AI",
    font: "serif",
    heading: (numbering: "1.1"),
    class: "[&_main>div:first-child_table]:hidden [&_article_figure]:flex [&_article_figure]:flex-col [&_article_figure]:items-center [&_article_figure]:text-center [&_article_figure_img]:max-w-full",
  )
  #theorems-setup[
    #body
    #html.nav(class: "mt-12 pt-6 border-t flex justify-between gap-4")[
      #if previous != none { link(previous.path)[← #previous.name] }
      #if next != none { link(next.path)[#next.name →] }
    ]
  ]
]

#book-page("index.html", [#include "src/index.typ"], next: chapters.at(1))
#book-page("learning.html", [#include "src/learning.typ"], previous: chapters.at(0), next: chapters.at(2))
#book-page("systems.html", [#include "src/systems.typ"], previous: chapters.at(1), next: chapters.at(3))
#book-page("questions.html", [#include "src/questions.typ"], previous: chapters.at(2))
