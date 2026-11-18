# 05_analise.R — Entregável 3: análise descritiva, correlações defasadas e regressões
# Entrada: dados/tratados/base_mensal.csv e retornos_ativos_mensal.csv
# Saídas:  resultados/figuras/*.png  e  resultados/tabelas/*.csv

source("scripts/parametros.R")
library(broom)
library(lmtest)
library(sandwich)

PASTA_FIG <- "resultados/figuras"
PASTA_TAB <- "resultados/tabelas"
dir.create(PASTA_FIG, recursive = TRUE, showWarnings = FALSE)
dir.create(PASTA_TAB, recursive = TRUE, showWarnings = FALSE)

base   <- read_csv(file.path(PASTA_TRATADOS, "base_mensal.csv"),            show_col_types = FALSE)
ativos <- read_csv(file.path(PASTA_TRATADOS, "retornos_ativos_mensal.csv"), show_col_types = FALSE)

# =========================================================================
# 0. Padrão visual do projeto (mesma paleta e estilo em todos os gráficos)
# =========================================================================
SETORES <- c("bancos", "varejo", "utilities")
NOMES   <- c(bancos = "Bancos", varejo = "Varejo", utilities = "Utilities", ibov = "Ibovespa")
CORES   <- c(bancos = "#1F3864", varejo = "#E07A2E", utilities = "#2A9D8F", ibov = "#8C8C8C")
FONTE   <- "Fonte: BCB/SGS e Yahoo Finance. Elaboração própria."

tema_projeto <- function() {
  theme_minimal(base_size = 11) +
    theme(plot.title          = element_text(face = "bold", size = 13),
          plot.title.position = "plot",
          plot.subtitle       = element_text(color = "grey35"),
          plot.caption        = element_text(color = "grey45", hjust = 0),
          plot.caption.position = "plot",
          legend.position     = "top",
          legend.title        = element_blank(),
          panel.grid.minor    = element_blank())
}

salvar <- function(grafico, arquivo, largura = 8, altura = 4.5) {
  ggsave(file.path(PASTA_FIG, arquivo), grafico,
         width = largura, height = altura, dpi = 300, bg = "white")
  if (interactive()) print(grafico)  # mostra no painel de gráficos; pelo Rscript só salva
}

# Retornos em formato longo: uma linha por mês e série
ret_long <- base |>
  select(mes, starts_with("ret_")) |>
  pivot_longer(-mes, names_to = "serie", names_prefix = "ret_", values_to = "ret")

# Períodos de ciclo de alta, para sombrear nos gráficos
regimes_alta <- base |>
  mutate(bloco = cumsum(ciclo != dplyr::lag(ciclo, default = ciclo[1]))) |>
  group_by(bloco, ciclo) |>
  summarise(inicio = min(mes), fim = max(mes) %m+% months(1), .groups = "drop") |>
  filter(ciclo == "alta")

# ymin = -Inf não funciona em escala log (vira NaN e o sombreado some);
# por isso o gráfico em log passa limites finitos (logo abaixo e acima da série)
sombra_alta <- function(ymin = -Inf, ymax = Inf) {
  # limites dentro do aes() para passarem pela escala do eixo y (inclusive a log)
  geom_rect(data = mutate(regimes_alta, y0 = ymin, y1 = ymax), inherit.aes = FALSE,
            aes(xmin = inicio, xmax = fim, ymin = y0, ymax = y1),
            fill = "grey88")
}

# =========================================================================
# 1. Estatística descritiva
# =========================================================================
anos <- nrow(base) / 12

descritiva <- ret_long |>
  group_by(serie) |>
  summarise(media_mensal        = mean(ret),
            desvio_mensal       = sd(ret),
            minimo              = min(ret),
            maximo              = max(ret),
            retorno_acumulado   = (prod(1 + ret / 100) - 1) * 100,
            retorno_anual_medio = (prod(1 + ret / 100)^(1 / anos) - 1) * 100,
            volatilidade_anual  = sd(ret) * sqrt(12),
            .groups = "drop") |>
  # 4 casas: o relatório arredonda de novo ao exibir, e arredondar duas vezes pode errar
  # (21,2536 viraria 21,25 e depois 21,2 em vez de 21,3)
  mutate(serie = unname(NOMES[serie]),
         across(where(is.numeric), \(x) round(x, 4)))

