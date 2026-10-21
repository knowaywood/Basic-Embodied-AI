// Content-only counterparts to the custom helpers in ../_symbols.typ.
// Pandoc needs these names to parse the document; layout and numbering remain
// the responsibility of the Typst source, while Markdown keeps each body.
#let thm-figure(supplement, body, title: none, numbered: true, emphasized: true) = block(breakable: true)[
  #if emphasized { strong(supplement) } else { supplement }
  #if title != none { [ (#title).] } else { [.] }
  #body
]

#let thm(body, title: none) = thm-figure("Theorem", body, title: title)
#let lemma(body, title: none) = thm-figure("Lemma", body, title: title)
#let proposition(body, title: none) = thm-figure("Proposition", body, title: title)
#let corollary(body, title: none) = thm-figure("Corollary", body, title: title)
#let problem(body, title: none) = thm-figure("Problem", body, title: title)
#let remark(body, title: none) = thm-figure("Remark", body, title: title)
#let def(body, title: none) = thm-figure("Definition", body, title: title)
#let example(body, title: none) = thm-figure("Example", body, title: title)
#let property(body, title: none) = thm-figure("Property", body, title: title)
#let hypothesis(body, title: none) = thm-figure("Hypothesis", body, title: title)
#let exercise(body, title: none) = thm-figure("Exercise", body, title: title)

#let pf(body) = block(breakable: true)[*Proof.* #body]
#let algo-figure(body, title: none) = block(breakable: true)[
  *Algorithm*#if title != none { [ (#title).] } else { [.] }
  #body
]
#let algo(body, title: none) = algo-figure(body, title: title)
#let theorems-setup(body) = body
