# 🎯 Quick Reference

Schnelle Befehle und Infos für den täglichen Gebrauch.

## 🚀 Häufig verwendete Befehle

### Python Projects Starten

```bash
# Computer-Use Demo
docker build . -t computer-use-demo:local
docker run -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY -p 5900:5900 -p 8501:8501 -p 6080:6080 -p 8080:8080 -it computer-use-demo:local

# Browser-Use Demo
./setup.sh && pip install -r requirements.txt

# Autonomous Coding
pip install -r requirements.txt
```

### TypeScript Projects Starten

```bash
npm install
npm run dev        # Full UI
npm run dev:left   # Left Sidebar (Customer Support)
npm run dev:right  # Right Sidebar (Customer Support)
npm run dev:chat   # Chat Only (Customer Support)
```

## 🧪 Quality Checks

### Python
```bash
ruff check .       # Lint
ruff format .      # Format
pyright            # Type Check
pytest             # Tests
```

### TypeScript
```bash
npm run lint       # Lint
npm run build      # Build
```

## 🔑 Environment

```bash
export ANTHROPIC_API_KEY=your-key-here
```

## 📞 Quick Links

- [[Projects]] - Alle Projekte
- [[Setup & Entwicklung]] - Detailliertes Setup
- [[Code Standards]] - Coding Guidelines
- [[Tools & Dependencies]] - Alle Tools

---
**Tipp:** Nutze CMD/CTRL+P um Dateien schnell zu öffnen!
