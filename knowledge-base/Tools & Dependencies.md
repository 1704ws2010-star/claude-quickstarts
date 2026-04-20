# Tools & Dependencies

Übersicht aller verwendeten Tools und Dependencies in den Claude Quickstarts.

## 🐍 Python Tools

### Linting & Formatting

- **ruff** - Fast Python linter & formatter
  - `ruff check .` - Code analysieren
  - `ruff format .` - Code formatieren
  - Konfiguration über `pyproject.toml`

### Type Checking

- **pyright** - Static type checker für Python
  - `pyright` - Whole project type check
  - Unterstützt moderne Python-Typen

### Testing

- **pytest** - Testing Framework
  - `pytest` - Alle Tests ausführen
  - `pytest tests/path_to_test.py::test_name -v` - Einzelner Test
  - Plugins für mocking und coverage

### Code Quality

- **isort** - Import organizer
  - Alphabetische Sortierung
  - Gruppierung nach Kategorie
  - `combine-as-imports` Flag

## 🔷 JavaScript/TypeScript Tools

### Framework & Runtime

- **Node.js** - JavaScript Runtime
- **npm** - Package Manager
- **Next.js** - React Framework
  - App Router
  - Built-in Optimization

### Linting

- **ESLint** - JavaScript/TypeScript Linter
  - `npm run lint` - Code analysieren
  - Next.js Configuration
  - Auto-fix mit `--fix` Flag

### Type Checking

- **TypeScript** - Type System
  - Strict Mode erforderlich
  - Automatische Checks beim Kompilieren

### UI Component Library

- **shadcn/ui** - Headless UI Components
  - Basierend auf Radix UI & Tailwind CSS
  - Komponenten-getriebene Architektur
  - Copy-paste Components (nicht npm package)

### Data Visualization

- **Recharts** - React Charts Library
  - Responsive Charts
  - Verschiedene Chart-Typen
  - Built on React Components

## 🏗️ Build Tools

### Python

- **Docker** - Container Runtime (Computer-Use Demo)
  - Image Building: `docker build . -t computer-use-demo:local`
  - Container Running mit Port-Mapping

### JavaScript/TypeScript

- **npm scripts** - Build automation
  - `npm run dev` - Development Server
  - `npm run build` - Production Build
  - `npm run lint` - Code Quality

## 📦 Key Dependencies

### Python Projects

| Package | Purpose |
|---------|---------|
| anthropic | Claude API Client |
| pytest | Testing Framework |
| ruff | Linting & Formatting |
| pyright | Type Checking |
| isort | Import Sorting |

### TypeScript Projects

| Package | Purpose |
|---------|---------|
| react | UI Library |
| next | Full-stack Framework |
| typescript | Type System |
| shadcn/ui | UI Components |
| recharts | Data Visualization |
| tailwindcss | CSS Framework |

## 🔑 Configuration Files

### Python

- `pyproject.toml` - Project Metadata & Tool Config
- `.pre-commit-config.yaml` - Pre-commit Hooks
- `pytest.ini` - Pytest Configuration (if needed)

### JavaScript

- `package.json` - Dependencies & Scripts
- `tsconfig.json` - TypeScript Configuration
- `.eslintrc.json` - ESLint Configuration
- `next.config.js` - Next.js Configuration

## 📚 Related

- [[Setup & Entwicklung]]
- [[Code Standards]]

---
**Last Updated:** 2026-04-20