por_ciclo <- ret_long |>
  left_join(select(base, mes, ciclo), by = "mes") |>
  group_by(serie, ciclo) |>
  summarise(retorno_medio = mean(ret), meses = n(), .groups = "drop")

# A diferença de retorno médio do varejo entre ciclos é significativa? (teste t de Welch)
p_ciclo_varejo <- t.test(ret_varejo ~ ciclo, data = base)$p.value

write_csv(descritiva, file.path(PASTA_TAB, "t1_estatistica_descritiva.csv"))
write_csv(mutate(por_ciclo, retorno_medio = round(retorno_medio, 2)),
          file.path(PASTA_TAB, "t2_retorno_por_ciclo.csv"))

# =========================================================================
# 2. Gráficos descritivos
# =========================================================================
acumulado <- ret_long |>
  group_by(serie) |>
  arrange(mes, .by_group = TRUE) |>
  mutate(indice = 100 * cumprod(1 + ret / 100)) |>
  ungroup()

g1 <- ggplot(acumulado, aes(mes, indice, color = serie)) +
  sombra_alta(ymin = min(acumulado$indice) * 0.9, ymax = max(acumulado$indice) * 1.1) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = CORES, labels = NOMES) +
  scale_y_log10() +
  labs(title    = "Utilities lideram no acumulado; varejo sobe e cai muito, nem sempre no ritmo da Selic",
       subtitle = paste0("Retorno acumulado, índice base 100 = dez/2014, escala logarítmica. ",
                         "Áreas cinza: ciclos de alta da Selic.\n",
                         "Todos os setores superam o Ibovespa no período."),
       x = NULL, y = "Índice", caption = FONTE) +
  tema_projeto()
salvar(g1, "g1_retorno_acumulado.png")

# Picos de cada ciclo de alta, para o título (calculados, não digitados)
virgula <- function(x, d = 2) formatC(x, format = "f", digits = d, decimal.mark = ",")
picos <- base |>
  mutate(bloco = cumsum(ciclo != dplyr::lag(ciclo, default = ciclo[1]))) |>
  filter(ciclo == "alta") |>
  group_by(bloco) |>
  summarise(pico = max(selic))

g2 <- ggplot(base, aes(mes, selic)) +
  sombra_alta() +
  geom_step(color = CORES[["bancos"]], linewidth = 0.9) +
  labs(title    = paste0(nrow(picos), " ciclos de alta levaram a Selic a ", virgula(min(picos$pico)),
                         "%-", virgula(max(picos$pico)), "% a.a.; entre eles, mínima de ",
                         virgula(min(base$selic), 0), "%"),
       subtitle = paste0("Meta Selic, % ao ano, no fim de cada mês. Áreas cinza: ciclos de alta\n",
                         "(incluem a manutenção no topo até o primeiro corte)."),
       x = NULL, y = "% a.a.", caption = FONTE) +
  tema_projeto()
salvar(g2, "g2_selic.png")

