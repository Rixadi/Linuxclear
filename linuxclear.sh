#!/usr/bin/env bash
#
# pwd404-clean.sh — utilitário de limpeza para Arch Linux
# by pwd404
#
# O que faz, na ordem:
#   1) paccache -rk2 (poda cache do pacman mantendo 2 versões — nunca -Scc)
#   2) remove diretórios órfãos download-* (downloads interrompidos)
#   3) remove pacotes órfãos (pacman -Qtdq), com confirmação
#   4) limpa cache do yay/paru, journald, /tmp, /var/tmp
#   5) limpa cache do usuário (por idade, a menos que -a seja usado)
#   6) lixeira (-t), thumbnails, core dumps, logs rotacionados antigos
#   7) backup opcional via Timeshift (-b) e reboot opcional (-r)
#
set -uo pipefail

# ──────────────── PALETA ────────────────
AZUL='\033[0;34m'
CIANO='\033[0;36m'
CIANO_N='\033[1;36m'
BRANCO='\033[1;37m'
CINZA='\033[0;90m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NEGRITO='\033[1m'
NC='\033[0m'

log()  { echo -e "${VERDE}[OK]${NC} $1"; }
warn() { echo -e "${AMARELO}[AVISO]${NC} $1"; }
err()  { echo -e "${VERMELHO}[ERRO]${NC} $1"; }

# ──────────────── CABEÇALHO ────────────────
MAGENTA='\033[0;35m'
ROXO='\033[1;35m'

echo -e "${AMARELO} ________________________________________ ${NC}"
echo -e "${AMARELO}( ${BRANCO}The best cure for insomnia is to get a${AMARELO} )${NC}"
echo -e "${AMARELO}( ${BRANCO}lot of sleep. -W.C. Fields${AMARELO}             )${NC}"
echo -e "${AMARELO} ---------------------------------------- ${NC}"
echo -e "${CINZA}        o   ${BRANCO}^__^${NC}"
echo -e "${CINZA}         o  ${BRANCO}(oo)\\\\_______${NC}"
echo -e "${CINZA}            ${BRANCO}(__)\\\\       )\\\\/\\\\${NC}"
echo -e "${CINZA}                ${BRANCO}||----w |${NC}"
echo -e "${CINZA}                ${BRANCO}||     ||${NC} ${ROXO}#pwed404${NC}"
echo ""

# ──────────────── ANIMAÇÃO DE INÍCIO ────────────────
spin_msg() {
    local msg="$1"
    local steps="${2:-14}"
    local frames=("|" "/" "-" "\\")
    local i=0
    for ((n=0; n<steps; n++)); do
        printf "\r${CIANO_N}[%s]${NC} %s" "${frames[$i]}" "$msg"
        i=$(( (i+1) % 4 ))
        sleep 0.07
    done
    printf "\r${VERDE}[OK]${NC} %s\n" "$msg"
}

spin_msg "Carregando pwd404-clean..." 16
spin_msg "Verificando ambiente Arch..." 10

# Não rode como root direto — o script pede sudo só onde precisa
if [[ $EUID -eq 0 ]]; then
    err "Não rode este script como root/sudo diretamente. Ele pede sudo quando precisar."
    exit 1
fi

# ──────────────── FLAGS & ARGS ────────────────
BACKUP=0
CLEAN_TRASH=0
REBOOT=0
AGGRESSIVE=0
ASSUME_YES=0

usage() {
    cat <<USAGE
Uso: $0 [opções]

  -b    Fazer backup com Timeshift antes de limpar
  -t    Esvaziar a lixeira
  -r    Reiniciar ao final
  -a    Modo agressivo (equivale a "Limpeza profunda")
  -y    Não perguntar nada, assume "sim" pra tudo (não interativo)
  -h    Mostra esta ajuda

Sem nenhuma flag, entra no menu interativo.
USAGE
}

if [[ $# -gt 0 ]]; then
    while getopts ":btray h" opt; do
        case $opt in
            b) BACKUP=1 ;;
            t) CLEAN_TRASH=1 ;;
            r) REBOOT=1 ;;
            a) AGGRESSIVE=1 ;;
            y) ASSUME_YES=1 ;;
            h) usage; exit 0 ;;
            \?) err "Opção inválida: -$OPTARG"; usage; exit 1 ;;
        esac
    done
