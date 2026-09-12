---
name: pdf-analysis-optimizer
description: "Protocolo optimizado de lectura, análisis de estructura, búsqueda semántica/regex y extracción quirúrgica de documentos PDF 100% local (offline) vía headless Python (pypdf/pdfplumber/pymupdf) a 0 tokens de contexto."
mainAgent: true
subagent: true
commandExecutionPolicy: auto
tools:
  - run_command
  - view_file
  - write_to_file
  - replace_file_content
  - multi_replace_file_content
  - grep_search
---

# 📄 PDF Analysis & Inspection Optimizer

## Cuándo usar esta skill
- El usuario proporcione o haga referencia a archivos PDF (programas de estudio, normativas, libros, dossieres, boletas, manuales, etc.).
- Se requiera buscar términos, palabras clave, números de página o capítulos dentro de PDFs voluminosos (> 5 páginas).
- Se necesite extraer la tabla de contenidos (TOC / Bookmarks), resumen de unidades o metadatos de un PDF.
- Se deban dividir, fusionar, recortar páginas o auditar el contenido de documentos PDF sin consumir cuota de tokens en el modelo.

## ⛔ REGLA DE ORO INMUTABLE (Anti-Desperdicio de Tokens)
**PROHIBICIÓN ESTRICTA:** NUNCA uses la herramienta `view_file` directamente sobre archivos PDF de más de 2 páginas o libros pesados.
- **Motivo:** Cargar PDFs completos al contexto del LLM inyecta decenas o cientos de miles de tokens (~50k-150k por documento), saturando la ventana de contexto y ralentizando la sesión.
- **Solución:** Todo análisis, búsqueda e inspección de PDFs DEBE realizarse de forma **Headless y local** en la terminal mediante scripts ligeros de Python (`pypdf`, `pdfplumber`, `fitz`/`pymupdf` o `pdftotext`). Solo se devuelve al chat el fragmento exacto o la conclusión requerida.

---

## 🛠️ Protocolo de Ejecución Paso a Paso

### 1. Chequeo Pre-Vuelo y Metadatos (0 Tokens)
Inspecciona rápidamente el número total de páginas, metadatos y si el PDF contiene texto digital nativo o imágenes escaneadas:

```python
import pypdf

def inspect_pdf_metadata(pdf_path):
    reader = pypdf.PdfReader(pdf_path)
    total_pages = len(reader.pages)
    first_page_text = reader.pages[0].extract_text() if total_pages > 0 else ""
    is_scanned = len(first_page_text.strip()) == 0
    
    print(f"Total Páginas: {total_pages}")
    print(f"Tipo: {'Escaneado (requiere OCR)' if is_scanned else 'Texto Digital Nativo'}")
    return total_pages, is_scanned
```

---

### 2. Búsqueda Determinista de Palabras Clave / Temas (PDF Grep de Alta Velocidad)
En lugar de leer todo el documento, busca ocurrencias exactas o expresiones regulares en milisegundos usando el motor C++ de PyMuPDF (o `pypdf` como alternativa):

```python
import pymupdf  # C++ Engine (Recomendado para PDFs masivos)
import re

def search_in_pdf_fast(pdf_path, query_term, max_matches=15):
    """Escaneo ultrarrápido con motor C++ (20k páginas en segundos)."""
    doc = pymupdf.open(pdf_path)
    matches = []
    pattern = re.compile(rf"{re.escape(query_term)}", re.IGNORECASE)
    
    for page_num, page in enumerate(doc):
        text = page.get_text()
        if pattern.search(text):
            for line in text.splitlines():
                if pattern.search(line):
                    matches.append({"page": page_num + 1, "snippet": line.strip()})
                    if len(matches) >= max_matches:
                        break
        if len(matches) >= max_matches:
            break
            
    doc.close()
    return matches
```

---

### 3. Extracción de Tabla de Contenidos / Bookmarks (TOC)
Extrae el árbol de temas, títulos y números de página sin procesar el cuerpo del texto:

```python
import pypdf

def extract_pdf_toc(pdf_path):
    reader = pypdf.PdfReader(pdf_path)
    outlines = reader.outline
    toc = []
    
    def parse_outline(outline_list):
        for item in outline_list:
            if isinstance(item, list):
                parse_outline(item)
            elif hasattr(item, 'title'):
                try:
                    page_num = reader.get_destination_page_number(item) + 1
                    toc.append({"title": item.title, "page": page_num})
                except Exception:
                    toc.append({"title": item.title, "page": "N/A"})
                    
    if outlines:
        parse_outline(outlines)
    return toc
```

