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
     Pela definição de ciclo, toda alta da Selic cai em ciclo de alta e todo corte em ciclo de
     queda: na prática, o m2 compara a reação a cortes (b1) com a reação a altas (b1+b3).
     O controle pelo Ibovespa isola a reação própria do setor, além do movimento geral da bolsa.
  4. Robustez: varejo sem MGLU3 e cada ação de varejo sozinha.

RESULTADOS (associações; não medem efeito causal)
  H1 (varejo reage negativamente) — APOIADA EM PARTE. +1 p.p. na Selic vem acompanhado de
     retorno mensal 3,36 p.p. menor no varejo (p = 0,005). Porém o efeito vem da MGLU3:
     sozinha ela dá -9,67 (p = 0,002), e a cesta sem ela dá -0,21 (p = 0,825).
     A correlação também é significativa nas defasagens 0, 1, 2, mas a própria variação da Selic
     é autocorrelacionada (o Copom move os juros em sequência), então isso não prova reação atrasada.
  H2 (bancos: relação fraca ou positiva) — APOIADA (sem efeito detectável). Coeficiente 0,27 (p = 0,729).
     Ressalva: a comparação com o varejo depende da MGLU3; sem ela, o varejo também não reage.
  H3 (utilities defensivas) — APOIADA SÓ QUANTO AOS JUROS: coeficiente 0,84 (p = 0,333), sem efeito detectável.
     Mas o beta de mercado das utilities é 0,99: elas acompanham a bolsa quase 1 para 1.
  H4 (a relação muda entre ciclos) — NÃO APOIADA. A diferença entre a reação a altas e a cortes
     não é significativa em nenhum setor (p entre 0,40 e 0,87); o teste tem pouco poder.
     Na média simples o varejo rende 2,67% ao mês na queda contra 0,93% na alta,
     mas essa diferença não é estatisticamente significativa (teste t, p = 0,337): o varejo oscila demais
     para que médias de cerca de 70 meses separem os ciclos.

LIMITAÇÕES
  - Cestas pequenas (3 ações): uma ação volátil, como a MGLU3, domina o resultado do setor.
  - O ciclo herda a direção do último movimento do Copom; não há estado "estável". Por isso
    os ciclos de alta incluem os meses de manutenção no topo, até o primeiro corte.
  - Usa a variação realizada da Selic, não a surpresa em relação às expectativas do mercado,
    que já pode estar nos preços antes da reunião do Copom.

COMO REPRODUZIR
  Abrir esta pasta no Positron (File > Open Folder) ou no RStudio e rodar scripts/05_analise.R.
  Pacotes: tidyverse, broom, lmtest, sandwich. Figuras e tabelas são recriadas em resultados/.
