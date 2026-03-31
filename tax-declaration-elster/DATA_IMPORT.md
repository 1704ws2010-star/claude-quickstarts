# 📂 Daten-Import Guide

Dieses Dokument erklärt die Verzeichnisstruktur und wie der Import funktioniert.

## 📁 Verzeichnisstruktur

```
data/
└── 2025/                          # Steuerjahr
    ├── persoenliche_daten.json    # Stammdaten (ERFORDERLICH)
    ├── einnahmen.csv              # Einnahmequellen (optional)
    ├── werbungskosten.csv         # Persönliche Abzüge (optional)
    ├── immobilien/                # Mietliegenschaften (optional)
    │   ├── wohnung_berlin.json
    │   ├── haus_hamburg.csv
    │   └── haus_muenchen.xlsx
    └── belege/                    # Dokumentation (optional)
        ├── scans/
        └── rechnungen/
```

---

## 📋 Dateiformate & Inhalte

### 1️⃣ **persoenliche_daten.json** (ERFORDERLICH)

```json
{
  "first_name": "Wolfgang",
  "last_name": "Schachtner",
  "date_of_birth": "1970-01-01",
  "tax_id": "12345678901",
  "street": "Berliner Straße 42",
  "city": "München",
  "postal_code": "80801",
  "email": "wolfgang@example.com",
  "phone": "+49 89 123456"
}
```

**Felder:**
- `first_name` - Vorname
- `last_name` - Nachname
- `date_of_birth` - Geburtsdatum (YYYY-MM-DD)
- `tax_id` - Elster-ID / Steuer-ID
- `street` - Straße und Hausnummer
- `city` - Stadt
- `postal_code` - Postleitzahl
- `email` - Email (optional)
- `phone` - Telefon (optional)

---

### 2️⃣ **einnahmen.csv** (optional)

```csv
source,amount,description
employment,65000,Bruttojahresgehalt
interest,450,Sparbuchzinsen
capital_gains,1200,Aktienverkauf Gewinne
freelance,5000,Freiberufliche Tätigkeit
```

**Spalten:**
- `source` - Einnahmequelle (employment, interest, capital_gains, freelance, etc.)
- `amount` - Betrag (Punkt oder Komma als Dezimaltrennzeichen)
- `description` - Beschreibung (optional)

**Oder JSON Format:**
```json
[
  {"source": "employment", "amount": 65000, "description": "Jahresgehalt"},
  {"source": "interest", "amount": 450, "description": "Bankzinsen"}
]
```

---

### 3️⃣ **werbungskosten.csv** (optional)

```csv
category,amount,description
work_expenses,1500,Homeoffice und Arbeitsmittel
professional_development,1200,Fortbildungskosten
donations,800,Spenden an gemeinnützige Organisationen
insurance,2400,Berufshaftpflichtversicherung
```

**Spalten:**
- `category` - Abzug-Kategorie
- `amount` - Betrag
- `description` - Beschreibung (optional)

**Verfügbare Kategorien:**
```
work_expenses              Werbungskosten / Arbeitsmittel
professional_development  Fortbildung und Kurse
donations                 Spenden
insurance                 Versicherungen
training_expenses         Ausbildungskosten
gifts                     Geschenke
travel                    Reisekosten
meals                     Verpflegung
```

---

### 4️⃣ **immobilien/** - Mietliegenschaften (optional)

Jede Immobilie kann als separates JSON oder CSV sein:

#### **JSON Format (Empfohlen):**
```json
[
  {
    "name": "Wohnung Berlin",
    "address": "Schönhauser Allee 42",
    "postal_code": "10435",
    "city": "Berlin",
    "type": "apartment",
    "purchase_price": 450000,
    "purchase_date": "2018-06-15",
    "rental_income": 1200,
    "expense_repairs": 800,
    "expense_insurance": 450,
    "expense_management": 150,
    "expense_utilities": 2100,
    "expense_loan_interest": 8500,
    "notes": "3-Zimmer mit Balkon"
  }
]
```

#### **CSV Format:**
```csv
name,address,postal_code,city,type,purchase_price,purchase_date,rental_income,expense_repairs,expense_insurance,expense_utilities
Haus Hamburg,Leineweber Str 15,21077,Hamburg,house,650000,2015-03-20,2500,2500,750,4800
```

**Immobilien-Felder:**
- `name` - Name der Immobilie
- `address` - Adresse
- `postal_code` - Postleitzahl
- `city` - Stadt
- `type` - Typ (apartment, house, commercial)
- `purchase_price` - Kaufpreis
- `purchase_date` - Kaufdatum (YYYY-MM-DD)
- `rental_income` - Monatliche Mieteinnahmen

**Werbungskosten für Immobilien:**
```
expense_repairs        Reparaturen/Instandhaltung
expense_insurance      Versicherungen
expense_management     Verwaltungsgebühren
expense_utilities      Nebenkosten (Wasser, Strom, Heizung)
expense_loan_interest  Darlehenskontenzinsen
expense_cleaning       Reinigung
expense_gardening      Gartenpflege
expense_tax_advice     Steuerberatung
```

---

## 🔄 Wie der Import funktioniert

### **Schritt 1: Import-Befehl starten**
```bash
python -m tax_declaration_elster.cli import-data data/2025 --year 2025
```

### **Schritt 2: Das macht der Import automatisch:**

