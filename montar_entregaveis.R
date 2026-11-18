# montar_entregaveis.R — monta os pacotes dos Entregáveis 1 a 4 prontos para enviar
# Rode DEPOIS do rodar_tudo.R. Resultado: pasta entregaveis/ com quatro pastas e quatro .zip.
# (O Entregável 5, README e instruções de reprodução, vai dentro do pacote 4 como README.md.)

source("scripts/parametros.R")

SAIDA <- "entregaveis"
E1 <- file.path(SAIDA, "Entregavel1_Coleta")
E2 <- file.path(SAIDA, "Entregavel2_Base")
E3 <- file.path(SAIDA, "Entregavel3_Analise")
E4 <- file.path(SAIDA, "Entregavel4_Relatorio")

# --- 0. Confere se tudo já foi gerado -----------------------------------
brutos   <- c("bcb_selic_meta.csv", "bcb_ipca.csv", "yahoo_precos_diarios.csv")
tratados <- c("base_mensal.csv", "base_mensal_excel.csv", "retornos_ativos_mensal.csv")
necessarios <- c(file.path(PASTA_BRUTOS, brutos), file.path(PASTA_TRATADOS, tratados),
                 "dados/dicionario_dados.md")
faltando <- necessarios[!file.exists(necessarios)]
if (length(faltando) > 0) {
  stop("Rode o rodar_tudo.R antes. Arquivos que faltam:\n  ", paste(faltando, collapse = "\n  "))
}

unlink(SAIDA, recursive = TRUE)  # começa do zero a cada execução
dir.create(file.path(E1, "scripts"),       recursive = TRUE)
dir.create(file.path(E1, "dados", "brutos"), recursive = TRUE)
dir.create(file.path(E2, "scripts"),       recursive = TRUE)

escrever <- function(linhas, caminho) {
  con <- file(caminho, open = "w", encoding = "UTF-8")
  writeLines(linhas, con)
  close(con)
}
fmt_data <- function(x) format(as.Date(x), "%d/%m/%Y")

# --- 1. Entregável 1: scripts de coleta + dados brutos ------------------
file.copy(file.path("scripts", c("parametros.R", "00_setup.R", "01_coleta_bcb.R", "02_coleta_mercado.R")),
          file.path(E1, "scripts"))
file.copy(file.path(PASTA_BRUTOS, brutos), file.path(E1, "dados", "brutos"))

selic  <- read_csv(file.path(PASTA_BRUTOS, "bcb_selic_meta.csv"),       show_col_types = FALSE)
ipca   <- read_csv(file.path(PASTA_BRUTOS, "bcb_ipca.csv"),             show_col_types = FALSE)
precos <- read_csv(file.path(PASTA_BRUTOS, "yahoo_precos_diarios.csv"), show_col_types = FALSE)

# Data da coleta gravada pelo 02 (a data de modificação do arquivo muda ao copiar ou clonar)
arq_data <- file.path(PASTA_BRUTOS, "data_coleta.txt")
data_coleta <- if (file.exists(arq_data)) {
  format(as.Date(readLines(arq_data, n = 1)), "%d/%m/%Y")
} else {
  format(file.mtime(file.path(PASTA_BRUTOS, "yahoo_precos_diarios.csv")), "%d/%m/%Y")
}
file.copy(arq_data, file.path(E1, "dados", "brutos"))
pregoes <- count(precos, symbol)
lista_tickers <- CESTAS |>
  group_by(setor) |>
  summarise(t = paste(sub("\\.SA$", "", ticker), collapse = ", "), .groups = "drop") |>
  mutate(linha = paste0("  - ", setor, ": ", t)) |>
  pull(linha)

