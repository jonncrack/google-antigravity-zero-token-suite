---
name: archive-inspector-optimizer
description: "Protocolo optimizado de inspección, exploración de árboles de directorios y extracción quirúrgica de archivos comprimidos (.zip, .tar.gz, .tgz, .rar, .7z, .bz2) 100% local a 0 tokens."
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

# 📦 Archive Inspector & Extractor Optimizer

## Cuándo usar esta skill
- El usuario proporcione o mencione un archivo comprimido (`.zip`, `.tar`, `.tar.gz`, `.tgz`, `.rar`, `.7z`, `.bz2`) proveniente de Moodle (respaldos de cursos, paquetes SCORM), plataformas escolares, descargas web o backups.
- Se requiera inspeccionar el contenido interno de un paquete sin descomprimirlo a ciegas en el espacio de trabajo.
- Se necesite extraer de forma quirúrgica solo archivos específicos (ej. únicamente los `.pdf`, `.xlsx`, `.md` o `.json`) para su análisis.

## ⛔ Regla de Oro (Anti-Desperdicio de Tokens)
**PROHIBICIÓN ESTRICTA:** NUNCA descomprimas archivos grandes masivamente dentro de la raíz del proyecto ni vuelques listas de miles de rutas repetitivas al chat.
- *Motivo:* Descomprimir miles de archivos dispersos contamina el árbol del workspace y llena la ventana de contexto de texto basura.
- *Solución:* Inspecciona el archivo de forma **Headless en memoria** con Python (`zipfile` / `tarfile`) o comandos de consola (`unzip -l`, `tar -tf`), presentando un resumen compacto y extrayendo únicamente los archivos solicitados a un directorio temporal aislado (`scratch/extracted/`).

---

## 🛠️ Protocolo de Ejecución Paso a Paso

### 1. Inspección Rápida en Memoria (Sin Descomprimir)
Para listar la estructura y detectar archivos clave según su extensión y tamaño:

```python
import sys
import zipfile
import tarfile
import os
import json

def inspect_archive(archive_path):
    ext = archive_path.lower()
    items = []
    
    if ext.endswith(".zip"):
        with zipfile.ZipFile(archive_path, 'r') as z:
            for info in z.infolist():
                if not info.is_dir():
                    items.append({
                        "filename": info.filename,
                        "size_bytes": info.file_size,
                        "compressed_bytes": info.compress_size
                    })
    elif ext.endswith((".tar.gz", ".tgz", ".tar", ".tar.bz2")):
        mode = "r:gz" if ext.endswith((".tar.gz", ".tgz")) else ("r:bz2" if ext.endswith(".tar.bz2") else "r:")
        with tarfile.open(archive_path, mode) as t:
            for member in t.getmembers():
                if member.isfile():
                    items.append({
                        "filename": member.name,
                        "size_bytes": member.size
                    })

    # Resumen por tipo de extensión
    summary_by_ext = {}
    for item in items:
        _, file_ext = os.path.splitext(item["filename"])
        file_ext = file_ext.lower() or "sin_extension"
        summary_by_ext[file_ext] = summary_by_ext.get(file_ext, 0) + 1

    return {
        "total_files": len(items),
        "extension_summary": summary_by_ext,
        "sample_files": items[:25]  # Muestra representativa
    }

if __name__ == "__main__":
    if len(sys.argv) > 1:
        print(json.dumps(inspect_archive(sys.argv[1]), indent=2, ensure_ascii=False))
```

### 2. Extracción Quirúrgica (Targeted Extraction)
Cuando el usuario solicite procesar un archivo interno específico o un grupo de extensiones:
- Extrae **únicamente los archivos necesarios** hacia `scratch/extracted/`:
```bash
# Para ZIP
unzip -q -j "ruta/archivo.zip" "carpeta_interna/documento.pdf" -d scratch/extracted/

# Para TAR.GZ
tar -xzf "ruta/archivo.tar.gz" -C scratch/extracted/ "carpeta_interna/documento.pdf"
```
- Luego, enruta el archivo extraído a su skill correspondiente (`pdf-analysis-optimizer`, `office-files-optimizer`, etc.).

---

### 3. Formato de Entrega al Usuario
- **Resumen Ejecutivo del Paquete:** Total de archivos, peso total y desglose por tipo (ej. `12 PDFs, 4 Excels, 1 base de datos`).
- **Árbol de Directorios Simplificado:** Principales carpetas y archivos destacados.
- **Acción Realizada:** Cuáles archivos específicos fueron extraídos a `scratch/extracted/` para su análisis posterior.

---

### 4. Limpieza Automática
Al concluir el análisis del contenido extraído:
```bash
rm -rf scratch/extracted scratch/inspect_archive.py
```

---

## 📋 Checklist antes de finalizar
- [ ] ¿Se inspeccionó el archivo comprimido sin desempacar todo al disco principal?
- [ ] ¿Se extrajeron únicamente los archivos indispensables a un directorio temporal aislado?
- [ ] ¿Se presentaron las estadísticas y tipos de archivos de forma compacta?
- [ ] ¿Se limpiaron los temporales al finalizar?
