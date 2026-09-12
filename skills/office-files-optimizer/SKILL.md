---
name: office-files-optimizer
description: "Protocolo optimizado de lectura, análisis de hojas de cálculo, documentos y presentaciones (Excel, Word, PowerPoint, CSV) 100% local (offline) vía headless Python (pandas, openpyxl, python-docx, python-pptx) a 0 tokens de contexto."
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

# 📊 Office Files & Documents Optimizer (Excel, Word, PowerPoint, CSV)

## Cuándo usar esta skill
- El usuario proporcione o haga referencia a archivos ofimáticos locales:
  - **Hojas de cálculo:** `.xlsx`, `.xls`, `.csv`, `.tsv`, `.ods` (listas de estudiantes, conciliaciones de pago, nóminas, notas, inventarios).
  - **Documentos de texto:** `.docx`, `.doc`, `.rtf` (planificaciones curriculares, normativas, contratos, guías pedagógicas).
  - **Presentaciones:** `.pptx`, `.ppt` (diapositivas de capacitación docente, talleres, ponencias).
- Se requiera buscar registros específicos (ej. un alumno por NIE, un código de pago NPE, un tema) dentro de archivos de miles de filas sin volcarlos al chat.
- Se necesite extraer resúmenes estadísticos, esquemas de diapositivas o tablas estructuradas a 0 tokens externos.

## ⛔ REGLA DE ORO INMUTABLE (Anti-Desperdicio de Tokens & Anti-Error 400)
**PROHIBICIÓN ESTRICTA:** NUNCA ejecutes la herramienta `view_file` directamente sobre archivos binarios de Office (`.xlsx`, `.xls`, `.docx`, `.pptx`).
- **Motivo:** Inyectar bytes binarios o XML comprimido corrompe el contexto de la conversación, provoca errores `400 Bad Request (INVALID_ARGUMENT)` en la API del LLM o quema cientos de miles de tokens innecesariamente en tablas masivas.
- **Solución:** Todo procesamiento, filtrado, extracción de texto y cálculo DEBE realizarse de forma **Headless y local** mediante scripts ligeros de Python (`pandas`, `openpyxl`, `python-docx`, `python-pptx`). Al chat solo se devuelve la fila, métrica o párrafo exacto requerido.

---

## 🛠️ Protocolo de Ejecución Paso a Paso

### 1. Hojas de Cálculo (Excel & CSV) vía `pandas` / `openpyxl`

#### A. Chequeo Pre-Vuelo: Nombres de Hojas y Dimensiones (0 Tokens)
Inspecciona cuántas hojas tiene el libro y cuántas filas/columnas posee antes de leer datos:
```python
import openpyxl

def inspect_excel_structure(file_path):
    wb = openpyxl.load_workbook(file_path, read_only=True)
    sheets = wb.sheetnames
    print(f"Hojas disponibles: {sheets}")
    wb.close()
```

#### B. Consulta Quirúrgica y Filtrado sin Cargar Todo el Dataset
Busca solo los registros que cumplan con una condición (ej. buscar alumno o filtrar por grado):
```python
import pandas as pd

def search_excel_records(file_path, sheet_name=0, column_name=None, search_value=None):
    df = pd.read_excel(file_path, sheet_name=sheet_name)
    
    if column_name and search_value:
        # Búsqueda insensible a mayúsculas/minúsculas
        filtered = df[df[column_name].astype(str).str.contains(str(search_value), case=False, na=False)]
    else:
        filtered = df.head(5) # Muestra representativa si no hay filtro
        
    print(f"Total filas encontradas: {len(filtered)}")
    print(filtered.to_markdown(index=False))
```

#### C. Métricas y Resúmenes Estadísticos Agregados
Calcula totales, conteos por categoría o sumatorias en local:
```python
import pandas as pd

def summarize_excel(file_path, sheet_name=0, group_by_col=None, agg_col=None):
    df = pd.read_excel(file_path, sheet_name=sheet_name)
    print(f"Dimensiones: {df.shape[0]} filas × {df.shape[1]} columnas")
    print(f"Columnas: {list(df.columns)}")
    
    if group_by_col and agg_col:
        summary = df.groupby(group_by_col)[agg_col].agg(['count', 'sum', 'mean'])
        print(summary.to_markdown())
```

---

### 2. Documentos de Texto (Word `.docx`) vía `python-docx`

#### A. Extracción Estructurada por Encabezados y Secciones
Lee la jerarquía de títulos (Título, H1, H2) sin el texto intermedio para conocer el índice:
```python
import docx

def extract_docx_outline(file_path):
    doc = docx.Document(file_path)
    outline = []
    
    for p in doc.paragraphs:
        if p.style.name.startswith('Heading') or p.style.name in ['Title', 'Subtitle']:
            outline.append(f"{p.style.name}: {p.text.strip()}")
            
    print("\n".join(outline))
```