escrever(c(
  "ENTREGÁVEL 1 — SCRIPTS DE COLETA",
  "Projeto: Juros e bolsa — como setores da B3 reagem à taxa Selic",
  "Disciplina: REC3302 — Introdução ao R Aplicado à Economia e Finanças (FEA-RP/USP)",
  "",
  "O QUE ESTES SCRIPTS FAZEM",
  "  - 00_setup.R: instala os pacotes necessários e cria as pastas.",
  "  - parametros.R: período, pastas e composição das cestas setoriais.",
  "  - 01_coleta_bcb.R: baixa do Banco Central (SGS) a meta Selic (série 432) e o IPCA mensal (série 433).",
  "  - 02_coleta_mercado.R: baixa do Yahoo Finance os preços diários ajustados de 9 ações e do Ibovespa.",
  "",
  "COMO RODAR",
  "  1. Abrir esta pasta no Positron (File > Open Folder) ou no RStudio.",
  "  2. Rodar, nesta ordem: scripts/00_setup.R, scripts/01_coleta_bcb.R e scripts/02_coleta_mercado.R.",
  "  3. Os dados são salvos em dados/brutos/.",
  "",
  "COLETA INCLUÍDA NESTE PACOTE",
  paste0("  - Data da coleta: ", data_coleta),
  paste0("  - Meta Selic: ", nrow(selic), " observações diárias, de ", fmt_data(min(selic$date)),
         " a ", fmt_data(max(selic$date))),
  paste0("  - IPCA: ", nrow(ipca), " meses, de ", format(min(ipca$date), "%m/%Y"),
         " a ", format(max(ipca$date), "%m/%Y")),
  paste0("  - Preços: ", n_distinct(precos$symbol), " tickers, de ", fmt_data(min(precos$date)),
         " a ", fmt_data(max(precos$date)), ", com ", min(pregoes$n),
         if (min(pregoes$n) != max(pregoes$n)) paste0(" a ", max(pregoes$n)) else "",
         " pregões por ticker"),
  "  - Composição das cestas:",
  lista_tickers,
  "",
  "OBSERVAÇÕES",
  "  - A API do BCB limita cada consulta a 10 anos; o script baixa em blocos de 3 anos e junta.",
  "  - As fontes são atualizadas com o tempo (meses novos e revisões de preços ajustados), então",
  "    rodar de novo em outra data pode gerar valores um pouco diferentes. Os arquivos em",
  "    dados/brutos/ registram exatamente o que foi coletado na data acima."
), file.path(E1, "README.txt"))

# --- 2. Entregável 2: base mensal + dicionário + validação --------------
file.copy(file.path(PASTA_TRATADOS, tratados), E2)
file.copy("dados/dicionario_dados.md", E2)
file.copy(file.path("scripts", c("parametros.R", "03_base_mensal.R", "04_validacao.R")),
          file.path(E2, "scripts"))

# Saída das checagens salva em texto
capture.output(source("scripts/04_validacao.R"), file = file.path(E2, "validacao.txt"))
linhas_val <- readLines(file.path(E2, "validacao.txt"), encoding = "UTF-8")
n_ok    <- sum(grepl("^\\s*OK\\s", linhas_val))
n_falha <- sum(grepl("^\\s*FALHA\\s", linhas_val))

base <- read_csv(file.path(PASTA_TRATADOS, "base_mensal.csv"), show_col_types = FALSE)

