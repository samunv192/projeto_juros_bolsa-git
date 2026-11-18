# Projeto: Juros e bolsa — como setores da B3 reagem à taxa Selic

Trabalho em grupo (5 integrantes) da disciplina REC3302 — Introdução ao R Aplicado à Economia
e Finanças (FEA-RP/USP). O curso termina no início de dezembro de 2026.
Responda sempre em português.

## Produto
Relatório de mercado + tutorial reproduzível em R/Quarto. Pergunta: mudanças na Selic afetam de
forma diferente o retorno de setores da B3?
- H1: varejo tem relação negativa com a variação da Selic.
- H2: bancos têm relação mais fraca ou até positiva (margem financeira).
- H3: utilities são defensivas (menor sensibilidade).
- H4: a relação muda entre ciclos de alta e de queda.
O professor pediu: boa estrutura, projeto "de mercado", visual bom e comunicação clara.

## Entregáveis (blocos de 2 semanas)
1. Scripts de coleta — CONCLUÍDO
2. Base mensal integrada e validada — CONCLUÍDO (141 meses, jan/2015 a set/2026, 7/7 checagens OK)
3. Análise (descritiva, correlações defasadas, regressões) — CONCLUÍDO (05_analise.R roda sem erros;
   g1..g6 e t1..t6, títulos já enunciam as conclusões)
4. Relatório de mercado + tutorial em Quarto (HTML e PDF), com resumo executivo de 1 página —
   CONCLUÍDO (relatorio/relatorio.qmd e tutorial.qmd; passou por revisão cruzada independente)
5. README e instruções de reprodução — CONCLUÍDO (README.md na raiz; vai no pacote do Entregável 4)

## Estrutura
- rodar_tudo.R: roda 00, 03, 04 e 05 com os dados salvos; 01 e 02 (coleta) só com BAIXAR_DADOS <- TRUE
- montar_entregaveis.R: renderiza o Quarto (acha o quarto.exe do Positron) e monta entregaveis/ com
  pastas e .zip dos Entregáveis 1 a 4 (o 3 roda o 05 de novo; os README.txt puxam números das tabelas)
- _quarto.yml (raiz): renderiza só relatorio/relatorio.qmd e tutorial.qmd; execute-dir = projeto
- relatorio/: relatorio.qmd, tutorial.qmd, _comum.R (lê t1..t6 e formata números; todo número do
  texto vem daqui), _metadata.yml (autores e formatos), estilo.scss (HTML), estilo.typ (PDF)
- PDF via Typst (vem com o Quarto; não há LaTeX instalado). Quarto: Positron\resources\app\quarto\bin
- scripts/parametros.R: período (DATA_INICIO = 2014-12-01), pastas e tabela CESTAS
- scripts/00_setup.R: instala pacotes (tidyverse, tidyquant, rbcb, jsonlite, httr2, zoo, broom, lmtest,
  sandwich); só acessa a internet se algum pacote não carregar
- scripts/01_coleta_bcb.R: Selic meta (SGS 432) e IPCA (SGS 433) via API do BCB direto (httr2)
- scripts/02_coleta_mercado.R: preços diários do Yahoo Finance via tidyquant; grava
  dados/brutos/data_coleta.txt (data da coleta: 2026-10-28)
- scripts/03_base_mensal.R: gera dados/tratados/base_mensal.csv, base_mensal_excel.csv e retornos_ativos_mensal.csv
- scripts/04_validacao.R: checagens da base
- scripts/05_analise.R: gera resultados/figuras/g1..g6.png e resultados/tabelas/t1..t6.csv
  (t6/g6 = efeito da Selic em cada ciclo, β1 e β1+β3 do m2, para H4; t5 inclui cada ação de varejo)
- dados/dicionario_dados.md: descrição de cada variável

## Decisões já tomadas
- Cestas de 3 ações com média simples: bancos (ITUB4, BBDC4, BBAS3), varejo (LREN3, MGLU3, RADL3),
  utilities (EQTL3, CMIG4, SBSP3). Mercado: ^BVSP. Banco do Brasil é BBAS3 (não BBAS4).
- Retornos simples mensais em %, com preço ajustado do último pregão do mês.
- delta_selic = variação da meta no mês, em p.p. Ciclo = direção do último movimento do Copom;
  meses sem mudança herdam o ciclo vigente (68 meses de alta, 73 de queda). Alternativa com estado
  "estável" fica como limitação.
- Juro real ex-post = (1 + Selic) / (1 + IPCA 12m) - 1. IPCA é baixado desde 12 meses antes.
- Regressões: ret_setor ~ delta_selic + ret_ibov (m1) e com interação delta_selic * ciclo_alta (m2),
  erros-padrão Newey-West (lag 3). Pela definição de ciclo, toda alta cai em ciclo de alta e todo
  corte em ciclo de queda: o m2 compara a reação a cortes (β1) com a reação a altas (β1+β3).
- Linguagem: coeficientes não significativos = "sem efeito detectável", nunca "não reage/é imune";
  coeficientes = associação, não causalidade. Correlações defasadas não provam reação atrasada
  (delta_selic tem autocorrelação 0,42-0,59).
- Robustez: varejo com e sem MGLU3 (MGLU3 tem muitos meses com retorno acima de 30%).
- Padrão visual: bancos #1F3864, varejo #E07A2E, utilities #2A9D8F, Ibovespa #8C8C8C; fonte dos dados
  no rodapé; 300 dpi. Depois de ver os resultados, reescrever os títulos dos gráficos para enunciarem
  a conclusão.

## Ambiente e cuidados
- Windows, Positron, R 4.6.1. A pasta do projeto precisa ser o diretório de trabalho.
- Para rodar pelo terminal, use Rscript (provavelmente em C:\Program Files\R\R-4.6.1\bin\Rscript.exe
  se não estiver no PATH), a partir da pasta do projeto: Rscript scripts/05_analise.R
- A API do BCB é instável (já deu XML de erro e status 502). O 01 tenta de novo e, se falhar, usa o
  CSV salvo. Evite rebaixar os dados sem necessidade: a base já está pronta em dados/tratados.
- Os dados do Yahoo são revisados com o tempo (diferenças na 5ª casa decimal); os brutos salvos
  registram a versão usada.

## Resultados
H1 apoiada só em parte (varejo -3,4 p.p. por +1 p.p., p = 0,005, mas sem MGLU3 o efeito some: -0,2,
p = 0,83); H2 apoiada, sem efeito detectável (bancos +0,27, n.s.; beta 1,30); H3 apoiada só quanto
aos juros (utilities +0,84, n.s.; beta 0,99); H4 não apoiada (diferença altas vs. cortes n.s. em
todos os setores, p de 0,40 a 0,87). Diferença de médias do varejo entre ciclos (2,7% vs 0,9% ao mês)
não é significativa (teste t, p = 0,34).

## Próximos passos
1. Preencher os nomes dos 5 integrantes em relatorio/_metadata.yml e no fim do README.md; depois
   rodar montar_entregaveis.R.
2. Os números estáticos do README.md e desta seção valem para a coleta de 28/10/2026; revisar se os
   dados forem atualizados.
