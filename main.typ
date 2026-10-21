#import "@preview/bookly:5.2.0": *
#import "@preview/equate:0.3.3": equate
#import "_symbols.typ": *

#show: bookly.with(
  title: "Basic Embodied AI",
  author: "Gilgamesh",
  theme: modern,
  lang: "zh",
  tufte: false,
  fonts: (
    body: ("Libertinus Serif", "Source Han Serif SC"),
    math: "Libertinus Math",
    size: 10pt,
  ),
  colors: (
    primary: rgb("#2563eb"),
    secondary: rgb("#dbeafe"),
  ),
  title-page: default-title-page,
  config-options: (
    open-right: false,
    alt-margins: false,
  ),
)

#set heading(numbering: "1.1")

#tableofcontents

#theorems-setup[
  #show: equate.with(breakable: true, sub-numbering: true, number-mode: "label")
  #include "src/index.typ"
  #include "src/learning.typ"
  #include "src/systems.typ"
  #include "src/questions.typ"
]