escrever(c(
  "ENTREGÁVEL 2 — BASE DE DADOS MENSAL",
  "Projeto: Juros e bolsa — como setores da B3 reagem à taxa Selic",
  "Disciplina: REC3302 — Introdução ao R Aplicado à Economia e Finanças (FEA-RP/USP)",
  "",
  "CONTEÚDO",
  paste0("  - base_mensal.csv: arquivo principal. ", nrow(base), " meses (",
         format(min(base$mes), "%m/%Y"), " a ", format(max(base$mes), "%m/%Y"), "), ",
         ncol(base), " variáveis."),
  "  - base_mensal_excel.csv: a mesma base no padrão brasileiro (ponto e vírgula e vírgula decimal), para abrir no Excel.",
  "  - retornos_ativos_mensal.csv: retorno mensal de cada ação, para testes de robustez.",
  "  - dicionario_dados.md: descrição de cada variável, unidades, fontes e regras de construção.",
  "  - validacao.txt: resultado das checagens automáticas da base.",
  "  - scripts/: código que constrói (03_base_mensal.R) e valida (04_validacao.R) a base.",
  "",
  "COMO A BASE FOI CONSTRUÍDA",
  "  - Preço do mês: preço ajustado do último pregão do mês; retorno simples mensal, em %.",
  "  - Setores: cestas de 3 ações (bancos, varejo e utilities), com média simples dos retornos.",
  "  - Selic: meta vigente no fim do mês; delta_selic é a variação no mês, em pontos percentuais.",
  "  - Ciclo: direção do último movimento do Copom (alta ou queda); meses sem mudança herdam o ciclo vigente.",
  "  - Juro real ex-post: (1 + Selic) / (1 + IPCA acumulado em 12 meses) - 1.",
  "  - Só entram meses completos e com IPCA já divulgado.",
  "",
  "VALIDAÇÃO",
  paste0("  - ", n_ok, " checagens OK e ", n_falha, " falha(s). Detalhes em validacao.txt."),
  "",
  "COMO REPRODUZIR",
  "  A base é gerada a partir dos dados brutos do Entregável 1. Copie os scripts deste pacote",
  "  para a pasta scripts/ do Entregável 1 e rode 03_base_mensal.R e depois 04_validacao.R.",
  "  Os arquivos são gerados em dados/tratados/."
), file.path(E2, "README.txt"))

# --- 3. Entregável 3: análise de dados -----------------------------------
# Pasta autocontida: tem a base de entrada, o script e os resultados, então quem
# abrir a pasta no Positron/RStudio consegue rodar scripts/05_analise.R direto.
dir.create(file.path(E3, "scripts"),                 recursive = TRUE)
dir.create(file.path(E3, PASTA_TRATADOS),            recursive = TRUE)
dir.create(file.path(E3, "resultados", "figuras"),   recursive = TRUE)
dir.create(file.path(E3, "resultados", "tabelas"),   recursive = TRUE)

# Roda a análise de novo para garantir que figuras e tabelas estão atualizadas,
# guardando a saída do console. Ambiente separado para não sobrescrever objetos daqui.
pdf(NULL)  # print() dos gráficos vai para um dispositivo nulo (não cria Rplots.pdf)
saida_analise <- capture.output(source("scripts/05_analise.R", local = new.env(), encoding = "UTF-8"))
dev.off()
escrever(saida_analise, file.path(E3, "saida_console.txt"))

file.copy(file.path("scripts", c("parametros.R", "05_analise.R")), file.path(E3, "scripts"))
file.copy(file.path(PASTA_TRATADOS, c("base_mensal.csv", "retornos_ativos_mensal.csv")),
          file.path(E3, PASTA_TRATADOS))
file.copy(list.files("resultados/figuras", full.names = TRUE), file.path(E3, "resultados", "figuras"))
file.copy(list.files("resultados/tabelas", full.names = TRUE), file.path(E3, "resultados", "tabelas"))

# Números do resumo lidos das tabelas (assim o README acompanha os resultados)
num <- function(x, d = 2) formatC(x, format = "f", digits = d, decimal.mark = ",")
pv  <- function(p) if (p < 0.001) "p < 0,001" else paste0("p = ", num(p, 3))

t2 <- read_csv("resultados/tabelas/t2_retorno_por_ciclo.csv",     show_col_types = FALSE)
t3 <- read_csv("resultados/tabelas/t3_correlacoes_defasadas.csv", show_col_types = FALSE)
t4 <- read_csv("resultados/tabelas/t4_regressoes.csv",            show_col_types = FALSE)
t5 <- read_csv("resultados/tabelas/t5_robustez_varejo.csv",       show_col_types = FALSE)
t6 <- read_csv("resultados/tabelas/t6_efeito_por_ciclo.csv",      show_col_types = FALSE)

