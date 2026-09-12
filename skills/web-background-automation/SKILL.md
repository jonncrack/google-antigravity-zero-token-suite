---
name: web-background-automation
description: "Motor maestro de automatización web y scraping determinista en segundo plano (Headless) con Python y Playwright a 0 tokens de API, para tareas repetitivas, exploración de DOM y extracción masiva."
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

# 🌐 Web Background Automation (Playwright Headless Master Engine)

## Cuándo usar esta skill
- El usuario solicite realizar **tareas web repetitivas** (llenado masivo de formularios, subida de archivos, descarga de reportes, clics en bucle).
- Se requiera **explorar e investigar la estructura de una página web** (descubrir selectores de botones, inputs, modales, menús desplegables o tablas) sin abrir navegadores visuales que consuman recursos o tokens de visión.
- Se necesite hacer **scraping robusto o extracción de datos** en sitios dinámicos y Single Page Applications (SPA: Angular, React, Vue, Svelte, jQuery/Bootstrap) con JavaScript activo.

---

## ⛔ Las 8 Reglas de Oro de la Automatización Headless

0. **Pre-Flight DOM Dump Obligatorio (`page.content()`):**
   - Ante **cualquier URL o módulo nuevo o que haya cambiado**, el primer paso SIEMPRE es ejecutar `pre_flight_dom_dump()` para extraer el HTML completo post-JavaScript y generar un `dom_map.json` con todos los selectores reales antes de escribir una sola línea de automatización.
   - *Motivo:* Los selectores CSS/XPath asumidos sin validación son la causa raíz de fallos que obligan al usuario a compartir manualmente el HTML. `page.content()` obtiene el DOM renderizado tal como el navegador lo ve, incluyendo todo el HTML generado por JavaScript (Angular, React, Vue).
   - *Excepción única:* Si la URL ya está completamente mapeada en la skill con selectores verificados en sesiones anteriores, se puede omitir el dump y usar los selectores conocidos directamente.

1. **Modo Headless Obligatorio (`headless=True`):**
   - Toda instancia de Chromium DEBE ejecutarse de forma invisible en segundo plano (`browser = await p.chromium.launch(headless=True)`).
   - *Beneficio:* 0 tokens visuales/multimodales, máxima velocidad de ejecución y total privacidad.

2. **Exploración Previa del DOM (Descubrimiento Determinista):**
   - Antes de intentar interactuar a ciegas en bucles masivos, ejecuta un script de descubrimiento que inspeccione los elementos reales con `page.evaluate()` para extraer atributos `name`, `formcontrolname`, `data-testid`, o textos semánticos.

3. **Manejo de Overlays, Toasts y Modales Desacoplados (CDK / Portals):**
   - En frameworks modernos (Angular Material CDK, React Portals, Vue Teleport), los diálogos emergentes, toasts y menús se montan en la raíz del `<body>` (ej: `.cdk-overlay-container`, `#modal-root`, `div[role="dialog"]`).
   - Interactúa siempre buscando dentro del contenedor flotante superior activo.

4. **Evasión Estricta de IDs Duplicados e IDs Dinámicos:**
   - **IDs Duplicados (Bug común de desarrollo):** Si varios botones comparten el mismo ID, NUNCA uses `#id_duplicado`. Selecciona por texto o tooltip (`button:has-text("...")` o `[mattooltip="..."]`).
   - **IDs Dinámicos (Autogenerados):** Si un selector tiene números variables (`#mat-checkbox-1095`, `#input-42`), localiza el elemento a través de su ancestro semántico o su texto identificador (`page.locator('div.user-card', has_text='correo@dominio.com').locator('mat-checkbox')`).

5. **Inyección Directa en Inputs de Archivo Ocultos (`display: none`):**
   - NUNCA hagas clic en botones de subida que disparen `input.click()` por JavaScript (eso abre un diálogo nativo del sistema operativo que bloquea el runner headless).
   - Inyecta la ruta del archivo directamente sobre el elemento `<input type="file">` invisible usando `locator.set_input_files('/ruta/archivo')`.

