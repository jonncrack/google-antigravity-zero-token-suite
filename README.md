# 🚀 Antigravity Zero-Token Suite

> **Suite oficial de 8 Custom Skills y Reglas de Orquestación para Google Antigravity diseñadas para procesar archivos masivos (PDFs, Excels, Word, DOM, Audios, Videos, ZIPs y OCR) a 0 tokens de API externos mediante offloading headless local.**

[![Antigravity](https://img.shields.io/badge/Google-Antigravity_2.0-00CB3C?style=for-the-badge&logo=google&logoColor=white)](https://antigravity.google)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![Zero-Token Architecture](https://img.shields.io/badge/Token_Cost-0_API_Tokens-brightgreen?style=for-the-badge)]()

---

## 💡 ¿Por qué existe esta suite?

Cuando trabajas con agentes de IA autónomos (como Google Antigravity), el enfoque convencional para procesar archivos suele ser la **fuerza bruta**: subir PDFs de 200 páginas, hojas de cálculo de miles de filas o transcripciones completas al chat.

### 🛑 Las consecuencias del enfoque tradicional:
1. **Saturación del Contexto:** Un solo documento pesado consume entre **40,000 y 150,000 tokens** en un único turno.
2. **Atención Diluida (Lost-in-the-Middle):** El modelo se satura y empieza a olvidar o alucinar sobre las instrucciones de desarrollo principales.
3. **Costos y Bloqueos:** Agota rápidamente las cuotas de tokens y provoca errores como `HTTP 400 Bad Request` al intentar leer binarios crudos.

### ⚡ Nuestra Solución: Filosofía Zero-Token
En lugar de forzar a la IA a leer archivos masivos en la nube, **Antigravity delega el trabajo pesado a motores locales en tu propia máquina** utilizando utilidades de código abierto de alto rendimiento (C++ y Python headless). 

La IA **únicamente recibe el extracto quirúrgico, la celda buscada o el resumen estructurado final**, reduciendo el consumo de tokens entre un **90% y un 100%**.

---

## 📦 Las 8 Skills Optimizadoras Incluidas

| Skill | Icono | Motor Local Utilizado | ¿Qué resuelve a 0 Tokens de API? |
| :--- | :---: | :--- | :--- |
| [`pdf-analysis-optimizer`](skills/pdf-analysis-optimizer/SKILL.md) | 📄 | **PyMuPDF / pypdf** *(Motor C++)* | Búsqueda regex ultrarrápida en miles de páginas, extracción quirúrgica de rangos y protocolo **Distill-to-Skill** (reduce libros a micro-archivos de capítulos). |
| [`office-files-optimizer`](skills/office-files-optimizer/SKILL.md) | 📊 | **Pandas / OpenPyXL / python-docx** | Análisis, filtrado masivo de miles de filas en Excel, auditoría de celdas y reportes Word sin volcar datos crudos al contexto. |
| [`html-parser-optimizer`](skills/html-parser-optimizer/SKILL.md) | 🌐 | **BeautifulSoup4 / lxml** | Limpieza quirúrgica de DOM web y dumps HTML: elimina scripts, estilos y SVG para extraer únicamente selectores CSS o texto semántico limpio. |
| [`audio-transcription-optimizer`](skills/audio-transcription-optimizer/SKILL.md) | 🎙️ | **Faster-Whisper** *(Local)* + Fallback | Transcripción de voz a texto 100% offline y gratuita usando la CPU de tu equipo. Previene el error `HTTP 400` al bloquear la lectura binaria directa. |
| [`video-analysis-optimizer`](skills/video-analysis-optimizer/SKILL.md) | 🎬 | **FFmpeg** *(fps=1)* + Agentic Video | Extrae fotogramas clave de navegación de grabaciones de pantalla (UI/bugs) en local y purga temporales al finalizar sin subir videos pesados. |
| [`archive-inspector-optimizer`](skills/archive-inspector-optimizer/SKILL.md) | 📦 | **Zipfile / Tarfile** *(Python nativo)* | Inspecciona el árbol interno y metadatos de archivos comprimidos (`.zip`, `.rar`, `.tar.gz`) en memoria sin desempacarlos en el disco. |
| [`ocr-image-optimizer`](skills/ocr-image-optimizer/SKILL.md) | 🖼️ | **Tesseract OCR / Pillow** | Digitaliza texto, cifras y tablas desde recibos de pago, boletas bancarias o comprobantes escaneados a 0 tokens de visión. |
| [`web-background-automation`](skills/web-background-automation/SKILL.md) | 🚀 | **Playwright Headless + BeautifulSoup** | Motor universal de automatización y scraping en segundo plano: realiza tareas repetitivas, llenado de formularios y auditoría web sin consumo de tokens de UI. |

---

## 🛠️ Instalación en 1 Solo Paso

### En macOS / Linux (Terminal / Bash / Zsh):
Clona el repositorio y ejecuta el instalador automático:

```bash
git clone https://github.com/jonncrack/antigravity-zero-token-suite.git
cd antigravity-zero-token-suite
./scripts/install.sh
```

### En Windows (PowerShell):
Abre PowerShell y ejecuta:

```powershell
git clone https://github.com/jonncrack/antigravity-zero-token-suite.git
cd antigravity-zero-token-suite
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

### ¿Qué hace el instalador automáticamente?
1. Copia las 8 carpetas de skills a tu directorio global de Antigravity (`~/.gemini/config/skills/`).
2. Inyecta las **Reglas de Enrutamiento Automático** en tu archivo `~/.gemini/config/AGENTS.md`.
3. Verifica que dispongas de Python 3 y herramientas recomendadas (`uv`, `ffmpeg`, `tesseract`).

---

## 🎮 Cómo se Utiliza

¡No necesitas aprender comandos nuevos! Gracias a la regla de **Enrutamiento Automático de Archivos**, el agente activa proactivamente la skill adecuada en cuanto detecta el archivo:

* **Para analizar un PDF pesado:**  
  > *"Búscame en qué página del documento 'Manual_Servidor.pdf' se explica la configuración del cortafuegos."*  
  *(El agente invoca `pdf-analysis-optimizer` y usa PyMuPDF en local. Costo: 0 tokens de API).*

* **Para cruzar dos Excels masivos:**  
  > *"Compara los clientes de 'Ventas_Agosto.xlsx' con 'Padron_Oficial.xlsx' y dime cuáles faltan."*  
  *(El agente invoca `office-files-optimizer` con Pandas en memoria RAM).*

* **Para transcribir un audio o nota de voz:**  
  > *"Transcribe esta nota de voz 'reunion_directiva.m4a' y hazme un resumen ejecutivo."*  
  *(El agente invoca `audio-transcription-optimizer` usando Faster-Whisper local).*

* **Para automatizar una página web en segundo plano:**  
  > *"Extrae los selectores de los botones de login en este enlace y genera un script headless."*  
  *(El agente ejecuta el Pre-Flight DOM dump con `web-background-automation`).*

---

## 📊 Benchmarks de Eficiencia

| Escenario | Enfoque Tradicional (Nube) | Zero-Token Suite (Local) | Ahorro Real |
| :--- | :--- | :--- | :---: |
| **PDF de 200 páginas** | ~95,000 tokens | **0 tokens de API** *(PyMuPDF C++)* | **100%** |
| **Excel de 15,000 filas** | ~120,000 tokens *(volcado CSV)* | **0 tokens de API** *(Pandas RAM)* | **100%** |
| **Página Web / DOM Dump** | ~45,000 tokens *(HTML sucio)* | **~300 tokens** *(BeautifulSoup)* | **99.3%** |
| **Audio de 30 minutos** | ~40,000 tokens | **0 tokens de API** *(Whisper local)*| **100%** |

Para ver el análisis técnico completo y la comparativa de arquitectura, consulta [`docs/architecture.md`](docs/architecture.md).

---

## 🤝 Contribuir y Comunidad

¡Las contribuciones son bienvenidas! Si tienes una nueva técnica de optimización local o quieres mejorar algún parser:
1. Haz un Fork del repositorio.
2. Crea una rama con tu mejora: `git checkout -b feature/nueva-optimizacion`.
3. Envía un Pull Request detallando la prueba de 0 tokens.

---

## 📄 Licencia

Distribuido bajo la Licencia **MIT**. Consulta el archivo [`LICENSE`](LICENSE) para más detalles.

---

**Creado con ❤️ para la comunidad de Google Antigravity y desarrolladores de agentes de IA.**
