#let def(body, title: none) = figure(
  emph(body),
  kind: "theorem",
  supplement: "Definition",
  numbering: "1",
  caption: title,
)

#let theorems-setup(body) = {
  show heading.where(level: 1): it => {
    counter(figure.where(kind: "theorem")).update(0)
    it
  }
  show heading.where(level: 2): it => {
    counter(figure.where(kind: "theorem")).update(0)
    it
  }

  show figure.where(kind: "theorem"): it => block(width: 100%, breakable: true)[
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