6. **Guardrails de Bucles y Manejo de Errores en Lote:**
   - Toda automatización masiva en bucle (ej. 100 filas) DEBE encapsular cada iteración en un bloque `try/except` individual para que el fallo en un registro no detenga el lote completo.
   - Incluir registro de progreso en consola cada 5 o 10 elementos (`print(f"[{i}/{total}] Procesado...")`).

7. **Sincronización Determinista de Red (`wait_for_response` vs `sleep`):**
   - En lugar de pausas fijas arbitrarias (`time.sleep(3)`), intercepta las respuestas HTTP/JSON con `page.expect_response(...)` o espera cambios explícitos de estado (`locator.wait_for(state="visible")`).

8. **Principio de Modificación Quirúrgica vs. Recreación Masiva:**
   - Queda estrictamente prohibido diseñar automatizaciones que vacíen y reconstruyan entidades enteras (tablas, catálogos, listas de preguntas, formularios) ante auditorías o cambios menores.
   - Todo script de modificación debe ubicar y operar **únicamente** sobre el elemento específico por su identificador único (ID/selector) o añadir al final en modo aditivo.

9. **Auditoría Cruzada Determinista Post-Ejecución (Cross-Audit Diff Check a 0 Tokens):**
   - Al finalizar cualquier inyección masiva o actualización en lote, DEBES ejecutar un script headless que extraiga los datos renderizados en el DOM en vivo y los compare matemáticamente contra el archivo fuente (PDF/CSV/JSON).
   - Exigir una tasa de coincidencia $\ge 95\%$ para certificar la tarea como completada.

10. **Evasión de Bloqueo por Overlays (Pointer-Events Traps):**
    - Cuando diálogos de alerta (SweetAlert, toasts, modals, CDK overlay) permanezcan en el DOM o durante su animación de cierre, `locator.click()` puede fallar por intercepción de eventos de puntero.
    - Usa clics nativos vía DOM: `page.evaluate("document.querySelector('...')?.click()")` y limpia proactivamente los contenedores huérfanos (`$('.sweet-overlay, .sweet-alert, .modal-backdrop').remove()`).

---

## 🧰 Patrones Maestros Universales (Playwright Python)

### 0. Pre-Flight DOM Dump (Paso 0 Universal — Obligatorio en URLs Nuevas)
```python
import os, json
from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup

def pre_flight_dom_dump(url: str, module_name: str = "page", output_dir: str = "scratch") -> dict:
    """
    Paso 0 Universal: Navega a la URL, espera el renderizado completo de JavaScript,
    extrae el HTML post-JS y genera un dom_map.json con todos los selectores reales.
    Ejecutar SIEMPRE antes de automatizar una URL nueva o modificada.
    """
    os.makedirs(output_dir, exist_ok=True)
    html_path = os.path.join(output_dir, f"dom_{module_name}.html")
    map_path  = os.path.join(output_dir, f"dom_{module_name}_map.json")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 1440, "height": 900})
        page = context.new_page()
        # Esperar a que JS termine de renderizar (networkidle = sin peticiones de red pendientes)
        page.goto(url, wait_until="networkidle", timeout=30000)
        html = page.content()  # HTML completo post-JavaScript ← la clave del protocolo
        browser.close()

    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"📄 DOM Snapshot: {html_path} ({len(html):,} bytes)")

    # Parsear y generar mapa limpio de selectores accionables
    soup = BeautifulSoup(html, "html.parser")
    for tag in soup(["script", "style", "svg", "noscript", "link", "meta"]):
        tag.decompose()

    dom_map = {"url": url, "forms": [], "inputs": [], "selects": [], "buttons": []}

    for form in soup.find_all("form"):
        dom_map["forms"].append({"id": form.get("id"), "action": form.get("action"), "method": form.get("method")})

    for inp in soup.find_all(["input", "textarea"]):
        dom_map["inputs"].append({
            "tag": inp.name, "id": inp.get("id"), "name": inp.get("name"),
            "type": inp.get("type", "text"), "placeholder": inp.get("placeholder"),
            "formcontrolname": inp.get("formcontrolname"),
            "data_testid": inp.get("data-testid"),
            "aria_label": inp.get("aria-label"),
            "class": " ".join(inp.get("class", []))
        })

    for sel in soup.find_all("select"):
        opts = [o.get("value", "") + ": " + o.get_text(strip=True) for o in sel.find_all("option")[:10]]
        dom_map["selects"].append({"id": sel.get("id"), "name": sel.get("name"), "sample_options": opts})

    for btn in soup.find_all(["button", "a"]):
        text = btn.get_text(strip=True)[:60]
        if text or btn.get("id") or btn.get("data-testid"):
            dom_map["buttons"].append({
                "tag": btn.name, "id": btn.get("id"),
                "class": " ".join(btn.get("class", [])),
                "text": text,
                "data_testid": btn.get("data-testid"),
                "aria_label": btn.get("aria-label")
            })

    with open(map_path, "w", encoding="utf-8") as f:
        json.dump(dom_map, f, ensure_ascii=False, indent=2)
    print(f"🗺️  DOM Map guardado: {map_path} ({len(dom_map['inputs'])} inputs, {len(dom_map['buttons'])} buttons)")
    print("➡️  Leer dom_map.json con view_file para identificar los selectores correctos antes de continuar.")
    return {"html_path": html_path, "map_path": map_path}
```