#### B. Búsqueda y Extracción Quirúrgica de Párrafos / Cláusulas
Extrae únicamente la sección o párrafo que contiene un término clave:
```python
import docx

def search_in_docx(file_path, query_term):
    doc = docx.Document(file_path)
    matches = []
    
    for i, p in enumerate(doc.paragraphs):
        if query_term.lower() in p.text.lower() and len(p.text.strip()) > 0:
            matches.append(f"[Párrafo {i+1}]: {p.text.strip()}")
            
    print(f"Coincidencias ({len(matches)}):")
    print("\n\n".join(matches[:10]))
```

#### C. Extracción Limpia de Tablas a Formato Markdown
Convierte tablas internas de Word a Markdown sin perder alineación:
```python
import docx

def extract_docx_tables(file_path):
    doc = docx.Document(file_path)
    for idx, table in enumerate(doc.tables):
        print(f"\n--- Tabla {idx+1} ---")
        rows_data = []
        for row in table.rows:
            rows_data.append([cell.text.strip().replace('\n', ' ') for cell in row.cells])
        if rows_data:
            headers = rows_data[0]
            body = rows_data[1:]
            print("| " + " | ".join(headers) + " |")
            print("| " + " | ".join(["---"] * len(headers)) + " |")
            for r in body:
                print("| " + " | ".join(r) + " |")
```

#### D. Detección Exhaustiva de Colores, Resaltados y Sombreados (0 Tokens)
Cuando un documento contenga filas o nombres marcados por color (ej. alumnos que ya pagaron, cláusulas observadas), inspecciona los 3 niveles posibles de formato en Word (`highlight`, `run shading` y `paragraph shading`):

```python
import docx
from docx.oxml.ns import qn

def extract_docx_colored_entries(file_path):
    doc = docx.Document(file_path)
    colored_items = []
    
    for i, p in enumerate(doc.paragraphs):
        text = p.text.strip()
        if not text:
            continue
        
        detected_colors = []
        
        # 1. Sombreado a nivel de párrafo completo
        ppr = p._p.find(qn('w:pPr'))
        if ppr is not None:
            shd = ppr.find(qn('w:shd'))
            if shd is not None:
                fill = shd.get(qn('w:fill'))
                if fill and fill.lower() not in ['auto', 'none', 'ffffff']:
                    detected_colors.append(f"para-shd:{fill}")
                    
        # 2. Resaltado y sombreado a nivel de run (texto)
        for run in p.runs:
            rpr = run._r.find(qn('w:rPr'))
            if rpr is not None:
                hl = rpr.find(qn('w:highlight'))
                if hl is not None:
                    detected_colors.append(f"highlight:{hl.get(qn('w:val'))}")
                shd = rpr.find(qn('w:shd'))
                if shd is not None:
                    fill = shd.get(qn('w:fill'))
                    if fill and fill.lower() not in ['auto', 'none', 'ffffff']:
                        detected_colors.append(f"run-shd:{fill}")
                        
        if detected_colors:
            colored_items.append({"index": i+1, "text": text, "colors": list(set(detected_colors))})
            
    print(f"Total elementos con color detectados: {len(colored_items)}")
    for item in colored_items:
        print(f"  🎨 [Párrafo {item['index']}] {item['text']} -> {item['colors']}")
```

---

### 3. Presentaciones (PowerPoint `.pptx`) vía `python-pptx`


#### A. Esquema General de Diapositivas y Títulos
Genera el índice de la presentación con el título de cada slide:
```python
from pptx import Presentation

def extract_pptx_summary(file_path):
    prs = Presentation(file_path)
    print(f"Total diapositivas: {len(prs.slides)}")
    
    for idx, slide in enumerate(prs.slides):
        title = slide.shapes.title.text.strip() if slide.shapes.title else "Sin Título"
        print(f"Diapositiva {idx+1}: {title}")
```

#### B. Extracción Completa de Texto y Notas del Orador (Speaker Notes)
Extrae el contenido de una diapositiva específica o de toda la presentación:
```python
from pptx import Presentation

def extract_slide_content(file_path, slide_number=None):
    prs = Presentation(file_path)
    
    for idx, slide in enumerate(prs.slides):
        if slide_number and (idx + 1) != slide_number:
            continue
            
        print(f"\n==========================================")
        print(f"DIAPOSITIVA {idx+1}")
        print(f"==========================================")
        
        # Texto de formas
        for shape in slide.shapes:
            if shape.has_text_frame:
                for paragraph in shape.text_frame.paragraphs:
                    t = paragraph.text.strip()
                    if t:
                        print(f"- {t}")
                        
        # Notas del orador
        if slide.has_notes_slide and slide.notes_slide.notes_text_frame:
            notes = slide.notes_slide.notes_text_frame.text.strip()
            if notes:
                print(f"\n[Notas del Orador]:\n{notes}")
```