```
1️⃣ persoenliche_daten.json
   ↓
   Liest: Vorname, Nachname, Adresse, Steuer-ID

2️⃣ einnahmen.csv / einnahmen.json / einnahmen.xlsx
   ↓
   Liest alle Einnahmequellen
   Konvertiert deutsche Dezimalformat (5.000,50 → 5000.50)

3️⃣ werbungskosten.csv / werbungskosten.json / werbungskosten.xlsx
   ↓
   Liest alle Abzüge
   Summiert automatisch

4️⃣ immobilien/*.json / immobilien/*.csv / immobilien/*.xlsx
   ↓
   Liest JEDE Datei im immobilien/-Ordner
   Pro Datei: 1 oder mehrere Immobilien
   Berechnet pro Immobilie:
     - Jährliche Mieteinnahmen (Monat × 12)
     - Summe aller Werbungskosten
     - Nettoeinkommen (Einnahmen - Kosten)

5️⃣ Gesamtberechnung
   ↓
   Addiert alle Einnahmen (Job + Immobilien + Sonstige)
   Subtrahiert alle Abzüge
   = Steuerpflichtiges Einkommen
```

### **Schritt 3: Output - Was kommt raus?**

```
📂 Importing from: data/2025
✓ Imported to: declaration_imported.json

📊 SUMMARY:
  Taxpayer: Wolfgang Schachtner
  Year: 2025

💰 INCOME:
  • employment: €65,000.00
  • interest: €450.00
  • capital_gains: €1,200.00
  Total: €66,650.00

🏠 PROPERTIES (2):
  • Wohnung Berlin: €14,400.00 - €12,000.00 = €2,400.00
  • Haus Hamburg: €30,000.00 - €9,550.00 = €20,450.00
  Total net: €22,850.00

📉 DEDUCTIONS:
  • work_expenses: €1,500.00
  • professional_development: €1,200.00
  • donations: €800.00
  • insurance: €2,400.00
  Total: €5,900.00

📊 TOTALS:
  Total Income: €89,500.00
  Total Deductions: €5,900.00
  Taxable Income: €83,600.00
```

---

## 🎯 Praktisches Beispiel

### **Szenario:**
Du hast:
- 1 Arbeitseinkommen: €60.000
- 2 Mietimmobilien
  - Wohnung Berlin: €1.200/Monat = €14.400/Jahr
  - Haus Hamburg: €2.500/Monat = €30.000/Jahr
- Verschiedene Werbungskosten

### **Dateistruktur:**
```
data/2025/
├── persoenliche_daten.json
├── einnahmen.csv
├── werbungskosten.csv
└── immobilien/
    ├── berlin.csv
    └── hamburg.json
```

### **Verarbeitung:**
```
Berlin CSV:
  rental_income: 1200 × 12 = 14.400
  Kosten: 800 + 450 + 150 + 2.100 + 8.500 = 12.000
  Netto: 14.400 - 12.000 = 2.400 ✓

Hamburg JSON:
  rental_income: 2500 × 12 = 30.000
  Kosten: 2.500 + 750 + 300 + 4.800 + 1.200 = 9.550
  Netto: 30.000 - 9.550 = 20.450 ✓

GESAMT:
  Einkommen: 60.000 + 14.400 + 30.000 = 104.400
  Abzüge: 5.900
  Steuerpflichtig: 98.500
```

---

## 💡 Wichtige Details

### **Deutsche Dezimalformate:**
Der Import verarbeitet automatisch:
- `1.200,50` → 1200.50 ✓
- `1200.50` → 1200.50 ✓
- `1200,50` → 1200.50 ✓

### **Flexible Dateiformate:**
```
einnahmen.csv      ✓ Funktioniert
einnahmen.json     ✓ Funktioniert
einnahmen.xlsx     ✓ Funktioniert (Excel)

immobilien/wohnung.csv      ✓ Funktioniert
immobilien/haus.json        ✓ Funktioniert
immobilien/grundstueck.xlsx ✓ Funktioniert
```

### **Mehrere Immobilien:**
```
immobilien/
├── wohnung_1.csv          # 1 Immobilie
├── hauser.json            # 1 oder mehrere (Array)
└── grundstuecke.xlsx      # 1 oder mehrere (Excel)
```

### **Automatische Berechnung:**
```
Pro Immobilie:
  Mieteinnahmen = rental_income × 12

Summe aller Werbungskosten:
  expense_* = SUMME(repairs + insurance + utilities + ...)

Nettoeinkommen:
  Einnahmen - Werbungskosten
```

---

## ✅ Checklist zum Starten

- [ ] `data/2025/persoenliche_daten.json` mit deinen Daten erstellt
- [ ] `einnahmen.csv` mit deinen Einnahmequellen (optional)
- [ ] `werbungskosten.csv` mit deinen Abzügen (optional)
- [ ] `immobilien/` Ordner mit deinen Mietliegenschaften (optional)
- [ ] Import-Befehl ausgeführt:
  ```bash
  python -m tax_declaration_elster.cli import-data data/2025
  ```
- [ ] Ergebnisse überprüft in `declaration_imported.json`

---

## 🚀 Nächste Schritte

Nach dem Import kannst du:
1. **Validieren**: `elster-fill validate declaration_imported.json`
2. **Formularanweisungen generieren**: `elster-fill generate declaration_imported.json`
3. **Elster eintragen**: Mit den generierten Anweisungen
