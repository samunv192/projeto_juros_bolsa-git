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
4. Relatório de mercado + tutorial em Quarto (HTML e PDF), com resumo executivo de 1 página
5. README e instruções de reprodução

## Estrutura
- rodar_tudo.R: roda 00 a 05 em ordem
- montar_entregaveis.R: monta entregaveis/ com as pastas e .zip dos Entregáveis 1, 2 e 3
  (o 3 roda o 05 de novo, e o README dele puxa os números de H1-H4 das tabelas)
- scripts/parametros.R: período (DATA_INICIO = 2014-12-01), pastas e tabela CESTAS
- scripts/00_setup.R: instala pacotes (tidyverse, tidyquant, rbcb, jsonlite, broom, lmtest, sandwich)
- scripts/01_coleta_bcb.R: Selic meta (SGS 432) e IPCA (SGS 433) via API do BCB direto (httr2)
- scripts/02_coleta_mercado.R: preços diários do Yahoo Finance via tidyquant
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
  erros-padrão Newey-West (lag 3).
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

## Próximos passos
Resultados (Entregável 3): H1 apoiada só em parte (varejo -3,4 p.p. por +1 p.p., p = 0,005, mas sem
MGLU3 o efeito some: -0,2, p = 0,83); H2 apoiada (bancos +0,27, n.s.); H3 apoiada (utilities n.s.);
H4 não apoiada (interação n.s. em todos os setores). Correlação do varejo significativa nas
defasagens de 0 a 2 meses.
1. Montar o relatório/tutorial em Quarto (Entregáveis 4 e 5) e estender montar_entregaveis.R.
