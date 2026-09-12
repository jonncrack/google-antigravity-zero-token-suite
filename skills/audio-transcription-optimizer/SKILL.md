---
name: audio-transcription-optimizer
description: "Protocolo optimizado de análisis de audio, metadatos y transcripción híbrida: local offline vía Whisper a 0 tokens y escalado de alta fidelidad con Gemini 3.5 Transcribe / Agentic Video, previniendo errores de carga binaria."
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

# 🎙️ Audio Transcription & Analysis Optimizer

## Cuándo usar esta skill
- El usuario proporcione un archivo o ruta de audio local (`.mp3`, `.wav`, `.m4a`, `.aac`, `.flac`, `.ogg`, `.opus`) o enlace de YouTube solicitando transcripción, extracción de letra, resumen de podcast o análisis de contenido.
- Se requiera extraer metadatos técnicos (duración, tasa de muestreo, canales, bitrate) de un archivo de sonido.
- Se necesite transcribir cantos, coros de iglesia o grabaciones en vivo donde los instrumentos o las repeticiones rítmicas dificulten la escucha.

## ⛔ REGLA DE ORO INMUTABLE (Anti-Error 400)
**PROHIBICIÓN ESTRICTA:** NUNCA ejecutes la herramienta `view_file` directamente sobre archivos binarios de audio (`.mp3`, `.wav`, `.m4a`, `.aac`, `.flac`, `.ogg`, `.opus`).
- *Motivo:* Inyectar bytes de audio crudos en el historial de la conversación corrompe el contexto y provoca un fallo irreversible de `HTTP 400 Bad Request (INVALID_ARGUMENT)` en la API de Google en los mensajes siguientes.
- *Solución:* Todo procesamiento de audio DEBE realizarse de forma **Headless y local** en la terminal mediante scripts de Python (`faster-whisper`), utilidades de línea de comandos (`ffprobe`/`ffmpeg`), o llamadas API especializadas (`google-genai`).

---

## 🛠️ Protocolo de Ejecución Paso a Paso (Motor Híbrido en 3 Niveles)

### 1. Inspección Rápida de Metadatos (FFprobe)
Antes de transcribir archivos locales, verifica su existencia y duración:
```bash
ffprobe -v error -show_entries format=duration,size,bit_rate:stream=codec_name,channels,sample_rate -of json "ruta/al/archivo.mp3"
```

---

### 2. Selección Determinista del Motor de Transcripción

Elige la ruta de ejecución según la naturaleza del audio:

#### Nivel 1: Local Offline con Faster-Whisper (0 Tokens de API — Predeterminado)
Para audios hablados estándar, clases, conferencias limpias y podcasts en local:

Crea y ejecuta un script ligero en `scratch/transcribe_audio.py`:
```python
import sys
import json
from faster_whisper import WhisperModel

def transcribe(audio_path, model_size="base"):
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    segments, info = model.transcribe(audio_path, beam_size=5, language=None)
    
    results = {
        "language": info.language,
        "duration": info.duration,
        "segments": [{"start": round(s.start, 2), "end": round(s.end, 2), "text": s.text.strip()} for s in segments]
    }
    return results

if __name__ == "__main__":
    if len(sys.argv) > 1:
        print(json.dumps(transcribe(sys.argv[1]), ensure_ascii=False, indent=2))
```

Ejecuta mediante `uv`:
```bash
source $HOME/.local/bin/env 2>/dev/null; uv run --with faster-whisper python3 scratch/transcribe_audio.py "ruta/al/audio.mp3" > scratch/transcript_result.json
```

#### Nivel 2: Gemini 3.5 Transcribe (Alta Fidelidad / Coros, Música en Vivo y Alabanzas)
Cuando el audio tenga **música de fondo fuerte (batería, bajo), notas de voz cantadas de celular o coros con repeticiones rítmicas continuas** donde Whisper suele entrar en bucles ("Alabaré..."):

Invoca a `gemini-3.5-transcribe` vía `google-genai` usando la `GEMINI_API_KEY`:
```python
import os, sys
from google import genai

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
audio_file = client.files.upload(file="ruta/al/audio.mp3")

response = client.interactions.create(
    model="gemini-3.5-transcribe",
    input=[
        {"type": "audio", "uri": audio_file.uri},
        {"type": "text", "text": "Transcribe la letra completa con estrofas separadas y mayúsculas reverenciales."}
    ]
)
print(response.output_text)
```

#### Nivel 3: Agentic Video Stream en YouTube (Cero Descargas a Disco)
Cuando se trate de un **enlace de YouTube sin subtítulos nativos**, ejecuta el script maestro del proyecto:
```bash
uv run --with youtube-transcript-api --with google-genai python3 scripts/get_youtube_transcript.py "<url_youtube>"
```
Gemini escuchará el stream de audio en la nube con un **88% de ahorro de tokens**, sin necesidad de descargar el video al Mac.

---

### 3. Formateo Inteligente según el Tipo de Contenido

Una vez obtenido el texto transcrito:

#### A. Si es un Canto / Alabanza / Música Cristiana:
- Aplica las **Reglas de Formateo de Coros**:
  - Salida exclusivamente en bloque de código `text`.
  - Estructuración limpia en estrofas, coros y puentes.
  - **Mayúsculas reverenciales obligatorias** para la Deidad divina (*Tú, Ti, Te, Él, Su, Suyo, Tu bondad, Tus brazos, Señor*).
  - Dos líneas en blanco de separación entre secciones.

#### B. Si es un Podcast / Entrevista / Conferencia:
- Entrega un **Reporte Estructurado**:
  - **Resumen Ejecutivo:** 2 a 3 párrafos con las ideas clave.
  - **Puntos Clave / Temas Tratados:** Bullet points destacados.
  - **Línea de Tiempo (Marcas de Tiempo):** Segmentos con `[MM:SS]` e idea principal.
  - **Transcripción Completa Limpia:** Texto fluido y corregido ortográficamente.

---

### 4. Limpieza Inmediata de Archivos Temporales
Una vez entregada la respuesta al usuario, elimina los archivos temporales de `scratch/`:
```bash
rm -f scratch/transcribe_audio.py scratch/transcript_result.json
```

---

## 📋 Checklist antes de finalizar
- [ ] ¿Se evitó estrictamente llamar a `view_file` sobre el archivo de audio binario?
- [ ] ¿Se seleccionó el nivel correcto (N1 Local Whisper, N2 Gemini 3.5 Transcribe o N3 Agentic Video)?
- [ ] ¿Se aplicó el formato adecuado (mayúsculas reverenciales para cantos o resumen para podcasts)?
- [ ] ¿Se eliminaron los archivos temporales generados en `scratch/`?
