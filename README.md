# Juros e bolsa: como os setores da B3 reagem à Selic

Relatório de mercado e tutorial reproduzível em R/Quarto sobre a sensibilidade de bancos, varejo e
utilities às mudanças da taxa Selic, de jan/2015 a set/2026.

Trabalho em grupo da disciplina **REC3302 — Introdução ao R Aplicado à Economia e Finanças**
(FEA-RP/USP).

## Pergunta e hipóteses

Mudanças na Selic afetam de forma diferente o retorno de setores da B3?

| | Hipótese | Resultado |
|---|---|---|
| H1 | O varejo tem relação negativa com a variação da Selic | **Apoiada em parte** |
| H2 | Bancos têm relação mais fraca ou até positiva (margem financeira) | **Apoiada** (sem efeito detectável) |
| H3 | Utilities são defensivas (menor sensibilidade) | **Apoiada** (só quanto aos juros) |
| H4 | A relação muda entre ciclos de alta e de queda | **Não apoiada** |

## Principais resultados

Regressão do retorno mensal de cada setor sobre a variação da Selic, controlando pelo Ibovespa,
com erros-padrão de Newey-West (141 meses). Os coeficientes medem associação, não efeito causal.

- **Varejo:** +1 p.p. na Selic vem acompanhado de retorno 3,4 p.p. menor no mês (p = 0,005). O
  efeito, porém, vem da **MGLU3**: sem ela, a cesta tem coeficiente de −0,2 (p = 0,83), e
  LREN3 e RADL3 sozinhas também não mostram reação detectável.
- **Bancos:** efeito de +0,3 p.p., não significativo (p = 0,73): não há evidência de que ganhem
  com a alta de juros. Beta de mercado de 1,30: os bancos amplificam a bolsa.
- **Utilities:** efeito de +0,8 p.p., não significativo (p = 0,33), mas beta de 0,99: sem
  sensibilidade detectável à Selic, mas com risco de bolsa. Foi o setor de maior retorno acumulado
  (863%).
- **Altas vs. cortes:** não encontramos diferença entre a reação a altas e a cortes da Selic em
  nenhum setor (p de 0,40 a 0,87), embora o teste tenha pouco poder. Pela definição de ciclo usada,
  testar a diferença entre ciclos equivale a comparar altas com cortes.

**Conclusão:** nesta amostra, a sensibilidade a juros apareceu em uma empresa (MGLU3), e não em um
setor inteiro.

> Os números acima refletem os dados coletados em 28/10/2026. No relatório, os números do texto
> e das tabelas são lidos diretamente dos resultados da análise.

## Entregáveis

| # | Entregável | Onde está |
|---|---|---|
| 1 | Scripts de coleta (BCB e Yahoo Finance) | `scripts/00` a `02`, `dados/brutos/` |
| 2 | Base mensal integrada e validada | `scripts/03` e `04`, `dados/tratados/`, `dados/dicionario_dados.md` |
| 3 | Análise: descritiva, correlações defasadas e regressões | `scripts/05_analise.R`, `resultados/` |
| 4 | Relatório de mercado (com resumo executivo) e tutorial | `relatorio/` (HTML e PDF) |
| 5 | README e instruções de reprodução | este arquivo |

O script `montar_entregaveis.R` empacota cada entregável em uma pasta e um `.zip` dentro de
`entregaveis/`.

## Estrutura do projeto

