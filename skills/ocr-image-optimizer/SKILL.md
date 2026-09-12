---
name: ocr-image-optimizer
description: "Protocolo optimizado de OCR y extracción de texto de imágenes escaneadas (.png, .jpg, .jpeg, .webp de recibos, actas, exámenes o cuadros) 100% local (offline) vía Tesseract/Pillow/Python a 0 tokens de visión de API."
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

# 🖼️ OCR & Scanned Image Optimizer

## Cuándo usar esta skill
- El usuario proporcione o mencione imágenes (`.png`, `.jpg`, `.jpeg`, `.webp`, `.bmp`, `.tiff`) que contengan **texto escaneado o fotografiado**:
  - Recibos y comprobantes bancarios (NPE de Banco Agrícola, transferencias, facturas).
  - Exámenes en papel, guías de estudio o libros escaneados.
  - Cuadros de notas, actas de calificaciones o listas impresas de estudiantes.
  - Capturas de pantalla con tablas de datos extensas.

## ⛔ Regla de Oro (Anti-Desperdicio de Tokens Multimodales)
**PROHIBICIÓN ESTRICTA:** NUNCA envíes imágenes pesadas llenas de texto denso directamente al modelo de visión en la nube si el objetivo principal es simplemente extraer o digitalizar el texto.
- *Motivo:* El análisis visual de imágenes de alta resolución satura la ventana de contexto con tokens multimodales pesados en cada turno de la conversación.
- *Solución:* Extrae el texto y cifras de forma **100% local y offline** utilizando el motor `tesseract` instalado en la Mac con pre-procesamiento de imagen en Python (`Pillow`), entregando al chat únicamente el texto plano estructurado en Markdown a **0 tokens de visión**.

---

## 🛠️ Protocolo de Ejecución Paso a Paso

### 1. Pre-procesamiento de Imagen y Extracción OCR Local
Crea y ejecuta un script de OCR en `scratch/ocr_extractor.py` optimizado para nitidez y contraste:

```python
import sys
import os
import subprocess
from PIL import Image, ImageEnhance, ImageFilter

def preprocess_and_ocr(image_path, lang="spa", psm="11"):
    # 1. Cargar imagen y convertir a escala de grises
    img = Image.open(image_path).convert('L')
    
    # 2. Aumentar contraste y nitidez para mejor lectura de fuentes y números
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(2.0)
    img = img.filter(ImageFilter.SHARPEN)
    
    temp_img_path = "scratch/temp_preprocessed.png"
    img.save(temp_img_path)
    
    # 3. Ejecutar Tesseract OCR local en macOS
    # PSM 11 (Sparse text) es ideal para tablas y columnas. Si falla, usa PSM 6 (Bloque uniforme).
    output_base = "scratch/ocr_output"
    cmd = [
        "tesseract",
        temp_img_path,
        output_base,
        "-l", lang,
        "--psm", psm
    ]
    
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError:
        # Fallback sin idioma específico
        cmd_fallback = ["tesseract", temp_img_path, output_base, "--psm", psm]
        subprocess.run(cmd_fallback, check=True)
        
    txt_file = f"{output_base}.txt"
    if os.path.exists(txt_file):
        with open(txt_file, "r", encoding="utf-8", errors="ignore") as f:
            text = f.read()
        return text.strip()
    return ""

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Permite pasar el psm como segundo argumento, por defecto usa 11
        psm_mode = sys.argv[2] if len(sys.argv) > 2 else "11"
        result = preprocess_and_ocr(sys.argv[1], psm=psm_mode)
        print(result)
```

### 2. Ejecución Headless
Ejecuta el script por consola guardando el resultado de texto en `scratch/`:
```bash
python3 scratch/ocr_extractor.py "ruta/a/la/imagen.png" > scratch/ocr_result.txt
```

Lee únicamente el texto plano resultante con `view_file` (consumiendo solo tokens de texto ligero).

---

### 3. Estructuración Inteligente según el Contenido

Una vez extraído el texto:

#### A. Si es un Recibo de Pago / Comprobante Bancario (NPE):
- Extrae y valida con expresiones regulares:
  - **Número de NPE / Referencia:** (ej. formato 28 a 34 dígitos).
  - **Monto Pagado ($):** Cifra exacta con decimales.
  - **Fecha y Hora de Transacción:** Formato estandarizado.
  - **Nombre del Alumno / Cliente y Banco emisor.**
- Presenta una ficha técnica de validación financiera en Markdown.

#### B. Si es un Examen o Guía Educativa:
- Estructura las preguntas en formato estándar Markdown (encabezados, opciones A, B, C, D o reactivos ELAC).

#### C. Si es un Cuadro de Notas o Lista:
- Reconstruye los datos en una tabla limpia de Markdown (`| Alumno | Nota 1 | Nota 2 | Promedio |`).

---

### 4. Limpieza Automática
Elimina los archivos temporales generados:
```bash
rm -f scratch/ocr_extractor.py scratch/temp_preprocessed.png scratch/ocr_output.txt scratch/ocr_result.txt
```

---

## 📋 Checklist antes de finalizar
- [ ] ¿Se extrajo el texto con Tesseract local sin enviar imágenes densas a la nube?
- [ ] ¿Se pre-procesó la imagen para asegurar legibilidad de números y montos?
- [ ] ¿Se estructuraron los datos extraídos (recibo, examen o tabla)?
- [ ] ¿Se eliminaron los archivos temporales de `scratch/`?
