---
name: html-parser-optimizer
description: "Protocolo optimizado de lectura, limpieza y extracción semántica de código HTML/DOM 100% local (offline) vía BeautifulSoup/lxml a 0 tokens de basura, eliminando scripts, estilos y etiquetas superfluas."
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

# 🌐 HTML & DOM Parser Optimizer

## Cuándo usar esta skill
- El usuario proporcione un archivo `.html`, `.htm`, fragmento de código DOM, o volcado de página web (de e-school, Kitaboo, Moodle, cursos Evolve o plataformas educativas).
- Se requiera identificar **selectores CSS deterministas** (IDs, clases, atributos `name`, `data-*`) para automatizaciones de Playwright sin gastar tokens leyendo etiquetas superfluas.
- Se necesite extraer **tablas de datos, formularios o texto educativo** de una página web en formato Markdown limpio.

## ⛔ Regla de Oro (Anti-Desperdicio de Tokens)
**PROHIBICIÓN ESTRICTA:** NUNCA vuelques ni leas archivos `.html` crudos directamente en el chat sin sanitización previa.
- *Motivo:* El 85% de un documento HTML moderno son scripts (`<script>`), hojas de estilo (`<style>`), gráficos vectoriales (`<svg>`), fuentes, metadatos y comentarios que devoran miles de tokens de contexto innecesariamente.
- *Solución:* Todo archivo HTML debe procesarse de forma **Headless y local** con Python (`BeautifulSoup4` / `lxml`) para extraer únicamente la información sustancial antes de presentarla.

---

## 🛠️ Protocolo de Ejecución Paso a Paso

### 1. Limpieza y Extracción Local con Python
Crea y ejecuta un script de análisis temporal en `scratch/clean_html.py` según el objetivo del usuario:

#### A. Si el objetivo es Extracción de Selectores DOM y Formularios (para Playwright):
```python
import sys
import json
from bs4 import BeautifulSoup

def extract_dom_elements(html_path):
    with open(html_path, "r", encoding="utf-8", errors="ignore") as f:
        soup = BeautifulSoup(f, "html.parser")

    # 1. Eliminar etiquetas basura
    for tag in soup(["script", "style", "svg", "noscript", "iframe", "link", "meta"]):
        tag.decompose()

    summary = {
        "forms": [],
        "inputs": [],
        "selects": [],
        "buttons": [],
        "tables": []
    }

    # 2. Extraer formularios
    for form in soup.find_all("form"):
        summary["forms"].append({
            "id": form.get("id"),
            "action": form.get("action"),
            "method": form.get("method")
        })

    # 3. Extraer inputs relevantes
    for inp in soup.find_all(["input", "textarea"]):
        summary["inputs"].append({
            "tag": inp.name,
            "id": inp.get("id"),
            "name": inp.get("name"),
            "type": inp.get("type", "text"),
            "placeholder": inp.get("placeholder"),
            "class": ".".join(inp.get("class", []))
        })

    # 4. Extraer selects y sus opciones
    for sel in soup.find_all("select"):
        options = [opt.get("value", "") + ": " + opt.get_text(strip=True) for opt in sel.find_all("option")[:10]]
        summary["selects"].append({
            "id": sel.get("id"),
            "name": sel.get("name"),
            "class": ".".join(sel.get("class", [])),
            "sample_options": options
        })

    # 5. Extraer botones interactivos
    for btn in soup.find_all(["button", "a"]):
        text = btn.get_text(strip=True)
        if text or btn.get("id") or btn.get("class"):
            summary["buttons"].append({
                "tag": btn.name,
                "id": btn.get("id"),
                "class": ".".join(btn.get("class", [])),
                "text": text[:50],
                "onclick": btn.get("onclick")
            })

    return summary

if __name__ == "__main__":
    if len(sys.argv) > 1:
        res = extract_dom_elements(sys.argv[1])
        print(json.dumps(res, ensure_ascii=False, indent=2))
```

#### B. Si el objetivo es Extracción de Contenido Textual / Cursos Educativos (Markdown):
```python
import sys
from bs4 import BeautifulSoup
import html2text

def html_to_clean_markdown(html_path):
    with open(html_path, "r", encoding="utf-8", errors="ignore") as f:
        soup = BeautifulSoup(f, "html.parser")

    for tag in soup(["script", "style", "svg", "noscript", "nav", "footer", "header"]):
        tag.decompose()

    h = html2text.HTML2Text()
    h.ignore_links = False
    h.ignore_images = True
    h.body_width = 0
    return h.handle(str(soup))
```

### 2. Ejecución Headless
Ejecuta el script mediante terminal y guarda el resultado limpio en `scratch/`:
```bash
python3 scratch/clean_html.py "ruta/al/archivo.html" > scratch/dom_clean_summary.json
```

Lee únicamente el archivo limpio resultante `scratch/dom_clean_summary.json` usando `view_file` para construir tu respuesta.

---

### 3. Formato de Entrega al Usuario
- Entrega un informe conciso con:
  1. **Resumen de la Estructura:** Qué tipo de vista o formulario es.
  2. **Selectores Listos para Playwright:** Código listo con los selectores exactos encontrados (ej. `page.locator('#btn-guardar')`).
  3. **Valores de Opciones / Tablas:** Listado limpio sin etiquetas HTML de cierre.

---

### 3. Uso como Etapa 2 del Pipeline Pre-Flight (Automatización → Parser)

Cuando el HTML proviene de un **pipeline de automatización** (generado por `page.content()` de Playwright, no copiado por el usuario), usar este flujo de integración:

```python
# scratch/parse_dom_dump.py
# Recibe el dom_snapshot.html del Pre-Flight Dump y genera dom_map.json enriquecido.
# Ejecutar con: uv run --with beautifulsoup4 python3 scratch/parse_dom_dump.py scratch/dom_login.html login

import sys, json, os
from bs4 import BeautifulSoup

def parse_pre_flight_dump(html_path: str, module_name: str = "page", output_dir: str = "scratch") -> str:
    """
    Parsea el HTML del Pre-Flight DOM Dump y genera un dom_map.json
    con selectores enriquecidos (incluyendo atributos Angular Material y AntD).
    """
    with open(html_path, "r", encoding="utf-8", errors="ignore") as f:
        soup = BeautifulSoup(f, "html.parser")

    # Eliminar etiquetas basura (elimina el ~85% de tokens innecesarios)
    for tag in soup(["script", "style", "svg", "noscript", "iframe", "link", "meta"]):
        tag.decompose()

    dom_map = {
        "source_html": html_path,
        "forms": [],
        "inputs": [],
        "selects": [],
        "buttons": [],
        "tables": [],
        "custom_elements": []  # Angular Material, AntD, data-testid, aria-label, formcontrolname
    }

    # Formularios
    for form in soup.find_all("form"):
        dom_map["forms"].append({"id": form.get("id"), "action": form.get("action"), "method": form.get("method")})

    # Inputs enriquecidos (incluye atributos Angular y AntD)
    for inp in soup.find_all(["input", "textarea"]):
        dom_map["inputs"].append({
            "tag": inp.name,
            "id": inp.get("id"),
            "name": inp.get("name"),
            "type": inp.get("type", "text"),
            "placeholder": inp.get("placeholder"),
            "formcontrolname": inp.get("formcontrolname"),       # ← Angular Reactive Forms
            "data_testid": inp.get("data-testid"),               # ← Test IDs de Playwright
            "aria_label": inp.get("aria-label"),                 # ← Accesibilidad
            "ng_model": inp.get("ng-model") or inp.get("[(ngModel)]"),  # ← AngularJS/Angular
            "class": " ".join(inp.get("class", []))
        })

    # Selects y opciones
    for sel in soup.find_all("select"):
        opts = [o.get("value", "") + ": " + o.get_text(strip=True) for o in sel.find_all("option")[:10]]
        dom_map["selects"].append({"id": sel.get("id"), "name": sel.get("name"),
            "class": " ".join(sel.get("class", [])), "sample_options": opts})

    # Botones y enlaces accionables
    for btn in soup.find_all(["button", "a"]):
        text = btn.get_text(strip=True)[:60]
        classes = " ".join(btn.get("class", []))
        if text or btn.get("id") or btn.get("data-testid") or "ant-btn" in classes or "mat-" in classes:
            dom_map["buttons"].append({
                "tag": btn.name,
                "id": btn.get("id"),
                "class": classes,
                "text": text,
                "onclick": btn.get("onclick"),
                "data_testid": btn.get("data-testid"),           # ← Kitaboo: test_*
                "aria_label": btn.get("aria-label"),
                "href": btn.get("href")
            })

    # Elementos personalizados de frameworks (Angular Material, AntD)
    custom_tags = ["mat-select", "mat-option", "mat-list-option", "mat-icon",
                   "ant-select", "nz-select", "nz-option"]
    for tag_name in custom_tags:
        for el in soup.find_all(tag_name):
            dom_map["custom_elements"].append({
                "tag": el.name,
                "id": el.get("id"),
                "class": " ".join(el.get("class", [])),
                "text": el.get_text(strip=True)[:50],
                "value": el.get("value")
            })

    # Tablas de datos
    for table in soup.find_all("table"):
        headers = [th.get_text(strip=True) for th in table.find_all("th")]
        row_count = len(table.find_all("tr")) - 1
        dom_map["tables"].append({"id": table.get("id"), "class": " ".join(table.get("class", [])),
            "headers": headers, "approx_rows": row_count})

    map_path = os.path.join(output_dir, f"dom_{module_name}_map.json")
    with open(map_path, "w", encoding="utf-8") as f:
        json.dump(dom_map, f, ensure_ascii=False, indent=2)

    print(f"✅ DOM Map generado: {map_path}")
    print(f"   📋 {len(dom_map['forms'])} forms | {len(dom_map['inputs'])} inputs | {len(dom_map['selects'])} selects | {len(dom_map['buttons'])} buttons | {len(dom_map['custom_elements'])} custom elements")
    return map_path

if __name__ == "__main__":
    html_path   = sys.argv[1] if len(sys.argv) > 1 else "scratch/dom_page.html"
    module_name = sys.argv[2] if len(sys.argv) > 2 else "page"
    parse_pre_flight_dump(html_path, module_name)
```

**Uso típico en pipeline:**
```bash
# Paso 1: Pre-Flight DOM Dump (genera dom_login.html)
uv run --with playwright python3 scratch/run_pre_flight.py

# Paso 2: Parsear con este script (genera dom_login_map.json)
uv run --with beautifulsoup4 python3 scratch/parse_dom_dump.py scratch/dom_login.html login

# Paso 3: Leer el mapa de selectores
# → Usar view_file para leer scratch/dom_login_map.json y extraer selectores
```

### 4. Limpieza Inmediata
Elimina los archivos temporales de `scratch/`:
```bash
rm -f scratch/clean_html.py scratch/dom_clean_summary.json
```

---

## 📋 Checklist antes de finalizar
- [ ] ¿Se evitó volcar código HTML crudo con scripts/estilos en el chat?
- [ ] ¿Se procesó el archivo localmente con BeautifulSoup/html2text a 0 tokens de basura?
- [ ] ¿Se entregaron los selectores o el texto estructurado en Markdown limpio?
- [ ] ¿Se eliminaron los archivos temporales generados en `scratch/`?