coef_m1 <- function(s, termo = "delta_selic") filter(t4, setor == s, modelo == "m1", term == termo)
rob     <- function(esp) filter(t5, especificacao == esp)
ciclo_m <- function(s, c) filter(t2, serie == s, ciclo == c)$retorno_medio

b_var <- coef_m1("varejo"); b_ban <- coef_m1("bancos"); b_uti <- coef_m1("utilities")
sem_mglu <- rob("Varejo sem MGLU3"); so_mglu <- rob("Só MGLU3")
cor_var_sig <- filter(t3, setor == "varejo", p_valor < 0.05)$defasagem
p_dif <- distinct(t6, setor, p_diferenca)

escrever(c(
  "ENTREGÁVEL 3 — ANÁLISE DE DADOS",
  "Projeto: Juros e bolsa — como setores da B3 reagem à taxa Selic",
  "Disciplina: REC3302 — Introdução ao R Aplicado à Economia e Finanças (FEA-RP/USP)",
  "",
  "PERGUNTA",
  "  Mudanças na Selic afetam de forma diferente o retorno de setores da B3?",
  paste0("  Amostra: ", nrow(base), " meses (", format(min(base$mes), "%m/%Y"), " a ",
         format(max(base$mes), "%m/%Y"), "), cestas de 3 ações por setor, Ibovespa como mercado."),
  "",
  "CONTEÚDO",
  "  - scripts/05_analise.R: código de toda a análise (usa scripts/parametros.R).",
  "  - dados/tratados/: base mensal de entrada (vem do Entregável 2).",
  "  - resultados/figuras/: gráficos em PNG, 300 dpi.",
  "      g1 retorno acumulado | g2 Selic e ciclos | g3 retorno médio por ciclo",
  "      g4 correlações defasadas | g5 sensibilidade à Selic | g6 sensibilidade por ciclo",
  "  - resultados/tabelas/: tabelas em CSV (separador vírgula, decimal ponto).",
  "      t1 estatística descritiva | t2 retorno por ciclo | t3 correlações defasadas",
  "      t4 regressões | t5 robustez do varejo | t6 efeito da Selic em cada ciclo",
  "  - saida_console.txt: tudo o que o script imprime ao rodar.",
  "",
  "MÉTODO",
  "  1. Descritiva: média, desvio, retorno acumulado e anualizado, volatilidade anual;",
  "     retorno médio separado por ciclo de alta e de queda da Selic.",
  "  2. Correlações entre o retorno do setor no mês t e a variação da Selic em t, t-1, t-2 e t-3.",
  "  3. Regressões por setor, com erros-padrão Newey-West (lag 3):",
  "       m1: ret_setor = a + b1*delta_selic + b2*ret_ibov + e",
  "       m2: m1 + ciclo_alta + delta_selic*ciclo_alta   (b1 = efeito na queda; b1+b3 = efeito na alta)",
  "     Pela definição de ciclo, toda alta da Selic cai em ciclo de alta e todo corte em ciclo de",
  "     queda: na prática, o m2 compara a reação a cortes (b1) com a reação a altas (b1+b3).",
  "     O controle pelo Ibovespa isola a reação própria do setor, além do movimento geral da bolsa.",
  "  4. Robustez: varejo sem MGLU3 e cada ação de varejo sozinha.",
  "",
  "RESULTADOS (associações; não medem efeito causal)",
  paste0("  H1 (varejo reage negativamente) — APOIADA EM PARTE. +1 p.p. na Selic vem acompanhado de"),
  paste0("     retorno mensal ", num(-b_var$estimate), " p.p. menor no varejo (", pv(b_var$p.value),
         "). Porém o efeito vem da MGLU3:"),
  paste0("     sozinha ela dá ", num(so_mglu$estimate), " (", pv(so_mglu$p.value),
         "), e a cesta sem ela dá ", num(sem_mglu$estimate), " (", pv(sem_mglu$p.value), ")."),
  paste0("     A correlação também é significativa nas defasagens ", paste(cor_var_sig, collapse = ", "),
         ", mas a própria variação da Selic"),
  "     é autocorrelacionada (o Copom move os juros em sequência), então isso não prova reação atrasada.",
  paste0("  H2 (bancos: relação fraca ou positiva) — APOIADA (sem efeito detectável). Coeficiente ",
         num(b_ban$estimate), " (", pv(b_ban$p.value), ")."),
  "     Ressalva: a comparação com o varejo depende da MGLU3; sem ela, o varejo também não reage.",
  paste0("  H3 (utilities defensivas) — APOIADA SÓ QUANTO AOS JUROS: coeficiente ", num(b_uti$estimate),
         " (", pv(b_uti$p.value), "), sem efeito detectável."),
  paste0("     Mas o beta de mercado das utilities é ", num(coef_m1("utilities", "ret_ibov")$estimate),
         ": elas acompanham a bolsa quase 1 para 1."),
  paste0("  H4 (a relação muda entre ciclos) — NÃO APOIADA. A diferença entre a reação a altas e a cortes"),
  paste0("     não é significativa em nenhum setor (p entre ", num(min(p_dif$p_diferenca), 2), " e ",
         num(max(p_dif$p_diferenca), 2), "); o teste tem pouco poder."),
  paste0("     Na média simples o varejo rende ", num(ciclo_m("varejo", "queda")), "% ao mês na queda contra ",
         num(ciclo_m("varejo", "alta")), "% na alta,"),
  paste0("     mas essa diferença não é estatisticamente significativa (teste t, ",
         pv(t.test(ret_varejo ~ ciclo, data = base)$p.value), "): o varejo oscila demais"),
  paste0("     para que médias de cerca de ", round(mean(table(base$ciclo))), " meses separem os ciclos."),
  "",
  "LIMITAÇÕES",
  "  - Cestas pequenas (3 ações): uma ação volátil, como a MGLU3, domina o resultado do setor.",
  "  - O ciclo herda a direção do último movimento do Copom; não há estado \"estável\". Por isso",
  "    os ciclos de alta incluem os meses de manutenção no topo, até o primeiro corte.",
  "  - Usa a variação realizada da Selic, não a surpresa em relação às expectativas do mercado,",
  "    que já pode estar nos preços antes da reunião do Copom.",
  "",
  "COMO REPRODUZIR",
  "  Abrir esta pasta no Positron (File > Open Folder) ou no RStudio e rodar scripts/05_analise.R.",
  "  Pacotes: tidyverse, broom, lmtest, sandwich. Figuras e tabelas são recriadas em resultados/."
), file.path(E3, "README.txt"))

