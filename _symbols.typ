#let thm-figure(supplement, body, title: none, numbered: true, emphasized: true) = figure(
  if emphasized { emph(body) } else { body },
  kind: "theorem",
  supplement: supplement,
  numbering: if numbered { "1" } else { none },
  caption: title,
)

#let thm(body, title: none) = thm-figure("Theorem", body, title: title)
#let lemma(body, title: none) = thm-figure("Lemma", body, title: title)
#let proposition(body, title: none) = thm-figure("Proposition", body, title: title)
#let corollary(body, title: none) = thm-figure("Corollary", body, title: title)
#let problem(body, title: none) = thm-figure("Problem", body, title: title)
#let remark(body, title: none) = thm-figure("Remark", body, title: title, emphasized: false)
#let def(body, title: none) = thm-figure("Definition", body, title: title)
#let example(body, title: none) = thm-figure("Example", body, title: title)
#let property(body, title: none) = thm-figure("Property", body, title: title)
#let hypothesis(body, title: none) = thm-figure("Hypothesis", body, title: title)
#let exercise(body, title: none) = thm-figure("Exercise")[#body]

#let pf(body) = block(width: 100%, breakable: true)[
  _Proof._ #body #v(0em) #h(1fr) $square$
]

#let algo-figure(body, title: none) = {
  figure(
    block(
      fill: luma(240),
      width: 100%,
      stroke: 0.5pt + blue,
      inset: 12pt,
      radius: 2pt,
      breakable: true,
      body,
    ),
    kind: "theorem",
    numbering: "1",
    supplement: "Algorithm",
    caption: title,
  )
}

#let algo(body, title: none) = algo-figure(body, title: title)

#let theorems-setup(body) = {
  show raw.where(block: false): it => box(
    fill: luma(245),
    inset: (x: 3.5pt, y: 3pt),
    radius: 2pt,
  )[ #it ]

  show heading.where(level: 1): it => {
    counter(figure.where(kind: "theorem")).update(0)
    it
  }
  show heading.where(level: 2): it => {
    counter(figure.where(kind: "theorem")).update(0)
    it
  }

  show figure.where(kind: "theorem"): it => block(width: 100%, breakable: true)[
    #set text(font: "FandolKai")
    #show strong: set text(stroke: 0.15pt)
    #set align(left)
    #v(0.5em)
    #context {
      let loc = it.location()
      let hcon = counter(heading).at(loc)
      let section = if hcon.len() > 1 { str(hcon.at(0)) + "." + str(hcon.at(1)) } else if hcon.len() > 0 {
        str(hcon.at(0))
      } else {
        "0"
      }
      let def-num = it.counter.at(loc).at(0)
      let prefix = [*#it.supplement #section.#def-num*]

      if it.caption != none {
        prefix
        [ (#it.caption.body).]
        v(0.2em)
        it.body
      } else {
        prefix
        [.]
        h(0.2em)
        it.body
      }
    }
    #v(0.5em)
  ]

  show ref: it => {
    let el = it.element
    if el != none and el.func() == figure and el.kind == "theorem" {
      context {
        let loc = el.location()
        let hcon = counter(heading).at(loc)
        let section = if hcon.len() > 1 { str(hcon.at(0)) + "." + str(hcon.at(1)) } else if hcon.len() > 0 { str(hcon.at(0)) } else {
          "0"
        }
        let def-num = el.counter.at(loc).at(0)
        link(loc)[#el.supplement #section.#def-num]
      }
    } else {
      it
    }
  }

  body
}
