// Estilo do PDF (Typst): mesma paleta dos gráficos do projeto
#let azul = rgb("#1F3864")

#show heading: set text(fill: azul)
#show heading.where(level: 1): it => {
  v(0.6em)
  it
  v(-0.5em)
  line(length: 100%, stroke: 0.8pt + azul)
  v(0.2em)
}

#show link: set text(fill: azul)

// Tabelas: cabeçalho em azul com texto branco e linhas finas
#set table(
  stroke: (x, y) => if y == 0 { none } else { (bottom: 0.4pt + luma(200)) },
  fill: (x, y) => if y == 0 { azul } else { none },
)
#show table.cell.where(y: 0): set text(fill: white, weight: "bold")
#show table.cell: set par(justify: false)   // sem espaços largos dentro das células
#show table: set text(size: 9pt)

// Código do tutorial em fonte menor, para as linhas caberem na página
#show raw.where(block: true): set text(size: 8pt)
