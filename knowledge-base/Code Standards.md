# Code Standards & Best Practices

Richtlinien für Code-Qualität und Stil in den Claude Quickstarts.

## 🐍 Python Style Guide

### Naming Conventions

- **Functions & Variables:** `snake_case`
- **Classes:** `PascalCase`
- **Constants:** `UPPER_SNAKE_CASE`

### Imports

- Nutze `isort` mit `combine-as-imports`
- Gruppierung: stdlib → third-party → local
- Beispiel:
  ```python
  from typing import Optional
  from pathlib import Path
  
  import requests
  from anthropic import Anthropic
  
  from my_module import helper_function
  ```

### Type Annotations

**Erforderlich für:**
- Alle Funktionsparameter
- Alle Rückgabewerte
- Klassenattribute wo sinnvoll

```python
def process_data(items: list[str], timeout: int = 30) -> dict[str, any]:
    """Process items and return results."""
    pass
```

### Classes & OOP

- Nutze `dataclasses` für Datenklassen
- Nutze `ABC` (Abstract Base Classes) für abstrakte Klassen
- Dokumentiere die Schnittstelle klar

```python
from dataclasses import dataclass
from abc import ABC, abstractmethod

@dataclass
class Config:
    name: str
    debug: bool = False

class BaseAgent(ABC):
    @abstractmethod
    def run(self):
        pass
```

### Error Handling

- Nutze **custom `ToolError`** für Tool-spezifische Fehler
- Gebe aussagekräftige Fehlermeldungen
- Unterscheide zwischen erwarteten und unerwarteten Fehlern

```python
from custom_errors import ToolError

try:
    result = run_tool()
except ToolError as e:
    logger.error(f"Tool failed: {e}")
except Exception as e:
    logger.critical(f"Unexpected error: {e}")
```

## 🔷 TypeScript/JavaScript Style Guide

### Mode

- **TypeScript Strict Mode** erforderlich
- Alle Dateien müssen gültig sein

### Naming Conventions

- **Variables & Functions:** `camelCase`
- **Classes & Types:** `PascalCase`
- **Constants:** `UPPER_CASE`

### Components

- **React:** Function Components (nicht Class Components)
- **Hooks:** React Hooks für State Management
- Beispiel:
  ```typescript
  interface Props {
    title: string;
    onSubmit: (data: string) => void;
  }
  
  export const MyComponent: React.FC<Props> = ({ title, onSubmit }) => {
    const [state, setState] = useState('');
    
    return <div>{title}</div>;
  };
  ```

### Type Definitions

- Definiere alle Props als Interfaces
- Nutze `type` für Union Types und Aliases
- Sei explicit mit Rückgabewerten

```typescript
interface UserData {
  id: string;
  name: string;
  email: string;
}

type Status = 'loading' | 'success' | 'error';

function fetchUser(id: string): Promise<UserData> {
  // ...
}
```

### UI Components (shadcn/ui)

- Nutze shadcn/ui Komponenten
- Importiere nur was du brauchst
- Respektiere die Komponenteneigenschaften

## 📋 General Best Practices

### Comments

- **Minimal kommentieren** - guter Code dokumentiert sich selbst
- **Nutze kurze einzeilige Kommentare** wenn nötig
- **Dokumentiere das WARUM**, nicht das WAS
- Beispiel:
  ```python
  # Exponential backoff: Retry nach 2s, 4s, 8s, 16s
  for attempt in range(4):
      if try_operation():
          break
      time.sleep(2 ** attempt)
  ```

### Documentation

- Nutze Docstrings für Module und Klassen (kurz!)
- Für komplexe Funktionen: Kurze Erklärung
- Halte es auf den Punkt

```python
def calculate_hash(data: str) -> str:
    """Generate SHA256 hash of data."""
    return hashlib.sha256(data.encode()).hexdigest()
```

### DRY & Abstraktion

- **Schreibe keinen Code voraus** - Three similar lines sind besser als premature abstraction
- **YAGNI** - You Aren't Gonna Need It
- Löse nur die aktuelle Anforderung

### Testing

- Schreibe Tests für neue Features
- Unit Tests mit pytest (Python)
- Teste Edge Cases
- Mock externe Dependencies

## 🛠️ Tools & Linting

### Python

- **ruff check** - Linting
- **ruff format** - Auto-formatting
- **pyright** - Type Checking
- **pytest** - Testing

### TypeScript/JavaScript

- **ESLint** - Linting
- **TypeScript** - Type Checking (automatisch)
- **Next.js configuration** für React Projects

## 📚 Related

- [[Setup & Entwicklung]]
- [[Projects]]

---
**Last Updated:** 2026-04-20