---

### 4. Extracción Quirúrgica de Rango de Páginas
Cuando el usuario solicite analizar una sección específica (ej. "Léete la Unidad 3 entre las páginas 45 y 52"):

```python
import pypdf

def extract_page_range(pdf_path, start_page, end_page):
    reader = pypdf.PdfReader(pdf_path)
    extracted = []
    
    start_idx = max(0, start_page - 1)
    end_idx = min(len(reader.pages), end_page)
    
    for i in range(start_idx, end_idx):
        t = reader.pages[i].extract_text() or ""
        extracted.append(f"--- PÁGINA {i+1} ---\n" + t.strip())
        
    return "\n\n".join(extracted)
```

---

### 5. Particionado / División de PDFs Masivos
Si se necesita guardar una sección o capítulo como un PDF independiente:

```python
import pypdf

def split_pdf(input_pdf, output_pdf, start_page, end_page):
    reader = pypdf.PdfReader(input_pdf)
    writer = pypdf.PdfWriter()
    
    for i in range(start_page - 1, min(end_page, len(reader.pages))):
        writer.add_page(reader.pages[i])
        
    with open(output_pdf, "wb") as f:
        writer.write(f)
    print(f"PDF dividido generado: {output_pdf}")
```

---

### 6. Sanitización e Integridad de Texto para Tablas Markdown (Anti-Broken Rows)
Al extraer texto desde PDFs con maquetación en columnas para construir tablas en Markdown (ej. listados de indicadores, competencias, glosarios), **NUNCA** inyectes cadenas con saltos de línea crudos dentro de las celdas, ya que rompen la sintaxis de la tabla (`| celda |`) y desplazan los textos a columnas incorrectas.

Aplica siempre la función de sanitización determinista:

```python
import re

def clean_table_cell(text):
    """
    Sanitiza y normaliza texto extraído de PDFs para garantizar
    tablas Markdown 100% íntegras y sin filas rotas.
    """
    if not text:
        return ""
    # 1. Unificar palabras partidas por guion y salto de línea ("litera -\nria" -> "literaria")
    text = re.sub(r'(\w+)\s*-\s*\n\s*(\w+)', r'\1\2', text)
    # 2. Convertir todos los saltos de línea y espacios múltiples en un único espacio
    text = re.sub(r'\s+', ' ', text)
    # 3. Escapar barras verticales para no romper las columnas de Markdown
    text = text.replace('|', r'\|')
    return text.strip()
```

#### Reglas de Integridad para Tablas en Markdown:
- **Fila Única por Registro:** Toda celda de una tabla Markdown (`| celda |`) DEBE ser una cadena en una sola línea sin caracteres `\n`.
- **Limpieza de Cabeceras de Página:** Filtrar encabezados residuales del PDF (ej. números de página, "Competencia de unidad") antes de cerrar la celda.
- **Puntuación Determinista:** Garantizar que los indicadores de logro finalicen limpiamente en punto (`.`) sin viñetas (`▪`, `•`) huérfanas de columnas adyacentes.

---

### 7. Extracción y Segmentación de Flujo Continuo en Documentos Masivos / Multilibro
Cuando se procesen documentos estructurados con transiciones dinámicas entre secciones o libros que comparten páginas (ej. un capítulo termina y otro inicia en la misma página):

```python
import pymupdf

def extract_continuous_stream(pdf_path):
    doc = pymupdf.open(pdf_path)
    full_text = ""
    for page in doc:
        full_text += page.get_text() + "\n"
    doc.close()
    return full_text
```
* **Máquina de Estados:** Procesar las líneas secuencialmente detectando encabezados principales (TOC / Títulos en mayúsculas) y numeración jerárquica para evitar pérdida de registros en saltos de página.

---

### 8. Protocolo de Extracción Continua Anti-Página Partida y Fidelidad Textual
Al extraer reactivos pedagógicos, ejercicios, opciones o evaluaciones curriculares de un PDF:
1. **Tratamiento de Saltos de Página (Anti-Página Partida):**
   - Si un reactivo inicia al pie de la página $N$ (ej. viñeta o imagen inicial) y sus opciones/ilustraciones continúan en la cabecera de la página $N+1$, NUNCA proceses las páginas de forma aislada.
   - El parser DEBE ensamblar el bloque contiguo cruzando la frontera de página para no omitir activos huérfanos.