# --- 4. Entregável 4: relatório, tutorial e README -----------------------
# Renderiza o relatório e o tutorial (HTML e PDF) com o Quarto, que já vem com o Positron/RStudio.
achar_quarto <- function() {
  candidatos <- c(
    Sys.which("quarto"),
    file.path(Sys.getenv("LOCALAPPDATA"), "Programs/Positron/resources/app/quarto/bin/quarto.exe"),
    "C:/Program Files/Positron/resources/app/quarto/bin/quarto.exe",
    "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe",
    "C:/Program Files/Quarto/bin/quarto.exe"
  )
  candidatos <- candidatos[nzchar(candidatos) & file.exists(candidatos)]
  if (length(candidatos) == 0) NA_character_ else unname(candidatos[1])
}

quarto <- achar_quarto()
if (!is.na(quarto)) {
  cat("\nRenderizando relatório e tutorial com o Quarto...\n")
  # system2() já põe o caminho entre aspas; não usar shQuote() aqui
  if (system2(normalizePath(quarto), "render") != 0) stop("O quarto render falhou. Veja as mensagens acima.")
} else {
  message("Quarto não encontrado; usando o relatório já renderizado em relatorio/.")
}

saidas <- file.path("relatorio", c("relatorio.html", "relatorio.pdf", "tutorial.html", "tutorial.pdf"))
if (!all(file.exists(saidas))) {
  stop("Renderize o relatório antes (no terminal: quarto render). Faltam:\n  ",
       paste(saidas[!file.exists(saidas)], collapse = "\n  "))
}
if (min(file.mtime(saidas)) < max(file.mtime(list.files("resultados/tabelas", full.names = TRUE)))) {
  warning("O relatório é mais antigo que os resultados da análise. Rode 'quarto render' de novo.")
}

