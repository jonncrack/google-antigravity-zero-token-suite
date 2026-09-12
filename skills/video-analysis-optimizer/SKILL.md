---
name: video-analysis-optimizer
description: "Protocolo optimizado de análisis de video: extracción local con FFmpeg (fps=1) a 0 tokens para UI/bugs, y motor agéntico en la nube (processing='agentic') con 88% de ahorro de tokens para videos largos y YouTube."
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

# 🎬 Video Analysis & UI Inspection Optimizer

## Cuándo usar esta skill
- El usuario proporcione un archivo de video local (`.mp4`, `.mov`, `.mkv`, `.webm`) que contenga demostraciones de errores (bugs), tutoriales o grabaciones de interfaces de usuario (UI).
- El usuario proporcione un enlace de video largo (conferencias, webinars GADEX, clases grabadas o YouTube) y solicite analizar momentos clave, extraer conclusiones o detectar anomalías.
- Se necesite extraer selectores DOM, pasos de navegación o flujos lógicos de una grabación.

## No usar esta skill cuando
- Se solicite diseñar prompts creativos para generar videos (para eso usar la skill `video-prompt-engineer`).

---

## 🛠️ Decisión de Arquitectura según Tipo y Origen del Video

Elige la ruta de ejecución óptima para garantizar el menor consumo de tokens y recursos:

### 🟢 RUTA A: Grabaciones Locales de UI y Bugs de Pantalla (< 5 minutos)
Para grabaciones de pantalla locales donde se deba inspeccionar la interfaz (botones, formularios, modales):

1. **Extracción por tiempo a 1 FPS (Optimizada para UI):**
   Evita detectores de escena (`gt(scene,0.2)`), ya que los cambios sutiles de UI no los detectan. Extrae fotogramas con FFmpeg a 1 fotograma por segundo (`fps=1`):
   ```bash
   mkdir -p scratch/video_analysis && ffmpeg -i "ruta/al/video.mp4" -vf "fps=1,scale='min(1024,iw)':-2" scratch/video_analysis/frame_%04d.png
   ```
   *(Si el video dura más de 2 minutos, reduce a `fps=0.5` para limitar la cantidad de frames).*

2. **Inspección progresiva a 0 tokens de API:**
   - Lista los fotogramas generados e inspecciona únicamente los frames representativos (inicio, transición de vista y resultado final).
   - Describe las acciones detectadas de forma breve.

3. **Limpieza inmediata:**
   ```bash
   rm -rf scratch/video_analysis
   ```

---

### ☁️ RUTA B: Videos Largos en la Nube y Enlaces de YouTube (> 15 minutos / Conferencias / GADEX)
Cuando el video provenga de una URL remota de YouTube o sea un video largo de varias horas:

1. **Cero Descargas a Disco & 88% de Ahorro de Tokens:**
   En lugar de descargar gigabytes a tu Mac o muestrear miles de frames estáticos, invoca al motor **Agentic Video** de Gemini mediante el SDK `google-genai` usando la `GEMINI_API_KEY`:

   ```python
   import os
   from google import genai

   client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

   interaction = client.interactions.create(
       model="gemini-3.7-flash",
       input=[
           {
               "type": "video",
               "uri": "https://www.youtube.com/watch?v=VIDEO_ID",
               "processing": "agentic"  # ← Bucle agéntico dinámico
           },
           {
               "type": "text",
               "text": "Analiza este video y responde: 1) Resumen cronológico, 2) Minutos exactos donde se presentan los temas clave, 3) Conclusiones principales."
           }
       ]
   )
   print(interaction.output_text)
   ```

2. El modelo buscará de forma autónoma en el stream en la nube solo los momentos relevantes, sin saturar la ventana de contexto.

---

## 📋 Formato de Reporte de Análisis Visual

Genera siempre un informe estructurado en Markdown:

```markdown
### Reporte de Análisis Visual (Video)

#### Resumen del Flujo
[Breve descripción de lo que ocurre en la grabación y su objetivo principal]

#### Cronología de Acciones
1. **[00:02]** - El usuario hace clic en el menú...
2. **[00:15]** - Aparece el SweetAlert modal...

#### Selectores y Elementos DOM Detectados
- **Botón de Envío:** `button#submit-btn`
- **Input de Correo:** `input[type="email"]`
```

---

## 📋 Checklist antes de finalizar
- [ ] Si fue un video local, ¿se usó FFmpeg (`fps=1`) y se eliminó `scratch/video_analysis`?
- [ ] Si fue un video largo / YouTube, ¿se usó el modo `processing: "agentic"` a 88% de ahorro de tokens?
- [ ] ¿Se documentaron los selectores o marcas de tiempo de forma clara?
