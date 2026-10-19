#import "@preview/bookly:5.2.0": *
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

#show raw.where(block: false): it => box(
  fill: luma(245),
  inset: (x: 3.5pt, y: 3pt),
  radius: 2pt,
)[#it]
#set heading(numbering: "1.1")

#tableofcontents

#theorems-setup[
  #include "src/index.typ"
  #include "src/learning.typ"
  #include "src/systems.typ"
  #include "src/questions.typ"
]