g3 <- por_ciclo |>
  mutate(serie = factor(NOMES[serie], levels = NOMES),
         ciclo = factor(ciclo, levels = c("alta", "queda"),
                        labels = c("Ciclo de alta", "Ciclo de queda"))) |>
  ggplot(aes(serie, retorno_medio, fill = ciclo)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  geom_hline(yintercept = 0, color = "grey40") +
  geom_text(aes(label = virgula(retorno_medio, 1),
                vjust = ifelse(retorno_medio >= 0, -0.4, 1.3)),
            position = position_dodge(width = 0.75), size = 3.3) +
  scale_fill_manual(values = c("Ciclo de alta" = "#1F3864", "Ciclo de queda" = "#9DB4D6")) +
  scale_y_continuous(labels = \(x) virgula(x, 0)) +
  labs(title    = "Varejo rende mais em ciclos de queda, mas a diferença não é significativa",
       subtitle = paste0("Retorno médio mensal (%) nos meses de cada ciclo. Teste t para o varejo: p = ",
                         virgula(p_ciclo_varejo), ".\nCom a volatilidade do setor, médias de cerca de ",
                         round(mean(table(base$ciclo))), " meses ainda têm muita incerteza."),
       x = NULL, y = "% ao mês", caption = FONTE) +
  tema_projeto()
salvar(g3, "g3_retorno_por_ciclo.png")

# =========================================================================
# 3. Correlações defasadas: retorno do setor no mês t vs. ΔSelic em t - k
# =========================================================================
cor_defasadas <- expand_grid(setor = SETORES, defasagem = 0:3) |>
  mutate(teste = map2(setor, defasagem, \(s, k) {
           cor.test(base[[paste0("ret_", s)]], dplyr::lag(base$delta_selic, k))
         }),
         correlacao = map_dbl(teste, \(t) unname(t$estimate)),
         p_valor    = map_dbl(teste, \(t) t$p.value)) |>
  select(-teste)

write_csv(mutate(cor_defasadas, across(c(correlacao, p_valor), \(x) round(x, 3))),
          file.path(PASTA_TAB, "t3_correlacoes_defasadas.csv"))

limite <- max(abs(cor_defasadas$correlacao))
g4 <- cor_defasadas |>
  mutate(setor  = factor(NOMES[setor], levels = rev(NOMES[SETORES])),
         rotulo = paste0(virgula(correlacao), ifelse(p_valor < 0.05, "*", ""))) |>
  ggplot(aes(factor(defasagem), setor, fill = correlacao)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = rotulo), size = 4) +
  scale_fill_gradient2(low = "#C0392B", mid = "white", high = "#1F3864",
                       midpoint = 0, limits = c(-limite, limite), labels = \(x) virgula(x, 1)) +
  labs(title    = "Só o varejo tem correlação (negativa) com a variação da Selic",
       subtitle = paste0("Correlação entre o retorno do setor no mês t e a variação da Selic em t - k. ",
                         "* = significativa a 5%.\nO Copom move os juros em sequência; por isso, ",
                         "as defasagens não indicam,\nsozinhas, uma reação atrasada."),
       x = "Defasagem da variação da Selic (meses)", y = NULL, caption = FONTE) +
  tema_projeto() +
  theme(legend.position = "right", panel.grid = element_blank())
salvar(g4, "g4_correlacoes_defasadas.png", largura = 7, altura = 3.5)

# =========================================================================
# 4. Regressões com controle de mercado e erros-padrão robustos
#    Modelo 1: ret_setor = a + b1*ΔSelic + b2*ret_ibov + e
#    Modelo 2: inclui interação de ΔSelic com o ciclo de alta (H4)
# =========================================================================
estimar <- function(dados, formula_txt) {
  m <- lm(as.formula(formula_txt), data = dados)
  # Newey-West: corrige erros-padrão para heterocedasticidade e autocorrelação
  ct <- coeftest(m, vcov. = NeweyWest(m, lag = 3, prewhite = FALSE))
  t_crit <- qt(0.975, df = m$df.residual)
  tidy(ct) |>
    mutate(conf.low  = estimate - t_crit * std.error,   # intervalo de confiança de 95%
           conf.high = estimate + t_crit * std.error,
           r2 = summary(m)$r.squared, n = nobs(m))
}

formulas <- c(
  m1 = "ret_{s} ~ delta_selic + ret_ibov",
  m2 = "ret_{s} ~ delta_selic * ciclo_alta + ret_ibov"
)

regressoes <- expand_grid(setor = SETORES, modelo = names(formulas)) |>
  mutate(res = map2(setor, modelo, \(s, m) estimar(base, str_glue(formulas[[m]], s = s)))) |>
  unnest(res)

