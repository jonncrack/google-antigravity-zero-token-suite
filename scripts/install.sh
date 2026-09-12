#!/usr/bin/env bash
# ==============================================================================
# Antigravity Zero-Token Suite - Instalador Automático Multiplataforma (macOS / Linux)
# ==============================================================================
# Autor: Jonnathan Gálvez
# Repositorio: https://github.com/jonncrack/antigravity-zero-token-suite
# ==============================================================================

set -e

# Colores de terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}   🚀 Instalador Oficial: Antigravity Zero-Token Suite ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# 1. Definir rutas objetivo
CONFIG_DIR="$HOME/.gemini/config"
TARGET_SKILLS_DIR="$CONFIG_DIR/skills"
RULES_FILE="$CONFIG_DIR/AGENTS.md"

echo -e "${YELLOW}[1/4] Verificando entorno de Google Antigravity...${NC}"
mkdir -p "$TARGET_SKILLS_DIR"
echo -e "  ✓ Directorio de skills listo: ${TARGET_SKILLS_DIR}"

# 2. Copiar las skills optimizadoras
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SKILLS_DIR="$SCRIPT_DIR/../skills"

if [ ! -d "$SOURCE_SKILLS_DIR" ]; then
    # Fallback si se ejecuta desde la raíz del repo
    SOURCE_SKILLS_DIR="$SCRIPT_DIR/skills"
fi

echo -e "\n${YELLOW}[2/4] Instalando las 8 Skills Optimizadoras a 0 Tokens...${NC}"

SKILLS=(
    "pdf-analysis-optimizer"
    "office-files-optimizer"
    "html-parser-optimizer"
    "audio-transcription-optimizer"
    "video-analysis-optimizer"
    "archive-inspector-optimizer"
    "ocr-image-optimizer"
    "web-background-automation"
)

for skill in "${SKILLS[@]}"; do
    if [ -d "$SOURCE_SKILLS_DIR/$skill" ]; then
        cp -R "$SOURCE_SKILLS_DIR/$skill" "$TARGET_SKILLS_DIR/"
        echo -e "  ${GREEN}✓${NC} Instalada: $skill"
    else
        echo -e "  ${RED}✗${NC} No se encontró la carpeta de la skill: $skill"
    fi
done

# 3. Inyectar / fusionar reglas en AGENTS.md
echo -e "\n${YELLOW}[3/4] Configurando reglas de enrutamiento automático (AGENTS.md)...${NC}"
RULES_SOURCE="$SCRIPT_DIR/../rules/token_optimization_rules.md"
if [ ! -f "$RULES_SOURCE" ]; then
    RULES_SOURCE="$SCRIPT_DIR/rules/token_optimization_rules.md"
fi

if [ -f "$RULES_SOURCE" ]; then
    if [ ! -f "$RULES_FILE" ]; then
        touch "$RULES_FILE"
    fi
    
    if grep -q "Filosofía de Consumo de Tokens (Eficiencia Máxima)" "$RULES_FILE"; then
        echo -e "  ${BLUE}ℹ${NC} Las reglas ya están presentes en $RULES_FILE. Omitiendo duplicación."
    else
        echo "" >> "$RULES_FILE"
        cat "$RULES_SOURCE" >> "$RULES_FILE"
        echo -e "  ${GREEN}✓${NC} Reglas de enrutamiento inyectadas en $RULES_FILE"
    fi
else
    echo -e "  ${YELLOW}⚠ Archivo de reglas no encontrado en $RULES_SOURCE.${NC}"
fi

# 4. Verificar dependencias de sistema recomendadas
echo -e "\n${YELLOW}[4/4] Verificando dependencias del sistema...${NC}"

# Python
if command -v python3 &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Python 3 detectado: $(python3 --version)"
else
    echo -e "  ${RED}✗ Python 3 no detectado. Se recomienda instalar Python 3.11+.${NC}"
fi

# uv
if command -v uv &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} uv detectado (gestor ultrarrápido a 0 dependencias globales)"
else
    echo -e "  ${YELLOW}ℹ 'uv' no está instalado. Se recomienda instalarlo para ejecución sin fricción:${NC}"
    echo -e "    curl -LsSf https://astral.sh/uv/install.sh | sh"
fi

# ffmpeg
if command -v ffmpeg &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} FFmpeg detectado (para video-analysis-optimizer)"
else
    echo -e "  ${YELLOW}ℹ FFmpeg no detectado (opcional, para análisis local de videos).${NC}"
    echo -e "    macOS: brew install ffmpeg | Ubuntu/Debian: sudo apt install ffmpeg"
fi

# tesseract
if command -v tesseract &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Tesseract OCR detectado (para ocr-image-optimizer)"
else
    echo -e "  ${YELLOW}ℹ Tesseract no detectado (opcional, para OCR de recibos e imágenes escaneadas).${NC}"
    echo -e "    macOS: brew install tesseract | Ubuntu/Debian: sudo apt install tesseract-ocr"
fi

echo ""
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}  🎉 ¡Instalación Completada con Éxito!              ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "Tus agentes en Google Antigravity ahora procesarán PDFs, Excels, Word,"
echo -e "DOM, audios y archivos pesados a 0 tokens de API de forma automática."
echo ""
