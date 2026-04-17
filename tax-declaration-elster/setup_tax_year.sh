#!/bin/bash
# Setup Script für deine Elster-Steuererklärung

set -e

echo "🎯 Elster Steuererklärung 2025 - Setup"
echo "======================================"
echo ""

# Konfigurierbar
YEAR=${1:-2025}
OUTPUT_DIR="${HOME}/Steuern_${YEAR}"

echo "📁 Erstelle Verzeichnisstruktur in: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"/{persoenliche_daten,einnahmen,werbungskosten,immobilien/belege,belege/{scans,rechnungen}}

echo "✓ Verzeichnisse erstellt"
echo ""

# Template: Persönliche Daten
cat > "$OUTPUT_DIR/persoenliche_daten.json" << 'EOF'
{
  "first_name": "YOUR_FIRST_NAME",
  "last_name": "YOUR_LAST_NAME",
  "date_of_birth": "YYYY-MM-DD",
  "tax_id": "YOUR_TAX_ID",
  "street": "YOUR_STREET_AND_NUMBER",
  "city": "YOUR_CITY",
  "postal_code": "YOUR_POSTAL_CODE",
  "email": "your.email@example.com",
  "phone": "+49 xxx xxxxxxx"
}
EOF
echo "✓ Template: persoenliche_daten.json"

# Template: Einnahmen
cat > "$OUTPUT_DIR/einnahmen.csv" << 'EOF'
source,amount,description
employment,0,Jahresbruttolohn
interest,0,Sparbuchzinsen
capital_gains,0,Aktienverkauf Gewinne
freelance,0,Freiberufliche Tätigkeit
EOF
echo "✓ Template: einnahmen.csv"

# Template: Werbungskosten
cat > "$OUTPUT_DIR/werbungskosten.csv" << 'EOF'
category,amount,description
work_expenses,0,Homeoffice und Arbeitsmittel
professional_development,0,Fortbildungskosten
donations,0,Spenden an gemeinnützige Organisationen
insurance,0,Berufshaftpflichtversicherung
training_expenses,0,Ausbildungs- und Fortbildungskosten
other,0,Sonstige Werbungskosten
EOF
echo "✓ Template: werbungskosten.csv"

# Template: Immobilie
cat > "$OUTPUT_DIR/immobilien/immobilie_1.json" << 'EOF'
[
  {
    "name": "PROPERTY_NAME",
    "address": "STREET_AND_NUMBER",
    "postal_code": "POSTAL_CODE",
    "city": "CITY",
    "type": "apartment",
    "purchase_price": 0,
    "purchase_date": "YYYY-MM-DD",
    "rental_income": 0,
    "expense_repairs": 0,
    "expense_insurance": 0,
    "expense_management": 0,
    "expense_utilities": 0,
    "expense_loan_interest": 0,
    "expense_cleaning": 0,
    "expense_gardening": 0,
    "notes": "Notizen zur Immobilie"
  }
]
EOF
echo "✓ Template: immobilien/immobilie_1.json"

# Create README
cat > "$OUTPUT_DIR/README.md" << 'EOF'
# Steuererklärung 2025

## 📋 Anleitung

1. **persoenliche_daten.json**
   - Trage deine persönlichen Daten ein
   - ALLE Felder ausfüllen

2. **einnahmen.csv**
   - Ersetze die 0 mit deinen Beträgen
   - Reihenfolge ist egal
   - Dezimaltrennzeichen: Komma (1.200,50) oder Punkt (1200.50)

3. **werbungskosten.csv**
   - Deine Abzüge eintragen
   - Nicht benötigte Kategorien können 0 sein

4. **immobilien/immobilie_1.json**
   - Wenn du Mietliegenschaften hast
   - rental_income = MONATLICHE Miete (nicht Jahres!)
   - Ausgaben alle eintragen
   - Mehrere Dateien für mehrere Immobilien

## 🚀 Kommandos

```bash
# Import testen
cd /path/to/claude-quickstarts/tax-declaration-elster
python -m tax_declaration_elster.cli import-data "PATH_TO_THIS_FOLDER" --year 2025

# Validieren
python -m tax_declaration_elster.cli validate declaration_imported.json

# Formularanweisungen generieren
python -m tax_declaration_elster.cli generate declaration_imported.json
```

## 💡 Tipps

- **Dezimalformat:** 1.200,50 oder 1200,50 (beide funktionieren)
- **Immobilien:** rental_income ist die MONATLICHE Miete (wird auto × 12)
- **Mehrere Immobilien:** Kopiere immobilie_1.json zu immobilie_2.json, etc.
- **Belege:** Scans in belege/scans/ speichern
EOF
echo "✓ Template: README.md"

echo ""
echo "======================================"
echo "✅ Setup abgeschlossen!"
echo "======================================"
echo ""
echo "📂 Ordner: $OUTPUT_DIR"
echo ""
echo "📝 Nächste Schritte:"
echo "   1. Öffne: $OUTPUT_DIR/persoenliche_daten.json"
echo "   2. Trage deine Daten ein"
echo "   3. Fülle einnahmen.csv und werbungskosten.csv aus"
echo "   4. Für Mietliegenschaften: Nutze immobilien/immobilie_1.json"
echo ""
echo "🚀 Kommando zum Testen:"
echo "   python -m tax_declaration_elster.cli import-data \"$OUTPUT_DIR\" --year $YEAR"
echo ""
