#  Computer-Use Demo

#computer-use #python #docker #important #frequently-used

Ein vollständiger Agent mit Zugriff auf Computer-Funktionen. Kann Screenshots nehmen, Mausclicks ausführen, Text eingeben und komplexe Aufgaben automatisieren.

## 📋 Überblick

- **Sprache:** Python
- **Fokus:** Computer Automation & Vision
- **Komplexität:** Hoch
- **Docker:** Ja (required)

## 🚀 Schnellstart

```bash
# Setup
./setup.sh

# Docker Image bauen
docker build . -t computer-use-demo:local

# Container starten
docker run -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  -v $(pwd)/computer_use_demo:/home/computeruse/computer_use_demo/ \
  -v $HOME/.anthropic:/home/computeruse/.anthropic \
  -p 5900:5900 -p 8501:8501 -p 6080:6080 -p 8080:8080 \
  -it computer-use-demo:local
```

## 🧪 Testing & Quality

```bash
# Linting
ruff check .

# Formatierung
ruff format .

# Type Checking
pyright

# Tests ausführen
pytest

# Einzelner Test
pytest tests/path_to_test.py::test_name -v
```

## 📁 Struktur

- `computer_use_demo/` - Hauptquellcode
- `tests/` - Testdateien
- `Dockerfile` - Container-Konfiguration
- `setup.sh` - Initialisierungsskript

## 🔧 Code Style

- **Functions/Variables:** snake_case
- **Classes:** PascalCase
- **Imports:** isort mit combine-as-imports
- **Error Handling:** Custom ToolError für Tool-Fehler
- **Types:** Typ-Annotationen überall
- **OOP:** Dataclasses & ABC (Abstract Base Classes)

## 📚 Related

- [[Setup & Entwicklung]]
- [[Code Standards]]
- [[Tools & Dependencies]]

---
**Last Updated:** 2026-04-20