dir.create(file.path(E4, "codigo_fonte", "relatorio"), recursive = TRUE)
file.copy(saidas, E4)
file.copy("README.md", E4)
file.copy("_quarto.yml", file.path(E4, "codigo_fonte"))
file.copy(file.path("relatorio", c("relatorio.qmd", "tutorial.qmd", "_comum.R", "_metadata.yml",
                                   "estilo.scss", "estilo.typ")),
          file.path(E4, "codigo_fonte", "relatorio"))

escrever(c(
  "ENTREGÁVEL 4 — RELATÓRIO DE MERCADO, TUTORIAL E README",
  "Projeto: Juros e bolsa — como setores da B3 reagem à taxa Selic",
  "Disciplina: REC3302 — Introdução ao R Aplicado à Economia e Finanças (FEA-RP/USP)",
  "",
  "CONTEÚDO",
  "  - relatorio.pdf / relatorio.html: relatório de mercado. A página 2 é o resumo executivo,",
  "    em 1 página; depois vêm contexto, dados e metodologia, resultados (H1 a H4), robustez,",
  "    implicações para o investidor e limitações.",
  "  - tutorial.pdf / tutorial.html: passo a passo em R, do dado bruto à regressão. O código é",
  "    executado de verdade e confere que reconstrói exatamente a base do projeto.",
  "  - README.md: apresentação do projeto e instruções de reprodução (Entregável 5).",
  "  - codigo_fonte/: arquivos Quarto (.qmd) e de estilo que geram o relatório e o tutorial.",
  "",
  "OS ARQUIVOS HTML",
  "  São autocontidos (figuras incluídas): basta abrir no navegador, sem internet.",
  "",
  "COMO OS NÚMEROS SÃO GERADOS",
  "  Os números do texto e das tabelas do relatório são lidos de resultados/tabelas/ (gerados por",
  "  scripts/05_analise.R), e os títulos dos gráficos são calculados no próprio 05. Se os dados",
  "  forem atualizados, basta rodar a análise e renderizar de novo; só o período no subtítulo do",
  "  relatório e as frases interpretativas precisam ser relidos.",
  "",
  "COMO REGENERAR",
  "  No projeto completo, na pasta do projeto: quarto render",
  "  (ou, no Positron, abrir relatorio/relatorio.qmd e clicar em Render)."
), file.path(E4, "README.txt"))

# --- 5. Compactar em .zip -----------------------------------------------
compactar <- function(pasta) {
  destino <- paste0(pasta, ".zip")
  if (.Platform$OS.type == "windows") {
    cmd <- sprintf("Compress-Archive -Path '%s' -DestinationPath '%s' -Force",
                   normalizePath(pasta), file.path(normalizePath(dirname(pasta)), basename(destino)))
    status <- system2("powershell", c("-NoProfile", "-Command", shQuote(cmd, type = "cmd")))
  } else {
    old <- setwd(dirname(pasta)); on.exit(setwd(old))
    status <- utils::zip(basename(destino), basename(pasta))
  }
  if (!identical(as.integer(status), 0L) || !file.exists(destino)) {
    message("Não consegui criar ", destino, ". Compacte a pasta manualmente ",
            "(botão direito > Compactar / Enviar para > Pasta compactada).")
  }
}
compactar(E1)
compactar(E2)
compactar(E3)
compactar(E4)

cat("\nPronto! Veja a pasta '", SAIDA, "':\n", sep = "")
print(list.files(SAIDA, recursive = TRUE))
if (n_falha > 0) warning("A validação teve ", n_falha, " falha(s). Confira validacao.txt antes de enviar.")