else
    # ──────────────── MENU PRINCIPAL ────────────────
    echo -e "${CIANO}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CIANO}║${NC}   ${NEGRITO}${BRANCO}pwd404${NC} ${CINZA}—${NC} ${NEGRITO}o que vamos limpar hoje?${NC}          ${CIANO}║${NC}"
    echo -e "${CIANO}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${CIANO}║${NC}  ${VERDE}${NEGRITO}[1]${NC} Limpeza leve                              ${CIANO}║${NC}"
    echo -e "${CIANO}║${NC}      ${CINZA}cache antigo, órfãos, journal, /tmp${NC}      ${CIANO}║${NC}"
    echo -e "${CIANO}║${NC}                                                 ${CIANO}║${NC}"
    echo -e "${CIANO}║${NC}  ${VERMELHO}${NEGRITO}[2]${NC} Limpeza profunda ${CINZA}(lá ele)${NC}                ${CIANO}║${NC}"
    echo -e "${CIANO}║${NC}      ${CINZA}tudo da leve + zera cache do usuário,${NC}    ${CIANO}║${NC}"
    echo -e "${CIANO}║${NC}      ${CINZA}/tmp e /var/tmp por completo${NC}             ${CIANO}║${NC}"
    echo -e "${CIANO}╚═══════════════════════════════════════════════╝${NC}"
    echo ""

    while true; do
        read -rp "$(echo -e "${NEGRITO}Escolha uma opção [1/2]: ${NC}")" opcao
        case "$opcao" in
            1)
                AGGRESSIVE=0
                log "Modo selecionado: Limpeza leve."
                break
                ;;
            2)
                echo ""
                warn "Modo profundo apaga TODO o cache do usuário e /tmp, sem checar idade dos arquivos."
                read -rp "$(echo -e "${VERMELHO}Tem certeza? Isso é lá com você (s/N): ${NC}")" -n 1 -r confirm; echo
                if [[ "$confirm" =~ ^[sS]$ ]]; then
                    AGGRESSIVE=1
                    log "Modo selecionado: Limpeza profunda. Lá ele."
                    break
                else
                    warn "Cancelado. Escolha novamente."
                fi
                ;;
            *)
                warn "Opção inválida. Digite 1 ou 2."
                ;;
        esac
    done

    echo ""
    read -rp "Fazer backup com Timeshift antes de limpar? (y/N): " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && BACKUP=1

    read -rp "Esvaziar a lixeira? (y/N): " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && CLEAN_TRASH=1

    read -rp "Reiniciar ao final? (y/N): " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && REBOOT=1
fi

# ──────────────── ESPAÇO ANTES ────────────────
ESPACO_ANTES=$(df -h / | awk 'NR==2 {print $4}')
echo ""
echo "=========================================="
echo " Espaço livre antes: $ESPACO_ANTES"
echo "=========================================="

# ──────────────── BACKUP COM TIMESHIFT (opcional) ────────────────
if [[ $BACKUP -eq 1 ]]; then
    echo ""
    echo "-> Verificando Timeshift..."

    if ! command -v timeshift &>/dev/null; then
        warn "Timeshift não encontrado. Instalando..."
        if ! sudo pacman -S --needed --noconfirm timeshift; then
            err "Falha ao instalar Timeshift. Pulando backup."
            BACKUP=0
        else
            log "Timeshift instalado."
        fi
    fi

    if [[ $BACKUP -eq 1 ]]; then
        if sudo timeshift --check 2>/dev/null | grep -q "No snapshots found"; then
            warn "Timeshift não configurado. Rode 'sudo timeshift-gtk' ou 'sudo timeshift --setup' primeiro."
            warn "Pulando backup automático."
        else
            echo "-> Criando snapshot (Ctrl+C para cancelar, 2s)..."
            sleep 2
            sudo timeshift --create --comments "arch-cleaner backup automático" --tags D
            log "Snapshot criado."
        fi
    fi
fi

