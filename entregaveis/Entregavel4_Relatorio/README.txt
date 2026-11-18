ENTREGÁVEL 4 — RELATÓRIO DE MERCADO, TUTORIAL E README
Projeto: Juros e bolsa — como setores da B3 reagem à taxa Selic
Disciplina: REC3302 — Introdução ao R Aplicado à Economia e Finanças (FEA-RP/USP)

CONTEÚDO
  - relatorio.pdf / relatorio.html: relatório de mercado. A página 2 é o resumo executivo,
    em 1 página; depois vêm contexto, dados e metodologia, resultados (H1 a H4), robustez,
    implicações para o investidor e limitações.
  - tutorial.pdf / tutorial.html: passo a passo em R, do dado bruto à regressão. O código é
    executado de verdade e confere que reconstrói exatamente a base do projeto.
  - README.md: apresentação do projeto e instruções de reprodução (Entregável 5).
  - codigo_fonte/: arquivos Quarto (.qmd) e de estilo que geram o relatório e o tutorial.

OS ARQUIVOS HTML
  São autocontidos (figuras incluídas): basta abrir no navegador, sem internet.

COMO OS NÚMEROS SÃO GERADOS
  Os números do texto e das tabelas do relatório são lidos de resultados/tabelas/ (gerados por
  scripts/05_analise.R), e os títulos dos gráficos são calculados no próprio 05. Se os dados
  forem atualizados, basta rodar a análise e renderizar de novo; só o período no subtítulo do
  relatório e as frases interpretativas precisam ser relidos.

COMO REGENERAR
  No projeto completo, na pasta do projeto: quarto render
  (ou, no Positron, abrir relatorio/relatorio.qmd e clicar em Render).