### 1. Manejo de Modales y Diálogos Flotantes
```python
# Esperar que el modal en el overlay esté completamente montado y visible
modal = page.locator('.cdk-overlay-container, #modal-root, [role="dialog"]').last
await modal.wait_for(state="visible", timeout=10000)

# Interactuar dentro del modal acotando el scope
await modal.locator('input[type="checkbox"]').check()
await modal.locator('button:has-text("Confirmar"), button.btn-primary').click()
```

### 2. Selección de Elementos por Contexto (Anti-IDs Dinámicos)
```python
# Localizar una fila/tarjeta por su identificador único (email, código, nombre)
target_row = page.locator('tr, mat-grid-tile, div.card', has_text="usuario@empresa.com").first

# Hacer clic en el botón o checkbox interno de esa fila específica
await target_row.locator('button.action-btn, mat-checkbox label, input[type="checkbox"]').click()
```

### 3. Subida de Archivos Masiva / Bulk Upload
```python
# Inyección directa en input invisible (acepta .xlsx, .csv, .pdf, etc.)
file_input = page.locator('input[type="file"]')
await file_input.set_input_files('/ruta/absoluta/al/documento.xlsx')

# Esperar validación o toast de respuesta
await page.wait_for_selector('.toast-success, .alert-success, [role="alert"]', timeout=15000)
```

### 4. Auto-Scroll para Virtual Scroll / Scroll Infinito
```python
# Bucle para forzar la carga de todos los registros en listas virtuales
async def load_all_infinite_items(page, item_selector, max_scrolls=50):
    prev_count = 0
    for _ in range(max_scrolls):
        count = await page.locator(item_selector).count()
        if count == prev_count and count > 0:
            break  # No se cargaron más elementos
        prev_count = count
        # Scroll al último elemento visible
        await page.locator(item_selector).last.scroll_into_view_if_needed()
        await page.wait_for_timeout(400)
    return prev_count
```

### 5. Escucha de Eventos de Red (Guardado Determinista)
```python
# Esperar respuesta exitosa del servidor tras hacer clic en guardar
async with page.expect_response(lambda r: ("api/" in r.url or "save" in r.url) and r.status == 200, timeout=15000):
    await page.locator('button:has-text("Save"), button:has-text("Guardar")').click()
### 6. Persistencia Progresiva (Checkpoints) y Evasión WAF (Cloudflare)
En scraping de gran volumen (> 50 páginas o múltiples capítulos):
```python
# 1. Guardar progreso incremental en JSON
def save_checkpoint(data, file_path="scratch/progress.json"):
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# 2. Backoff exponencial ante pantallas de verificación ("Just a moment...")
if "Just a moment" in await page.title() or (response and response.status == 403):
    await page.wait_for_timeout(random.randint(5000, 10000))