2. **Prevalencia del Conteo Real sobre Erratas de Enunciado:**
   - Si la redacción indica *"ordena del 1 al 3"* pero el documento contiene 4 viñetas o 4 imágenes, el parser DEBE capturar las **4 entidades reales**, evitando truncar datos por erratas de redacción previas.
3. **Principio de Fidelidad Textual Estricta (Cero Paráfrasis):**
   - Prohibido resumir, aproximar o redactar de memoria enunciados, opciones o textos de lectura. La extracción debe ser 100% literal palabra por palabra.
4. **Anti-Página Partida en Claves de Respuesta (Extracción Multilínea):**
   - Cuando las opciones del reactivo queden al pie de la página $N$ y la cabecera `Respuesta correcta:` o su valor pasen a la cabecera de la página $N+1$, el parser DEBE fusionar el bloque cruzando la frontera de página antes de extraer la clave, asegurando que la letra o valor no se pierda ni se asigne por defecto (A).
5. **Fusión Pedagógica de Instrucción y Pregunta en Campos de Enunciado Único:**
   - Cuando el documento curricular desglosa `Instrucción para el estudiante:` y `Pregunta:`, y la plataforma destino (ej. e-school) solo admita un campo único de texto (`#question-multiple`, `#question-open`, `#question-fv`), es OBLIGATORIO fusionar ambos elementos con la estructura:
     ```text
     Instrucción: [texto de la instrucción]

     Pregunta: [texto de la pregunta]
     ```
   - Queda estrictamente prohibido omitir la instrucción orientadora del alumno o descartar la interrogante.

---

### 9. Protocolo de Auditoría Previa de Coherencia Pedagógica y Activos (Pre-Flight Coherence Check)
Al analizar documentos PDF para estructurar, digitalizar o generar reactivos de examen, el agente DEBE ejecutar localmente un escaneo de coherencia y **REPORTAR obligatoriamente al usuario en el chat cualquier discrepancia antes de escribir código o inyectar datos**:
1. **Incongruencia Cuantitativa de Enunciados vs. Activos:**
   - Si la indicación dice *"ordena del 1 al 3"* pero el documento contiene 4 imágenes o 4 textos, se debe reportar la discrepancia y asumir el conteo real de activos gráficos (4 ítems).
2. **Incongruencia en Subpreguntas Declaradas:**
   - Si la instrucción indica *"responde las dos preguntas derivadas"* pero el bloque lista 3 o 1 derivada, reportar el conteo exacto detectado.
3. **Incongruencia en Claves y Opciones:**
   - Detectar si una pregunta de opción múltiple tiene menos de 3 opciones, carece de clave de respuesta correcta o la clave no coincide con ninguna de las letras disponibles.
4. **Fidelidad Textual Estricta al 100%:**
   - Prohibición absoluta de alterar palabras, simplificar enunciados o inventar distractores. Todo texto debe ser extraído programáticamente de forma 100% idéntica al original.
5. **Aislamiento Hermético de Banco Curricular (Anti-Caché Residual):**
   - Garantizar que todo reactivo provenga exclusivamente del PDF de la materia e institución activa. Queda estrictamente prohibido filtrar o reutilizar contenidos de proyectos anteriores (ej. literatura en ciencias o matemáticas).
6. **Validación Determinista de Claves sin Fallback Silencioso (Fail-Fast):**
   - Si un reactivo de opción múltiple o F/V en PDF no localiza su clave en el buffer multilínea, el parser debe marcar el reactivo como `UNRESOLVED_KEY` y lanzar un error bloqueante, prohibiendo la asignación automática o por defecto de la primera opción.

---

### 10. Protocolo "Distill-to-Skill": Destilación de Libros, Currículos MINED y Dossiers GADEX en Skills Modulares (Ahorro 24×–51× en Tokens)
Cuando un documento PDF extenso (> 50 páginas) deba consultarse de forma recurrente en múltiples tareas (ej. los Programas de Estudio oficial para evaluaciones **ELAC 2026** o los Dossiers de 15 submódulos de la **Maestría en IA - GADEX**), **NUNCA** re-leas el PDF completo en cada turno. Aplica la estrategia de *Progressive Disclosure* (Carga Progresiva bajo Demanda) para eliminar el **Discovery Loop Tax**:

#### A. Arquitectura Canónica de la Skill Generada:
Genera la estructura en `~/.gemini/config/skills/<slug-del-documento>/`:
- `SKILL.md` (~4,000 tokens): Modelos mentales, mapa de navegación temático y reglas de activación.
- `cheatsheet.md` (~1,000 tokens): Tablas de decisión rápida, indicadores de logro prioritarios, rúbricas o fórmulas.
- `glossary.md` (~1,500 tokens): Glosario alfabético de términos técnicos con referencias a capítulos.
- `chapters/` (~1,000 tokens cada archivo): Micro-archivos markdown segmentados por unidad, capítulo o submódulo (`ch01_*.md`, `ch02_*.md`).

#### B. Script Headless de Extracción Determinista en Python (0 Tokens de API):
Crea y ejecuta un script en `scratch/distill_pdf_to_skill.py`:
```python
import os, sys, re, json
import pymupdf

def distill_pdf_to_skill(pdf_path, output_skill_dir, skill_name, skill_desc):
    os.makedirs(f"{output_skill_dir}/chapters", exist_ok=True)
    doc = pymupdf.open(pdf_path)
    toc = doc.get_toc()  # [[lvl, title, page], ...]
    
    chapters_meta = []
    if toc:
        for i, item in enumerate(toc):
            lvl, title, start_p = item
            end_p = toc[i+1][2] - 1 if i + 1 < len(toc) else len(doc)
            slug = re.sub(r'[^a-zA-Z0-9_]', '_', title.lower()).strip('_')[:40]
            filename = f"ch{i+1:02d}_{slug}.md"
            
            # Extraer texto del rango de páginas a 0 tokens
            ch_text = ""
            for p_num in range(start_p - 1, min(end_p, len(doc))):
                ch_text += doc[p_num].get_text() + "\n"
                
            with open(f"{output_skill_dir}/chapters/{filename}", "w", encoding="utf-8") as f:
                f.write(f"# {title}\n\n" + ch_text.strip())
                
            chapters_meta.append({"chapter": i + 1, "title": title, "file": f"chapters/{filename}", "pages": f"{start_p}-{end_p}"})
    
    # Crear SKILL.md con frontmatter compatible con Antigravity Custom Agents 2.0
    skill_md_content = f"""---
name: {skill_name}
description: "{skill_desc}"
subagent: true
tools:
  - view_file
  - grep_search
---

# {skill_name.upper()} Knowledge Base

## Índice de Capítulos (Carga Progresiva Bajo Demanda)
"""
    for ch in chapters_meta:
        skill_md_content += f"- **Capítulo {ch['chapter']}:** {ch['title']} -> `{ch['file']}` (Págs. {ch['pages']})\n"
        
    with open(f"{output_skill_dir}/SKILL.md", "w", encoding="utf-8") as f:
        f.write(skill_md_content)
        
    doc.close()
    print(f"✅ Skill destilada con éxito en: {output_skill_dir}")
```

#### C. Casos de Aplicación Deterministas:
1. **Exámenes ELAC 2026 (Currículo MINED):**
   - Permite al generador de exámenes consultar exclusivamente `chapters/grado9_unidad3.md` para obtener el indicador de logro en 1,000 tokens en vez de abrir el PDF de 250 páginas.
2. **Dossiers de Maestría en IA (GADEX):**
   - Al redactar foros con `copywriter-foros` o validar casos prácticos, el agente solo carga el micro-archivo del submódulo requerido (`ch05_dria.md`), consumiendo < 1,500 tokens.

---

## ⚡ Guía de Motores y Herramientas Recomendadas
- 🚀 **PyMuPDF (`pymupdf`):** **Motor Primario de Alto Rendimiento (C++ MuPDF).** Indispensable para documentos voluminosos o masivos (> 50 páginas, hasta 20,000+ páginas), escaneo ultrarrápido con regex (20k páginas en < 45s), extracción de bloques con coordenadas y renderizado de páginas a imágenes PNG para OCR.
- 🪶 **`pypdf`:** Motor liviano secundario 100% Python puro para operaciones rápidas, metadatos e inspección sin dependencias binarias.
- 📊 **`pdfplumber`:** Especializado en extracción visual de tablas complejas con bordes y líneas.
- ⚡ **`pdftotext` (poppler):** Para conversiones instantáneas completas por consola a texto plano (`pdftotext input.pdf output.txt`).
- 👁️ **`pytesseract` / `ocrmypdf`:** Solo para PDFs escaneados que no posean capa de texto digital.