write_csv(mutate(regressoes, across(where(is.numeric), \(x) round(x, 4))),
          file.path(PASTA_TAB, "t4_regressoes.csv"))

beta_selic <- regressoes |> filter(modelo == "m1", term == "delta_selic")

g5 <- beta_selic |>
  mutate(setor = factor(NOMES[setor], levels = rev(NOMES[SETORES]))) |>
  ggplot(aes(estimate, setor, color = setor)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high), linewidth = 0.9, size = 0.6) +
  scale_color_manual(values = setNames(CORES[SETORES], NOMES[SETORES]), guide = "none") +
  labs(title    = paste0("Só o varejo reage à Selic (",
                         virgula(filter(beta_selic, setor == "varejo")$estimate, 1),
                         " p.p. por +1 p.p.), efeito puxado pela MGLU3"),
       subtitle = paste0("Efeito de +1 p.p. na Selic sobre o retorno mensal (p.p.), controlando pelo Ibovespa.\n",
                         "Barras: intervalo de confiança de 95% (erros-padrão Newey-West)."),
       x = "Coeficiente da variação da Selic (β1)", y = NULL, caption = FONTE) +
  tema_projeto()
salvar(g5, "g5_sensibilidade_selic.png", largura = 8, altura = 3.8)

# -------------------------------------------------------------------------
# H4: efeito da Selic em cada ciclo, a partir do modelo 2
#   ciclo de queda: β1           (delta_selic)
#   ciclo de alta:  β1 + β3      (delta_selic + delta_selic:ciclo_alta)
# Atenção: pela definição de ciclo, toda alta da Selic cai em ciclo de alta e todo corte em ciclo
# de queda. Na prática, β1 mede a reação a CORTES e β1 + β3 a reação a ALTAS.
#   Var(β1 + β3) = Var(β1) + Var(β3) + 2 Cov(β1, β3), com a matriz Newey-West
# -------------------------------------------------------------------------
efeito_por_ciclo <- function(s) {
  m <- lm(as.formula(str_glue(formulas[["m2"]], s = s)), data = base)
  V <- NeweyWest(m, lag = 3, prewhite = FALSE)
  b <- coef(m)
  t_crit <- qt(0.975, df = m$df.residual)
  i1 <- "delta_selic"; i3 <- "delta_selic:ciclo_alta"
  tibble(ciclo     = c("queda", "alta"),
         estimate  = c(b[[i1]], b[[i1]] + b[[i3]]),
         std.error = c(sqrt(V[i1, i1]), sqrt(V[i1, i1] + V[i3, i3] + 2 * V[i1, i3]))) |>
    mutate(p.value   = 2 * pt(abs(estimate / std.error), df = m$df.residual, lower.tail = FALSE),
           conf.low  = estimate - t_crit * std.error,
           conf.high = estimate + t_crit * std.error,
           # p-valor de β3: testa se o efeito é diferente entre os ciclos
           p_diferenca = coeftest(m, vcov. = V)[i3, "Pr(>|t|)"])
}

efeitos_ciclo <- tibble(setor = SETORES) |>
  mutate(res = map(setor, efeito_por_ciclo)) |>
  unnest(res)

write_csv(mutate(efeitos_ciclo, across(where(is.numeric), \(x) round(x, 4))),
          file.path(PASTA_TAB, "t6_efeito_por_ciclo.csv"))

