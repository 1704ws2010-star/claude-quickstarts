# Legal & Compliance

Rechtliche Anforderungen und Dokumentationspflichten für die Claude Quickstarts.

## 📄 Copyright Notices

### CHANGELOG.md Pflicht

Wenn Änderungen an Dateien mit **Copyright Notice** gemacht werden:

1. **Lokalisiert:** Gehe in das Subdirectory der geänderten Datei
2. **Erstelle oder aktualisiere:** `CHANGELOG.md` im selben Directory
3. **Dokumentiere:** Die Änderung mit Datum und Beschreibung

### Struktur einer CHANGELOG.md

```markdown
# Changelog

## [Unreleased]

### Changed
- Updated authentication system
- Fixed memory leak in worker thread

### Added
- New feature X
- Support for Y

### Fixed
- Bug with Z

## [1.0.0] - 2026-04-20

### Initial Release
- Initial version with core features
```

### Wo CHANGELOG.md Dateien existieren

- `computer-use-demo/CHANGELOG.md`
- Weitere Projekte nach Bedarf

## 📋 Copyright Notice Locations

Dateien mit Copyright Notices sind üblicherweise oben in der Datei dokumentiert:

```python
# Copyright (c) 2024 Anthropic
# Licensed under [License Type]
```

```typescript
// Copyright (c) 2024 Anthropic
// Licensed under [License Type]
```

## 🔄 Workflow beim Ändern copyrighted Files

1. **Datei mit Copyright identifizieren**
2. **Zur CHANGELOG.md des Subdirectories navigieren**
3. **Änderung dokumentieren** unter entsprechender Kategorie
4. **Commit mit Referenz** zur CHANGELOG.md erstellen

## 📄 License Information

- Repository-Level License: `LICENSE` im Root
- Projekt-spezifische Licenses in Subdirectories (falls vorhanden)

## 📚 Related

- [[Projects]]

---
**Last Updated:** 2026-04-20