# ──────────────── 1. CACHE DO PACMAN (paccache, seguro) ────────────────
echo ""
if command -v paccache &>/dev/null; then
    echo "-> Limpando cache antigo do pacman (mantendo 2 versões por pacote)..."
    sudo paccache -rk2
    log "Cache do pacman limpo."
else
    warn "paccache não encontrado. Instalando pacman-contrib..."
    sudo pacman -S --needed --noconfirm pacman-contrib
    sudo paccache -rk2
    log "Cache do pacman limpo."
fi

# 1b. Corrigir diretórios órfãos download-* (bug conhecido de downloads interrompidos)
echo ""
echo "-> Verificando diretórios órfãos de downloads interrompidos..."
ORFAOS_DOWNLOAD=$(sudo find /var/cache/pacman/pkg -maxdepth 1 -type d -name "download-*" 2>/dev/null)
if [[ -n "$ORFAOS_DOWNLOAD" ]]; then
    echo "Encontrados:"
    echo "$ORFAOS_DOWNLOAD"
    sudo find /var/cache/pacman/pkg -maxdepth 1 -type d -name "download-*" -exec rm -rf {} +
    log "Diretórios órfãos de download removidos."
else
    log "Nenhum diretório órfão de download encontrado."
fi

# ──────────────── 2. PACOTES ÓRFÃOS ────────────────
echo ""
echo "-> Procurando pacotes órfãos..."
ORFAOS=$(pacman -Qtdq 2>/dev/null || true)
if [[ -n "$ORFAOS" ]]; then
    echo "Pacotes órfãos encontrados:"
    echo "$ORFAOS"
    if [[ $ASSUME_YES -eq 1 ]]; then
        resp="s"
    else
        read -rp "Remover esses pacotes órfãos? [s/N] " resp
    fi
    if [[ "$resp" =~ ^[sS]$ ]]; then
        echo "$ORFAOS" | sudo pacman -Rns --noconfirm -
        log "Pacotes órfãos removidos."
    else
        warn "Remoção de órfãos ignorada."
    fi
else
    log "Nenhum pacote órfão encontrado."
fi

# ──────────────── 3. CACHE DO YAY/PARU (AUR) ────────────────
for AUR_HELPER in yay paru; do
    if command -v "$AUR_HELPER" &>/dev/null; then
        echo ""
        echo "-> Limpando cache do $AUR_HELPER..."
        "$AUR_HELPER" -Sc --noconfirm
        log "Cache do $AUR_HELPER limpo."
    fi
done

# ──────────────── 4. LOGS DO JOURNALD ────────────────
echo ""
echo "-> Limpando logs do journald (mantendo 7 dias / 200M)..."
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=200M
log "Logs do journald reduzidos."

# ──────────────── 5. /tmp E /var/tmp ────────────────
echo ""
echo "-> Limpando /tmp e /var/tmp..."
if [[ $AGGRESSIVE -eq 1 ]]; then
    sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
    log "/tmp e /var/tmp limpos por completo (modo agressivo)."
else
    sudo find /tmp -type f -atime +1 -delete 2>/dev/null || true
    sudo find /tmp -type d -empty -delete 2>/dev/null || true
    sudo find /var/tmp -type f -atime +7 -delete 2>/dev/null || true
    log "/tmp (arquivos +1 dia) e /var/tmp (+7 dias) limpos."
fi

# ──────────────── 6. CACHE DO USUÁRIO ────────────────
echo ""
echo "-> Limpando cache do usuário (~/.cache)..."
if [[ $AGGRESSIVE -eq 1 ]]; then
    rm -rf "$HOME/.cache/"* 2>/dev/null || true
    log "~/.cache limpo por completo (modo agressivo)."
else
    find "$HOME/.cache" -type f -atime +30 -delete 2>/dev/null || true
    log "~/.cache limpo (arquivos com mais de 30 dias)."
fi

# ──────────────── 7. LIXEIRA (opcional) ────────────────
if [[ $CLEAN_TRASH -eq 1 ]]; then
    echo ""
    echo "-> Esvaziando lixeira..."
    if [[ -d "$HOME/.local/share/Trash" ]]; then
        rm -rf "$HOME/.local/share/Trash/files/"* "$HOME/.local/share/Trash/info/"* 2>/dev/null || true
        log "Lixeira do usuário esvaziada."
    else
        warn "Nenhuma lixeira encontrada em ~/.local/share/Trash."
    fi
