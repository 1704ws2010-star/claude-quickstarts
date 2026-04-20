# Setup & Entwicklung

Vollständige Anleitung zum Aufsetzen und Entwickeln an den Claude Quickstart Projekten.

## 🐍 Python Projekte

### Computer-Use Demo

```bash
# 1. Repository Setup
./setup.sh

# 2. Docker Image bauen
docker build . -t computer-use-demo:local

# 3. Container mit allen Ports starten
docker run -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  -v $(pwd)/computer_use_demo:/home/computeruse/computer_use_demo/ \
  -v $HOME/.anthropic:/home/computeruse/.anthropic \
  -p 5900:5900 -p 8501:8501 -p 6080:6080 -p 8080:8080 \
  -it computer-use-demo:local
```

**Ports:**
- 5900 - VNC Remote Desktop
- 8501 - Streamlit UI
- 6080 - noVNC Browser
- 8080 - HTTP Server

### Browser-Use Demo

```bash
# Setup wie Computer-Use Demo
./setup.sh
pip install -r requirements.txt
```

### Autonomous Coding

```bash
# Einfacheres Setup, nur Dependencies
pip install -r requirements.txt
```

## 📦 JavaScript/TypeScript Projekte

### Setup

```bash
# Dependencies installieren
npm install

# Dev Server starten
npm run dev

# Für bestimmte Varianten:
npm run dev:left    # Customer Support - Left Sidebar
npm run dev:right   # Customer Support - Right Sidebar
npm run dev:chat    # Customer Support - Chat Only
```

### Production Build

```bash
npm run build
```

## 🧪 Testing & Quality Checks

### Python

```bash
# Linting
ruff check .

# Formatierung
ruff format .

# Type Checking
pyright

# Tests ausführen
pytest

# Einzelnen Test ausführen
pytest tests/path_to_test.py::test_name -v
```

### TypeScript/JavaScript

```bash
# Linting
npm run lint

# Type Checking (automatisch durch TypeScript)
```

## 🔑 Environment Variables

### ANTHROPIC_API_KEY

Erforderlich für alle Projekte! Setzen mit:

```bash
export ANTHROPIC_API_KEY=your-key-here
```

## 📚 Related

- [[Projects]]
- [[Code Standards]]

---
**Last Updated:** 2026-04-20