g6 <- efeitos_ciclo |>
  mutate(setor = factor(NOMES[setor], levels = rev(NOMES[SETORES])),
         ciclo = factor(ciclo, levels = c("queda", "alta"),
                        labels = c("Cortes (ciclo de queda)", "Altas (ciclo de alta)"))) |>
  ggplot(aes(estimate, setor, color = ciclo)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high),
                  position = position_dodge(width = 0.5), linewidth = 0.9, size = 0.5) +
  scale_color_manual(values = c("Altas (ciclo de alta)" = "#1F3864", "Cortes (ciclo de queda)" = "#9DB4D6"),
                     breaks = c("Altas (ciclo de alta)", "Cortes (ciclo de queda)")) +
  labs(title    = "Não há diferença significativa entre a reação a altas e a cortes da Selic",
       subtitle = paste0("Retorno mensal (p.p.) por 1 p.p. de variação da Selic, controlando pelo Ibovespa. ",
                         "Toda alta ocorre em ciclo de alta\ne todo corte em ciclo de queda. ",
                         "Barras: intervalo de confiança de 95% (Newey-West). Teste com pouco poder."),
       x = "Efeito da variação da Selic (p.p.)", y = NULL, caption = FONTE) +
  tema_projeto()
salvar(g6, "g6_sensibilidade_por_ciclo.png", largura = 8, altura = 4)

# =========================================================================
# 5. Robustez: cesta de varejo sem MGLU3
# =========================================================================
varejo_sem_mglu <- ativos |>
  filter(setor == "varejo", symbol != "MGLU3.SA") |>
  group_by(mes) |>
  summarise(ret_varejo_sem_mglu = mean(ret), .groups = "drop")

base_rob <- left_join(base, varejo_sem_mglu, by = "mes")

# Cada ação de varejo sozinha, para ver quem puxa o resultado
acoes_varejo <- ativos |>
  filter(setor == "varejo") |>
  mutate(acao = str_remove(symbol, "\\.SA$")) |>
  select(mes, acao, ret) |>
  pivot_wider(names_from = acao, values_from = ret, names_prefix = "ret_")
base_rob <- left_join(base_rob, acoes_varejo, by = "mes")

especificacoes <- c(
  "Varejo com MGLU3 (cesta)" = "ret_varejo",
  "Varejo sem MGLU3"         = "ret_varejo_sem_mglu",
  "Só LREN3"                 = "ret_LREN3",
  "Só MGLU3"                 = "ret_MGLU3",
  "Só RADL3"                 = "ret_RADL3"
)

robustez <- imap(especificacoes, \(y, nome) {
  estimar(base_rob, paste(y, "~ delta_selic + ret_ibov")) |> mutate(especificacao = nome)
}) |>
  list_rbind() |>
  filter(term == "delta_selic") |>
  select(especificacao, estimate, std.error, p.value, conf.low, conf.high, r2, n)

write_csv(mutate(robustez, across(where(is.numeric), \(x) round(x, 4))),
          file.path(PASTA_TAB, "t5_robustez_varejo.csv"))

# =========================================================================
# 6. Resumo no console
# =========================================================================
cat("\n=== 1. Estatística descritiva (% ao mês; acumulado e anual em %) ===\n")
print(descritiva, width = Inf)

cat("\n=== 2. Retorno médio mensal por ciclo (%) ===\n")
print(por_ciclo |> mutate(retorno_medio = round(retorno_medio, 2)) |>
        pivot_wider(names_from = ciclo, values_from = c(retorno_medio, meses)))

cat("\n=== 3. Correlações defasadas ===\n")
print(cor_defasadas |> mutate(across(c(correlacao, p_valor), \(x) round(x, 3))), n = Inf)

cat("\n=== 4. Regressões (erros-padrão Newey-West) ===\n")
print(regressoes |>
        select(setor, modelo, term, estimate, std.error, p.value, r2) |>
        mutate(across(where(is.numeric), \(x) round(x, 3))), n = Inf)

cat("\n=== 4b. H4: efeito da Selic em cada ciclo (modelo 2) ===\n")
print(efeitos_ciclo |> mutate(across(where(is.numeric), \(x) round(x, 3))), width = Inf)

cat("\n=== 5. Robustez: varejo com e sem MGLU3 (coeficiente da Selic) ===\n")
print(robustez |> mutate(across(where(is.numeric), \(x) round(x, 3))), width = Inf)

cat("\nFiguras salvas em", PASTA_FIG, "e tabelas em", PASTA_TAB, "\n")
