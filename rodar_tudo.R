# rodar_tudo.R — roda o projeto inteiro em ordem (coleta -> base mensal -> validação -> análise)
# No Positron: abra a pasta do projeto, abra este arquivo e clique no botão ▶ (Run).

# FALSE (padrão): REPRODUZ os resultados publicados a partir dos dados salvos em dados/brutos/.
# TRUE: baixa dados novos do BCB e do Yahoo Finance. Isso SUBSTITUI os arquivos de dados/brutos/
#       (a versão usada no relatório) e pode mudar todos os números, inclusive o período, quando
#       um novo mês de IPCA já tiver sido divulgado. Depois, releia o relatório renderizado.
BAIXAR_DADOS <- FALSE

source("scripts/00_setup.R")
if (BAIXAR_DADOS) {
  source("scripts/01_coleta_bcb.R")
  source("scripts/02_coleta_mercado.R")
} else {
  message("Usando os dados salvos em dados/brutos/ (BAIXAR_DADOS <- FALSE).")
}
source("scripts/03_base_mensal.R")
source("scripts/04_validacao.R")
source("scripts/05_analise.R")