fi

# ──────────────── 8. THUMBNAILS ────────────────
echo ""
if [[ -d "$HOME/.cache/thumbnails" ]]; then
    echo "-> Limpando cache de thumbnails..."
    rm -rf "$HOME/.cache/thumbnails/"* 2>/dev/null || true
    log "Cache de thumbnails limpo."
fi

# ──────────────── 9. CORE DUMPS ────────────────
echo ""
echo "-> Removendo core dumps antigos (+7 dias)..."
sudo find /var/lib/systemd/coredump -type f -mtime +7 -delete 2>/dev/null || true
log "Core dumps antigos removidos."

# ──────────────── 10. LOGS ROTACIONADOS ANTIGOS ────────────────
echo ""
echo "-> Removendo logs rotacionados antigos em /var/log (+30 dias)..."
sudo find /var/log -type f \( -name "*.gz" -o -name "*.old" -o -name "*.1" \) -mtime +30 -delete 2>/dev/null || true
log "Logs antigos removidos."

# ──────────────── 11. ATUALIZAR LOCATE DB (opcional) ────────────────
if command -v updatedb &>/dev/null; then
    echo ""
    echo "-> Atualizando banco de dados do locate..."
    sudo updatedb 2>/dev/null && log "Banco do locate atualizado." || warn "Falha ao atualizar locate."
fi

# ──────────────── ANIMAÇÃO DE CONCLUSÃO ────────────────
ESPACO_DEPOIS=$(df -h / | awk 'NR==2 {print $4}')
echo ""

RAINBOW=("\033[0;31m" "\033[0;33m" "\033[1;33m" "\033[0;32m" "\033[0;36m" "\033[0;34m" "\033[0;35m")
LARGURA=49

# efeito de "vassoura" varrendo a linha, deixando rastro colorido
for ((pos=0; pos<=LARGURA; pos++)); do
    linha=""
    for ((c=0; c<pos; c++)); do
        cor=${RAINBOW[$(( c % ${#RAINBOW[@]} ))]}
        linha+="${cor}·${NC}"
    done
    printf "\r${BRANCO}[${linha}${CINZA}$(printf '%*s' $((LARGURA-pos)) '' | tr ' ' '.')${BRANCO}] ${NEGRITO}(=🧹${NC}"
    sleep 0.012
done
printf "\n"

# banner de conclusão colorido
echo ""
echo -e "${VERDE}   ╭─────────────────────────────────────────╮${NC}"
echo -e "${VERDE}   │${NC}   ${NEGRITO}${BRANCO}✔  LIMPEZA CONCLUÍDA${NC}   ${ROXO}~ pwd404 ~${NC}          ${VERDE}│${NC}"
echo -e "${VERDE}   ╰─────────────────────────────────────────╯${NC}"
echo ""
echo -e "        ${CINZA}o   ${BRANCO}^__^${NC}   ${CINZA}(nada de poeira por aqui)${NC}"
echo -e "         ${CINZA}o  ${BRANCO}(--)\\\\_______${NC}"
echo -e "            ${BRANCO}(__)\\\\       )\\\\/\\\\${NC}"
echo -e "                ${BRANCO}||----w |${NC}"
echo -e "                ${BRANCO}||     ||${NC}"
echo ""
echo -e "   ${CIANO}┌───────────────────────────────────┐${NC}"
printf "   ${CIANO}│${NC} Espaço livre ${CINZA}antes${NC}:  ${AMARELO}%-15s${NC} ${CIANO}│${NC}\n" "$ESPACO_ANTES"
printf "   ${CIANO}│${NC} Espaço livre ${VERDE}depois${NC}: ${VERDE}${NEGRITO}%-15s${NC} ${CIANO}│${NC}\n" "$ESPACO_DEPOIS"
echo -e "   ${CIANO}└───────────────────────────────────┘${NC}"
echo ""

# ──────────────── REBOOT (opcional) ────────────────
if [[ $REBOOT -eq 1 ]]; then
    echo ""
    warn "Reiniciando em 5 segundos... (Ctrl+C para cancelar)"
    sleep 5
    sudo reboot
fi