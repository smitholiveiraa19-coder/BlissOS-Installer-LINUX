#!/bin/bash

# --- Configurações de Cores e Estética ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 
BOLD='\033[1m'

# --- Variáveis de Ambiente ---
# Detecta o usuário real mesmo rodando com sudo
REAL_USER=$(logname || echo $USER)
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
DOWNLOADS_DIR="$USER_HOME/Downloads"
ISO_NAME="BLISSOS.iso"
TARGET_DIR="/blissos"
LOG_FILE="/var/log/bliss_install.log"

# --- Funções de Apoio ---
log_action() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}[OK]${NC} $1" | tee -a "$LOG_FILE"; }
error_exit() { echo -e "${RED}[ERRO]${NC} $1" | tee -a "$LOG_FILE"; exit 1; }

progress_bar() {
    local duration=$1
    local sleep_interval=0.1
    local progress=0
    while [ $progress -lt 100 ]; do
        echo -ne "\r${YELLOW}Progresso: [${progress}%]${NC}"
        sleep $sleep_interval
        progress=$((progress + 5))
    done
    echo -e "\r${GREEN}Progresso: [100%] Concluído!${NC}"
}

# --- 1. Verificação de Privilégios ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}ERRO: Execute o script com sudo: sudo ./instalar.sh${NC}"
   exit 1
fi

clear
echo -e "${BLUE}${BOLD}=============================================="
echo -e "      INSTALADOR AUTOMATIZADO BLISS OS"
echo -e "==============================================${NC}\n"

# --- 2. Automação de Dependências ---
log_action "Verificando dependências do sistema..."
DEPENDENCIES=("p7zip-full" "grub-pc-bin" "grub-common" "coreutils")

for dep in "${DEPENDENCIES[@]}"; do
    if ! dpkg -l | grep -q "$dep"; then
        echo -e "${YELLOW}Instalando dependência ausente: $dep...${NC}"
        apt-get update -qq && apt-get install -y "$dep" -qq > /dev/null || error_exit "Falha ao instalar $dep."
        success "$dep instalado."
    else
        success "$dep já está presente."
    fi
done

# --- 3. Localização Inteligente da ISO ---
log_action "Procurando por $ISO_NAME em $DOWNLOADS_DIR..."
if [ ! -f "$DOWNLOADS_DIR/$ISO_NAME" ]; then
    error_exit "Arquivo $ISO_NAME não encontrado. Coloque a ISO em: $DOWNLOADS_DIR"
fi
success "ISO detectada: $DOWNLOADS_DIR/$ISO_NAME"

# --- 4. Preparação da Raiz e Extração ---
log_action "Criando estrutura em $TARGET_DIR..."
mkdir -p "$TARGET_DIR/data" || error_exit "Não foi possível criar a pasta na raiz."

log_action "Extraindo arquivos essenciais da ISO..."
# Lista de arquivos vitais
FILES=("kernel" "initrd.img" "ramdisk.img")

for f in "${FILES[@]}"; do
    7z e "$DOWNLOADS_DIR/$ISO_NAME" "$f" -o"$TARGET_DIR" -y > /dev/null || error_exit "Falha ao extrair $f."
done

# Caso especial para o system (pode ser .sfs ou .img)
log_action "Extraindo imagem do sistema..."
if 7z l "$DOWNLOADS_DIR/$ISO_NAME" | grep -q "system.sfs"; then
    7z e "$DOWNLOADS_DIR/$ISO_NAME" "system.sfs" -o"$TARGET_DIR" -y > /dev/null
else
    7z e "$DOWNLOADS_DIR/$ISO_NAME" "system.img" -o"$TARGET_DIR" -y > /dev/null || error_exit "Não encontrei system.sfs ou system.img na ISO."
fi
progress_bar 2
success "Arquivos movidos para $TARGET_DIR."

# --- 5. Configuração Automática do Boot (GRUB) ---
log_action "Identificando sistema e configurando Dual Boot..."

GRUB_FILE="/etc/grub.d/40_custom"
if grep -q "menuentry 'Bliss OS'" "$GRUB_FILE"; then
    log_action "Entrada do Bliss OS já existe no GRUB. Atualizando..."
    sed -i '/menuentry "Bliss OS"/,/}/d' "$GRUB_FILE"
fi

cat <<EOF >> "$GRUB_FILE"
menuentry 'Bliss OS (Android-x86)' --class android-x86 {
    search --set=root --file /blissos/kernel
    linux /blissos/kernel root=/dev/ram0 androidboot.selinux=permissive buildvariant=userdebug SRC=/blissos
    initrd /blissos/initrd.img
}
EOF

log_action "Atualizando o GRUB..."
update-grub > /dev/null 2>&1 || grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1
success "Inicialização configurada com sucesso."

# --- 6. Checkup Final ---
echo -e "\n${BLUE}${BOLD}--- CHECKUP FINAL ---${NC}"
MISSING=0
[ ! -f "$TARGET_DIR/kernel" ] && { echo -e "${RED}[FALHA] Kernel ausente${NC}"; MISSING=1; }
[ ! -f "$TARGET_DIR/initrd.img" ] && { echo -e "${RED}[FALHA] Initrd ausente${NC}"; MISSING=1; }
[ ! -d "$TARGET_DIR/data" ] && { echo -e "${RED}[FALHA] Pasta DATA não encontrada${NC}"; MISSING=1; }

if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}${BOLD}TUDO PRONTO! O Bliss OS foi instalado corretamente na raiz.${NC}"
    echo -e "Logs detalhados em: $LOG_FILE"
else
    error_exit "A verificação final falhou. Verifique se a ISO não está corrompida."
fi

echo -e "\n${YELLOW}Deseja reiniciar o computador agora para entrar no Bliss OS? (s/n)${NC}"
read -r reboot_now
if [[ $reboot_now == [sS] ]]; then
    reboot
fi
