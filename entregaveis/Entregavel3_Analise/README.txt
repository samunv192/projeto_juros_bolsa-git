ENTREGÁVEL 3 — ANÁLISE DE DADOS
Projeto: Juros e bolsa — como setores da B3 reagem à taxa Selic
Disciplina: REC3302 — Introdução ao R Aplicado à Economia e Finanças (FEA-RP/USP)

PERGUNTA
  Mudanças na Selic afetam de forma diferente o retorno de setores da B3?
  Amostra: 141 meses (01/2015 a 09/2026), cestas de 3 ações por setor, Ibovespa como mercado.

CONTEÚDO
  - scripts/05_analise.R: código de toda a análise (usa scripts/parametros.R).
  - dados/tratados/: base mensal de entrada (vem do Entregável 2).
  - resultados/figuras/: gráficos em PNG, 300 dpi.
      g1 retorno acumulado | g2 Selic e ciclos | g3 retorno médio por ciclo
      g4 correlações defasadas | g5 sensibilidade à Selic | g6 sensibilidade por ciclo
  - resultados/tabelas/: tabelas em CSV (separador vírgula, decimal ponto).
      t1 estatística descritiva | t2 retorno por ciclo | t3 correlações defasadas
      t4 regressões | t5 robustez do varejo | t6 efeito da Selic em cada ciclo
  - saida_console.txt: tudo o que o script imprime ao rodar.

MÉTODO
  1. Descritiva: média, desvio, retorno acumulado e anualizado, volatilidade anual;
     retorno médio separado por ciclo de alta e de queda da Selic.
  2. Correlações entre o retorno do setor no mês t e a variação da Selic em t, t-1, t-2 e t-3.
  3. Regressões por setor, com erros-padrão Newey-West (lag 3):
       m1: ret_setor = a + b1*delta_selic + b2*ret_ibov + e
       m2: m1 + ciclo_alta + delta_selic*ciclo_alta   (b1 = efeito na queda; b1+b3 = efeito na alta)
     O controle pelo Ibovespa isola a reação própria do setor, além do movimento geral da bolsa.
  4. Robustez: varejo sem MGLU3 e cada ação de varejo sozinha.

RESULTADOS
  H1 (varejo reage negativamente) — APOIADA EM PARTE. +1 p.p. na Selic reduz o retorno mensal
     do varejo em 3,36 p.p. (p = 0,005). A correlação é significativa
     nas defasagens 0, 1, 2 (meses). Porém o efeito vem da MGLU3: sozinha ela dá -9,67 (p = 0,002),
     e a cesta sem ela dá -0,21 (p = 0,825).
  H2 (bancos: relação fraca ou positiva) — APOIADA. Coeficiente 0,27 (p = 0,729), não significativo.
  H3 (utilities defensivas) — APOIADA quanto à Selic: coeficiente 0,84 (p = 0,333).
     Ressalva: o beta de mercado das utilities é 0,99, ou seja, elas acompanham a bolsa quase 1 para 1.
  H4 (a relação muda entre ciclos) — NÃO APOIADA. A diferença entre alta e queda não é
     significativa em nenhum setor (p entre 0,40 e 0,87).
     Na média simples o varejo rende 2,67% ao mês na queda contra 0,93% na alta,
     mas essa diferença some quando se controla pelo Ibovespa.

LIMITAÇÕES
  - Cestas pequenas (3 ações): uma ação volátil, como a MGLU3, domina o resultado do setor.
  - O ciclo herda a direção do último movimento do Copom; não há estado "estável".
  - Usa a variação realizada da Selic, não a surpresa em relação às expectativas do mercado,
    que já pode estar nos preços antes da reunião do Copom.

COMO REPRODUZIR
  Abrir esta pasta no Positron (File > Open Folder) ou no RStudio e rodar scripts/05_analise.R.
  Pacotes: tidyverse, broom, lmtest, sandwich. Figuras e tabelas são recriadas em resultados/.
