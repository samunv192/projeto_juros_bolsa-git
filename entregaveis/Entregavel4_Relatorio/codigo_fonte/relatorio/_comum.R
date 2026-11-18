# relatorio/_comum.R — leitura dos resultados e formatação de números
# Usado pelo relatório e pelo tutorial. Todo número citado no texto sai daqui,
# lido das tabelas de resultados/tabelas/ (geradas por scripts/05_analise.R).
# Assim, se a análise for rodada de novo, o texto acompanha os novos resultados.

suppressPackageStartupMessages(library(tidyverse))

FIG <- "../resultados/figuras"   # caminho das figuras, relativo à pasta relatorio/
TAB <- "resultados/tabelas"      # caminho das tabelas, relativo à pasta do projeto

ler <- function(arquivo) read_csv(file.path(TAB, arquivo), show_col_types = FALSE)

base <- read_csv("dados/tratados/base_mensal.csv", show_col_types = FALSE)
t1 <- ler("t1_estatistica_descritiva.csv")
t2 <- ler("t2_retorno_por_ciclo.csv")
t3 <- ler("t3_correlacoes_defasadas.csv")
t4 <- ler("t4_regressoes.csv")
t5 <- ler("t5_robustez_varejo.csv")
t6 <- ler("t6_efeito_por_ciclo.csv")

# --- Formatação no padrão brasileiro ------------------------------------
num <- function(x, d = 1) formatC(x, format = "f", digits = d, decimal.mark = ",", big.mark = ".")
sinal <- function(x, d = 1) paste0(ifelse(x > 0, "+", ""), num(x, d))   # +0,3 / -3,4
pv <- function(p) ifelse(p < 0.001, "p < 0,001", paste0("p = ", num(p, 3)))
MESES <- c("jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez")
mes_ano <- function(d) paste0(MESES[month(d)], "/", year(d))

NOMES <- c(bancos = "Bancos", varejo = "Varejo", utilities = "Utilities", ibov = "Ibovespa")

# --- Atalhos para os números mais citados --------------------------------
inicio <- min(base$mes)
fim    <- max(base$mes)
n_meses <- nrow(base)
n_mudancas <- sum(base$delta_selic != 0)
# Data da coleta: gravada pelo 02_coleta_mercado.R em dados/brutos/data_coleta.txt
data_coleta <- format(as.Date(readLines("dados/brutos/data_coleta.txt", n = 1)), "%d/%m/%Y")

# A variação da Selic é muito autocorrelacionada (o Copom move os juros em sequência)
autocor_delta <- acf(base$delta_selic, lag.max = 3, plot = FALSE)$acf[2:4]
meses_por_ciclo <- round(mean(table(base$ciclo)))   # ~70 meses em cada ciclo

# Altas e cortes: pela definição, toda alta cai em ciclo de alta e todo corte em ciclo de queda
n_altas  <- sum(base$delta_selic > 0)
n_cortes <- sum(base$delta_selic < 0)
passo_tipico <- median(abs(base$delta_selic[base$delta_selic != 0]))  # passo típico do Copom

# Coeficiente do modelo 1 (sem interação): coef("varejo")$estimate etc.
coef_m1 <- function(setor_, termo = "delta_selic") {
  filter(t4, setor == setor_, modelo == "m1", term == termo)
}
r2_m1 <- function(setor_) coef_m1(setor_)$r2

# Estatística descritiva de uma série (nomes como em t1: "Bancos", "Varejo"...)
desc <- function(serie_, coluna) filter(t1, serie == serie_)[[coluna]]

# Retorno médio por ciclo (t2 usa nomes curtos: "bancos", "ibov"...)
ciclo_medio <- function(serie_, ciclo_) filter(t2, serie == serie_, ciclo == ciclo_)$retorno_medio
meses_ciclo <- function(ciclo_) filter(t2, serie == "ibov", ciclo == ciclo_)$meses

# Robustez (t5) e efeito por ciclo (t6)
rob <- function(esp) filter(t5, especificacao == esp)
efeito_ciclo <- function(setor_, ciclo_) filter(t6, setor == setor_, ciclo == ciclo_)
p_diferenca <- distinct(t6, setor, p_diferenca)

# A diferença de retorno médio do varejo entre ciclos é significativa por si só? (teste t de Welch)
teste_ciclo_varejo <- t.test(ret_varejo ~ ciclo, data = base)

# Correlações defasadas significativas do varejo
defas_varejo_sig <- filter(t3, setor == "varejo", p_valor < 0.05)$defasagem

# Ciclos da Selic: blocos de meses consecutivos com o mesmo ciclo
ciclos <- base |>
  mutate(bloco = cumsum(ciclo != lag(ciclo, default = first(ciclo)))) |>
  group_by(bloco, ciclo) |>
  summarise(inicio = min(mes), fim = max(mes), meses = n(),
            selic_min = min(selic), selic_max = max(selic),
            ultima_alta = suppressWarnings(max(mes[delta_selic > 0])),   # último aumento do ciclo
            .groups = "drop")
ciclos_alta <- filter(ciclos, ciclo == "alta")

# Retorno acumulado do varejo dentro de cada ciclo (para descrever o gráfico de retorno acumulado)
varejo_ciclos <- base |>
  mutate(bloco = cumsum(ciclo != lag(ciclo, default = first(ciclo)))) |>
  group_by(bloco, ciclo) |>
  summarise(inicio = min(mes), fim = max(mes),
            ret = (prod(1 + ret_varejo / 100) - 1) * 100, .groups = "drop")
varejo_melhor_queda <- varejo_ciclos |> filter(ciclo == "queda") |> slice_max(ret, n = 1)
varejo_pior_queda   <- varejo_ciclos |> filter(ciclo == "queda") |> slice_min(ret, n = 1)
periodo <- function(linha) paste0(mes_ano(linha$inicio), " a ", mes_ano(linha$fim))

# Lista em texto: "a, b e c"
juntar <- function(x) {
  if (length(x) <= 1) return(as.character(x))
  paste(paste(head(x, -1), collapse = ", "), "e", tail(x, 1))
}
