# 00_setup.R — rode UMA vez, com a pasta do projeto aberta no Positron (File > Open Folder)
# Instala os pacotes que faltam (inclusive dependências que falharam) e cria as pastas.

if (!dir.exists("scripts")) {
  stop("Diretório de trabalho errado: abra a PASTA do projeto no Positron (File > Open Folder). ",
       "Diretório atual: ", getwd())
}

# Pacotes grandes (ex.: stringi, ggplot2) podem passar do limite padrão de 60 s de download
options(timeout = 600)

# httr2 (API do BCB) e zoo (IPCA em 12 meses) já vêm com o tidyquant, mas ficam explícitos
pacotes <- c("tidyverse", "tidyquant", "rbcb", "jsonlite", "httr2", "zoo",
             "broom", "lmtest", "sandwich")

# Pelo Rscript (fora do Positron/RStudio) não há repositório do CRAN definido
if (getOption("repos")[["CRAN"]] %in% c("@CRAN@", "")) {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
}

carrega <- function(p) vapply(p, requireNamespace, logical(1), quietly = TRUE)

# Só vai à internet se algum pacote não carregar (assim o projeto roda offline depois de instalado)
if (!all(carrega(pacotes))) {
  # Instala o que não está instalado
  faltando <- setdiff(pacotes, rownames(installed.packages()))
  if (length(faltando) > 0) install.packages(faltando)

  # Confere se cada pacote CARREGA de verdade. Se uma dependência falhou no download,
  # o pacote aparece como instalado mas não carrega; nesse caso reinstalamos o que faltou.
  for (tentativa in 1:3) {
    deps <- tools::package_dependencies(pacotes, recursive = TRUE,
                                        db = available.packages())
    todos <- unique(c(pacotes, unlist(deps)))
    pacotes_base <- rownames(installed.packages(priority = "base"))
    sem_instalar <- setdiff(todos, c(rownames(installed.packages()), pacotes_base))
    if (length(sem_instalar) == 0) break
    message("Instalando dependências que faltaram: ", paste(sem_instalar, collapse = ", "))
    install.packages(sem_instalar)
  }
}

nao_carregam <- pacotes[!carrega(pacotes)]
if (length(nao_carregam) > 0) {
  stop("Estes pacotes ainda não carregam: ", paste(nao_carregam, collapse = ", "),
       ". Verifique a internet e rode este script de novo.")
}

# Se o rbcb der problema, use a versão do GitHub:
# install.packages("remotes"); remotes::install_github("wilsonfreitas/rbcb")
# (ou rode o 01_coleta_bcb.R com USAR_RBCB <- FALSE, que usa a API do BCB direto)

dir.create("dados/brutos",   recursive = TRUE, showWarnings = FALSE)
dir.create("dados/tratados", recursive = TRUE, showWarnings = FALSE)

cat("Pronto! Pacotes instalados e pastas criadas.\n")