```
projeto_juros_bolsa/
├── rodar_tudo.R              # roda os scripts em ordem (coleta só se BAIXAR_DADOS = TRUE)
├── montar_entregaveis.R      # renderiza o relatório e gera entregaveis/ com pastas e .zip
├── _quarto.yml               # configuração do Quarto (relatório e tutorial)
├── scripts/
│   ├── parametros.R          # período, pastas e composição das cestas
│   ├── 00_setup.R            # instala os pacotes
│   ├── 01_coleta_bcb.R       # meta Selic (SGS 432) e IPCA (SGS 433)
│   ├── 02_coleta_mercado.R   # preços diários (Yahoo Finance)
│   ├── 03_base_mensal.R      # base mensal: retornos, Selic, ciclo, juro real
│   ├── 04_validacao.R        # 7 checagens automáticas da base
│   └── 05_analise.R          # figuras g1 a g6 e tabelas t1 a t6
├── dados/
│   ├── brutos/               # dados como vieram das fontes (+ data_coleta.txt)
│   ├── tratados/             # base_mensal.csv e retornos por ação
│   └── dicionario_dados.md   # descrição de cada variável
├── resultados/
│   ├── figuras/              # PNG, 300 dpi
│   └── tabelas/              # CSV
├── relatorio/
│   ├── relatorio.qmd         # relatório de mercado -> .html e .pdf
│   ├── tutorial.qmd          # tutorial passo a passo -> .html e .pdf
│   ├── _comum.R              # leitura das tabelas e formatação dos números
│   ├── _metadata.yml         # autores e opções comuns de formato
│   └── estilo.scss, estilo.typ  # visual do HTML e do PDF
└── entregaveis/              # pacotes gerados por montar_entregaveis.R
```

## Como reproduzir

**Requisitos:** R 4.6 ou mais recente, Positron ou RStudio e Quarto 1.4 ou mais recente (já vem
com o Positron e o RStudio). Para o PDF, o Quarto usa o Typst, que já vem incluído; não é preciso
instalar LaTeX.

1. Abra a **pasta do projeto** no Positron (*File > Open Folder*) ou no RStudio. Ela precisa ser o
   diretório de trabalho.
2. Instale os pacotes uma vez:
   ```r
   source("scripts/00_setup.R")
   ```
3. Reproduza a base, a validação e a análise a partir dos dados salvos em `dados/brutos/`:
   ```r
   source("rodar_tudo.R")
   ```
4. Gere o relatório e o tutorial (HTML e PDF) e empacote os entregáveis:
   ```r
   source("montar_entregaveis.R")
   ```
   O script encontra sozinho o Quarto que vem com o Positron ou o RStudio. Para gerar só o
   relatório, use o botão *Render* do Positron ou, se o Quarto estiver no PATH, `quarto render`
   no terminal.

**Atualizar os dados.** Para baixar dados novos do Banco Central e do Yahoo Finance, mude
`BAIXAR_DADOS <- TRUE` no início do `rodar_tudo.R` (é preciso internet). Isso **substitui** os
arquivos de `dados/brutos/` e pode mudar todos os números, inclusive o período, quando um novo mês
de IPCA já tiver sido divulgado. Os números do relatório se atualizam sozinhos, mas as frases
interpretativas e os números estáticos deste README precisam ser revistos. O Yahoo também revisa os
preços ajustados com o tempo (diferenças na 5ª casa decimal).

## Dados e metodologia

- **Fontes:** Banco Central do Brasil (SGS, séries 432 e 433) e Yahoo Finance.
- **Cestas** (média simples de 3 ações): bancos (ITUB4, BBDC4, BBAS3), varejo (LREN3, MGLU3,
  RADL3) e utilities (EQTL3, CMIG4, SBSP3). Mercado: Ibovespa.
- **Retornos:** simples e mensais, com o preço ajustado do último pregão do mês.
- **Selic:** meta vigente no fim do mês; `delta_selic` é a variação no mês, em p.p.
- **Ciclo:** direção do último movimento do Copom; meses sem mudança herdam o ciclo vigente
  (68 meses de alta e 73 de queda). Assim, toda alta cai em ciclo de alta e todo corte em ciclo
  de queda.
- **Modelos:** `ret_setor ~ delta_selic + ret_ibov` e, para H4, com a interação
  `delta_selic * ciclo_alta`; erros-padrão de Newey-West com 3 defasagens.
- **Robustez:** varejo sem a MGLU3 e cada ação de varejo sozinha.

As limitações (cestas pequenas, viés de sobrevivência, uso da variação realizada em vez da surpresa
do Copom, entre outras) estão discutidas no relatório.

## Autores

<!-- PREENCHER com os nomes dos integrantes (também em relatorio/_metadata.yml) -->
Samuel Neachic Vasques, João Pedro Diniz Menegucci, Hugo Mendes Luchetti, Alisson pedro Viana Rocha,Edson Saturnino Franquilei

*Projeto acadêmico; não constitui recomendação de investimento.*