---

### 3. Protocolo de Detección de Incongruencias en Reactivos de Exámenes (Word & Excel)

Al extraer o estructurar reactivos curriculares a partir de documentos `.docx` o tablas de `.xlsx`:
1. **Incongruencia Cuantitativa de Enunciados vs. Activos:**
   - Si la indicación dice *"ordena del 1 al 3"* pero el documento contiene 4 imágenes o 4 textos en viñetas/filas, se debe **reportar la discrepancia en el chat** y asumir las 4 entidades reales.
2. **Incongruencia en Subpreguntas Declaradas:**
   - Si la instrucción indica *"responde las dos preguntas derivadas"* pero el bloque lista 3 o 1 derivada, reportar proactivamente el conteo exacto detectado.
3. **Incongruencia en Claves y Opciones:**
   - Detectar si una pregunta de opción múltiple tiene menos de 3 opciones, carece de clave de respuesta correcta o la clave no coincide con ninguna de las opciones disponibles.
4. **Fidelidad Textual Estricta (Cero Paráfrasis):**
   - Prohibición absoluta de alterar palabras, simplificar enunciados o inventar distractores cuando el archivo original ya provee el texto literal.
5. **Extracción Robusta Multilínea de Claves de Respuesta (Anti-Salto de Línea / Anti-Página Partida):**
   - La clave (`A-D`, `Verdadero/Falso`) frecuentemente no reside en la misma línea que la cabecera `Respuesta correcta:`, sino en la línea subsecuente o separada por saltos de párrafo/página.
   - NUNCA evalúes la clave con un regex estricto de una sola línea ni interrumpas (`break`) la búsqueda si la línea actual solo contiene la etiqueta.
   - Aplica una ventana de búsqueda de 1 a 3 líneas subsecuentes o el regex multilínea determinista:
     ```python
     # Regex determinista multilínea para claves
     m_corr = re.search(r'respuesta\s+correcta[:\s]*\n*([A-D])\b', raw_block, re.IGNORECASE)
     ```
6. **Fusión Pedagógica de Instrucción y Pregunta en Campos de Enunciado Único:**
   - Cuando el reactivo contenga `Instrucción para el estudiante:` y `Pregunta:` de forma separada, y la plataforma destino (ej. e-school) solo admita un campo único de texto (`#question-multiple`, `#question-open`, `#question-fv`), es OBLIGATORIO fusionar ambos elementos con la estructura:
     ```text
     Instrucción: [texto de la instrucción]

     Pregunta: [texto de la pregunta]
     ```
   - Queda terminantemente prohibido omitir la instrucción orientadora del estudiante o descartar el cuerpo de la pregunta.
7. **Principio de Aislamiento de Archivo Maestro y Cero Fuga de Contexto (Anti-Caché Residual):**
   - El archivo `.docx` o `.xlsx` procesado define el universo cerrado de datos para esa materia, grado e institución. Prohibido extrapolar o mezclar variables, lecturas o reactivos de proyectos previos (ej. textos de *Leamos lo Nuestro* en pruebas de Ciencias o Matemáticas).
8. **Extracción Estricta sin Asunciones por Defecto (Fail-Fast en Claves):**
   - Si la búsqueda de la clave (`Respuesta correcta:`) no arroja una coincidencia exacta (`A-D`, `V/F`), el script DEBE detenerse y registrar una excepción explícita (`raise ValueError`). Prohibido asumir que la respuesta correcta es A por defecto (`corr = 1`).
9. **Cotejo Obligatorio contra el Amparo Pedagógico (`Justificación:`):**
   - Siempre que exista un documento maestro con justificaciones pedagógicas, es mandatorio ejecutar un chequeo de coherencia cruzada: validar que el texto de la justificación concuerde semánticamente con la alternativa seleccionada como correcta. Si se detecta contradicción o ambigüedad, se reporta proactivamente al usuario antes de inyectar datos a plataforma.

---

## ⚡ Ejecución sin Instalación Global (`uv run`)
Usa `uv run` para ejecutar cualquier análisis sin ensuciar el entorno global:
```bash
# Para Excel / CSV:
uv run --with pandas --with openpyxl python3 scratch/script.py

# Para Word:
uv run --with python-docx python3 scratch/script.py

# Para PowerPoint:
uv run --with python-pptx python3 scratch/script.py
```