```

---

## 🛠️ Plantilla Maestra de Automatización (Python Asíncrono + Playwright)

Guarda y ejecuta el script en `scratch/run_automation.py`:

```python
import asyncio
import json
import os
from playwright.async_api import async_playwright

async def run():
    async with async_playwright() as p:
        # 1. Navegador Headless con viewport amplio
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(viewport={"width": 1440, "height": 900})
        page = await context.new_page()

        try:
            print("🚀 [1/4] Iniciando sesión...")
            await page.goto("https://portal.ejemplo.com/login", wait_until="networkidle")

            # 2. Autenticación robusta
            await page.locator('input[name="username"], input[type="email"]').fill("admin@empresa.com")
            await page.locator('input[name="password"], input[type="password"]').fill("ClaveSegura$2026")
            await page.locator('button[type="submit"], button:has-text("Login")').click()
            await page.wait_for_load_state("networkidle")
            print("✅ Sesión autenticada.")

            # 3. Navegación y Procesamiento en Lote
            items_to_process = ["ID_001", "ID_002", "ID_003"]
            total = len(items_to_process)

            for idx, item_id in enumerate(items_to_process, 1):
                try:
                    print(f"[{idx}/{total}] Procesando: {item_id}...")
                    
                    # Búsqueda determinista
                    search_box = page.locator('input[placeholder*="Search"], input[type="search"]').first
                    await search_box.fill(item_id)
                    await page.keyboard.press("Enter")
                    await page.wait_for_timeout(300)

                    # Interacción con la fila encontrada
                    row = page.locator('tr, div.item-card', has_text=item_id).first
                    if await row.count() > 0:
                        await row.locator('button.btn-action').click()
                        
                        # Si abre modal de confirmación
                        modal = page.locator('.cdk-overlay-container, [role="dialog"]').last
                        if await modal.is_visible():
                            await modal.locator('button:has-text("Confirm"), button:has-text("Assign")').click()
                    
                    print(f"[{idx}/{total}] ✅ {item_id} completado.")

                except Exception as item_err:
                    print(f"⚠️ [{idx}/{total}] Error en {item_id}: {item_err}")
                    continue

            print("🎉 Automatización completada exitosamente.")

        except Exception as e:
            print(f"❌ Error fatal en automatización: {e}")
            os.makedirs("scratch", exist_ok=True)
            await page.screenshot(path="scratch/error_debug.png", full_page=True)
            print("📸 Captura guardada en scratch/error_debug.png")
        finally:
            await browser.close()

if __name__ == "__main__":
    asyncio.run(run())
```

---

## 🚀 Patrón de Ejecución Rápida con `uv`
Ejecuta siempre el script en la terminal mediante `uv` para garantizar dependencias aisladas a 0 fricción:

```bash
uv run --with playwright python3 scratch/run_automation.py
```

---

## 📋 Checklist Pre-Vuelo
- [ ] **¿Se ejecutó `pre_flight_dom_dump()` para la URL/módulo actual? (Obligatorio en URLs nuevas o cambiadas)**
- [ ] ¿El navegador está configurado estrictamente con `headless=True`?
- [ ] ¿Los selectores evitan IDs duplicados y usan jerarquía de texto/ancestro?
- [ ] ¿Los file inputs usan `.set_input_files()` en lugar de hacer clic en el botón?
- [ ] ¿Los modales se buscan en el overlay desacoplado (`.cdk-overlay-container` o `[role="dialog"]`)?
- [ ] ¿Cada elemento del bucle está protegido con `try/except` individual?
- [ ] ¿Se captura un pantallazo de depuración (`scratch/error_debug.png`) en caso de fallo?
