<#
.SYNOPSIS
    Reorganisiert deinen OneDrive-Stamm nach PARA und legt die finale
    Struktur fuer Bereiche, Steuer, Stammdaten und Templates an.

.DESCRIPTION
    Trockenlauf ist die Voreinstellung -- nichts wird angefasst, alles
    nur angezeigt und ins Logfile geschrieben. Erst mit -Execute werden
    die Aktionen wirklich ausgefuehrt (mit Rueckfrage davor).

    Was passiert:
    1. PARA-Wurzeln und Eingangs-Subordner anlegen
    2. Alte Top-Folder nach PARA verschieben (Tier 1)
    3. Aufteilungen (03_Beruf -> Wolfi/Daniela/Bundeswehr)
    4. Drei Immobilien-Bereiche anlegen (Vermietung Muenchen,
       Ferienwohnung Marquartstein, Eigenheim Hemhofen)
    5. Bestehende Dachauer-Substruktur in Vermietung Muenchen schieben
    6. Steuer-Substruktur (Anlage V, Haushaltsnahe, N) je Jahr anlegen
    7. Stammdaten-YAML-Templates und Beleg-Index-Stubs schreiben
    8. README.md, obsidian-schema.md, Notfall-Karte als Vorlage anlegen
    9. Tresor- und Logs-Platzhalter

    Sicherheits-Regeln:
    - Vorhandene Zielordner werden nicht ueberschrieben (Skip mit Hinweis)
    - Vorhandene Dateien werden nicht ueberschrieben
    - Geschuetzte Ordner (Vault, Desktop, Bilder, Dokumente ...) werden
      nie angefasst
    - Jede Aktion landet im Logfile

.PARAMETER OneDrivePath
    Pfad zum OneDrive-Stamm. Standard: $env:OneDrive

.PARAMETER VaultName
    Name des Obsidian-Vault-Ordners im OneDrive-Stamm.
    Standard: 'Schaur_Vault'

.PARAMETER Execute
    Erst dieser Schalter fuehrt die Aktionen wirklich aus.

.PARAMETER LogPath
    Pfad zum Logfile. Standard: <OneDrive>\_Logs\reorganize-<Zeitstempel>.txt

.EXAMPLE
    .\Reorganize-OneDrive-PARA.ps1
    Zeigt nur an, was passieren wuerde.

.EXAMPLE
    .\Reorganize-OneDrive-PARA.ps1 -Execute
    Fuehrt die Reorganisation durch (mit Rueckfrage).

.NOTES
    Vor dem Lauf: OneDrive-Sync auf diesem Geraet pausieren, andere
    Geraete schlafen lassen. Nach dem Lauf: Sync wieder aktivieren und
    einmal voll durchlaufen lassen, bevor du an einem anderen Geraet
    weiterarbeitest.
#>

[CmdletBinding()]
param(
    [string]$OneDrivePath = $env:OneDrive,
    [string]$VaultName    = 'Schaur_Vault',
    [switch]$Execute,
    [string]$LogPath
)

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

# Fuenf PARA-Wurzeln + zwei System-Ordner
$ParaRoots = @(
    '00_Eingang',
    '01_Projekte',
    '02_Bereiche',
    '03_Ressourcen',
    '04_Archiv',
    '_Tresor',
    '_Logs'
)

# Eingangs-Subordner
$EingangSub = @(
    '00_Eingang\Scans',
    '00_Eingang\Mail_Anhaenge',
    '00_Eingang\Zu_verschluesseln',
    '00_Eingang\_unsicher',
    '00_Eingang\KI_Vorschlaege'
)

# Bereiche-Substruktur (leer angelegt, fuellt sich mit Inhalten)
$BereichSub = @(
    '02_Bereiche\Familie\Daniela',
    '02_Bereiche\Familie\Paula',
    '02_Bereiche\Familie\Gemeinsam',

    '02_Bereiche\CoWork\Immobiliensuche\Roettenbach',
    '02_Bereiche\CoWork\Pensionsplanung_Gemeinsam',
    '02_Bereiche\CoWork\Familienorganisation',

    '02_Bereiche\Beruf Wolfi\Aktuell',
    '02_Bereiche\Beruf Wolfi\Vortraege_Grundbuch',
    '02_Bereiche\Beruf Wolfi\Fortbildung',

    '02_Bereiche\Beruf Daniela',

    '02_Bereiche\Bundeswehr Wolfi',

    '02_Bereiche\Vorsorge & Notfall\Wichtig',
    '02_Bereiche\Vorsorge & Notfall\Gesundheit',
    '02_Bereiche\Vorsorge & Notfall\Testament_Erbe',

    '02_Bereiche\Freizeit'
)

# Eigenheim Hemhofen (selbstgenutzt -- Paragraph 35a Haushaltsnahe)
$EigenheimSub = @(
    '02_Bereiche\Eigenheim Hemhofen\Kauf_und_Grundbuch',
    '02_Bereiche\Eigenheim Hemhofen\Versorger',
    '02_Bereiche\Eigenheim Hemhofen\Garten_und_Werkzeug',
    '02_Bereiche\Eigenheim Hemhofen\Bilder'
)

# Eigenheim -- Jahres-Subordner fuer Belege
$EigenheimYearly = @(
    '02_Bereiche\Eigenheim Hemhofen\Instandhaltung',
    '02_Bereiche\Eigenheim Hemhofen\Haushaltsnahe_Belege'
)

# Ferienwohnung Marquartstein (Eigennutzung, KEINE Vermietung)
$FewoSub = @(
    '02_Bereiche\Ferienwohnung Marquartstein\Kauf_und_Grundbuch',
    '02_Bereiche\Ferienwohnung Marquartstein\Versorger',
    '02_Bereiche\Ferienwohnung Marquartstein\Belegung',
    '02_Bereiche\Ferienwohnung Marquartstein\Bilder'
)

$FewoYearly = @(
    '02_Bereiche\Ferienwohnung Marquartstein\Instandhaltung'
)

# Vermietung Muenchen Dachauer344 (Anlage V relevant)
$VermietungSub = @(
    '02_Bereiche\Vermietung Muenchen_Dachauer344\Kauf_und_Grundbuch',
    '02_Bereiche\Vermietung Muenchen_Dachauer344\AfA',
    '02_Bereiche\Vermietung Muenchen_Dachauer344\Finanzierung_Zinsen',
    '02_Bereiche\Vermietung Muenchen_Dachauer344\Hausverwaltung',
    '02_Bereiche\Vermietung Muenchen_Dachauer344\Mieter',
    '02_Bereiche\Vermietung Muenchen_Dachauer344\Verwaltung_Laufend',
    '02_Bereiche\Vermietung Muenchen_Dachauer344\Bilder'
)

$VermietungYearly = @(
    '02_Bereiche\Vermietung Muenchen_Dachauer344\Instandhaltung',
    '02_Bereiche\Vermietung Muenchen_Dachauer344\Betriebskosten',
    '02_Bereiche\Vermietung Muenchen_Dachauer344\Sonderkonto'
)

# Finanzen-Substruktur
$FinanzenSub = @(
    '02_Bereiche\Finanzen & Steuern\Finanzen\Konten',
    '02_Bereiche\Finanzen & Steuern\Finanzen\Versicherungen',
    '02_Bereiche\Finanzen & Steuern\Finanzen\Depots_Vermoegen',
    '02_Bereiche\Finanzen & Steuern\Finanzen\Vertraege_Laufend'
)

# Steuer-Substruktur pro Jahr
$SteuerAnlagen = @(
    'Anlage_N_Wolfi',
    'Anlage_N_Daniela',
    'Anlage_V_Muenchen-Dachauer344',
    'Anlage_Vorsorgeaufwand',
    'Anlage_Sonderausgaben',
    'Anlage_Haushaltsnahe_Hemhofen',
    'Elster_Abgabe'
)

# Jahre, fuer die Steuer- und Belegt-Ordner angelegt werden
$BelegYears = @('2024', '2025', '2026')

# Ressourcen-Substruktur
$RessourcenSub = @(
    '03_Ressourcen\Tech_und_Skripte',
    '03_Ressourcen\KI_Skills_und_Prompts',
    '03_Ressourcen\Recht_und_Beamtentum',
    '03_Ressourcen\Steuern_Wissen',
    '03_Ressourcen\Immobilien_Fachwissen',
    '03_Ressourcen\Heimwerken_und_DIY',
    '03_Ressourcen\Bergsport_und_Outdoor',
    '03_Ressourcen\Training_und_Fitness',
    '03_Ressourcen\Ernaehrung',
    '03_Ressourcen\Vorlagen'
)

# Archiv-Substruktur (Ziel-Slots fuer spaeter)
$ArchivSub = @(
    '04_Archiv\Steuererklaerungen_alt',
    '04_Archiv\Immobilien_geprueft',
    '04_Archiv\Bundeswehr_abgeschlossen',
    '04_Archiv\Beruf_Wolfi_abgeschlossen'
)

# Beispiel-Projekte (leer, nur Container)
$ProjekteSub = @(
    '01_Projekte\2026_Reorganisation_OneDrive',
    '01_Projekte\2026_Dev_Elster_Fill',
    '01_Projekte\2026_Digitalisierung_Privat',
    '01_Projekte\2026_Pensionsvorbereitung'
)

# Tier-1-Verschiebungen: alte OneDrive-Topfolder -> PARA-Ziel
$Moves = [ordered]@{
    '01_Inbox_Scans'  = '00_Eingang\Scans'
    '02_Dienst_Bw'    = '02_Bereiche\Bundeswehr Wolfi'
    '02_Steuern'      = '02_Bereiche\Finanzen & Steuern\Steuern'
    '04_Immobilien'   = '02_Bereiche\Vermietung Muenchen_Dachauer344'
    '05_Finanzen'     = '02_Bereiche\Finanzen & Steuern\Finanzen'
    '06_CoWork'       = '02_Bereiche\CoWork'
    '07_Familie'      = '02_Bereiche\Familie'
    '08_Vorsorge'     = '02_Bereiche\Vorsorge & Notfall'
    '09_Freizeit'     = '02_Bereiche\Freizeit'
    '10_Archiv'       = '04_Archiv'
    '!!!WICHTIGES'    = '02_Bereiche\Vorsorge & Notfall\Wichtig'
}

# Aufteilungen: Quellordner enthaelt Unterordner, die je woandershin gehen
$Splits = @{
    '03_Beruf' = @{
        'Wolfi_Freistaat'     = '02_Bereiche\Beruf Wolfi\Aktuell'
        'Daniela_Freistaat'   = '02_Bereiche\Beruf Daniela'
        'Vortraege_Grundbuch' = '02_Bereiche\Beruf Wolfi\Vortraege_Grundbuch'
    }
}

# Ordner, die niemals angefasst werden
$Protected = @(
    $VaultName,
    'Desktop',
    'Dokumente',
    'Bilder',
    'Anlagen',
    'Anwendungen',
    '.OneDrive'
)

# Tier-2-Hinweise: nicht automatisch, am Ende ausgeben
$ManualReview = @(
    @{
        Path   = '000_Zu_erledigen'
        Reason = 'Aufgabenliste, kein Dokumentenlager. Inhalt pruefen und ' +
                 'einzeln zuordnen oder als Dashboard-Note in den Vault.'
    },
    @{
        Path   = '03_Beruf\Wolfi_Freistaat\OLG_Altbestand'
        Reason = 'Sehr grosser Altbestand (>2000 Unterordner). Empfehlung: ' +
                 'als ZIP in 04_Archiv\<Jahr>\OLG_Altbestand.zip ablegen.'
    }
)

# ---------------------------------------------------------------------------
# Templates -- werden ans Dateisystem geschrieben
# ---------------------------------------------------------------------------

$Template_README = @'
# OneDrive -- Persoenliches Aktenarchiv

Stand: siehe Aenderungsdatum dieser Datei.

## Top-Level-Struktur (PARA)

| Ordner | Zweck |
|---|---|
| `00_Eingang\` | Sammelpunkt fuer Scans, Mail-Anhaenge, Downloads. Wird woechentlich geleert. |
| `01_Projekte\` | Befristete Vorhaben mit klarem Ziel und Enddatum. |
| `02_Bereiche\` | Dauerhafte Verantwortlichkeiten (Familie, Beruf, Immobilien, Steuern). |
| `03_Ressourcen\` | Wissen, Referenzen, Vorlagen -- keine Verantwortung. |
| `04_Archiv\` | Erledigtes, eventuell spaeter wieder relevant. |
| `_Tresor\` | Cryptomator-Container fuer sensible Originale. |
| `_Logs\` | Logs der Sortier-Skripte und Reorg-Laeufe. |

## Drei Immobilien -- drei Welten

| Bereich | Nutzung | Steuerlich |
|---|---|---|
| `Vermietung Muenchen_Dachauer344` | vermietet | Anlage V |
| `Ferienwohnung Marquartstein` | Eigennutzung | -- |
| `Eigenheim Hemhofen` | selbstgenutzt | Anlage Haushaltsnahe (35a) |

## Beleg-Workflow

1. Scan / Mail-Anhang landet in `00_Eingang\`.
2. Sortier-Agent (oder du am Sonntag) routet nach Stammdaten.
3. Datei landet in `02_Bereiche\<Bereich>\<Kategorie>\<Jahr>\` mit
   Namensschema: `YYYY-MM-DD_Gewerk_Firma_Betrag.pdf`.
4. Sortier-Agent erzeugt parallel eine Markdown-Note im Vault mit
   Frontmatter (siehe `Schaur_Vault\99_Konfiguration\obsidian-schema.md`).
5. Steuer-Sicht entsteht automatisch via Dataview-Query im Vault.

## Tresor (Cryptomator)

Der Cryptomator-Container liegt unter `_Tresor\`. Inhalt:
Testamente, Vollmachten, hochsensitive Befunde, Vermoegensaufstellung
gesamt, Zugangsdaten.

Was NICHT in den Tresor gehoert: Routine-Belege, Versorgerrechnungen,
Mietvertraege. Dafuer reicht OneDrive-Verschluesselung.

## Notfall

Im Notfall finden Angehoerige unter
`02_Bereiche\Vorsorge & Notfall\Wichtig\NOTFALL-KARTE.md` die wichtigsten
Hinweise und unverschluesselte Kopien von Patientenverfuegung und
Vollmacht.

## Verwandte Skripte

- `organize-onedrive-para\Reorganize-OneDrive-PARA.ps1` -- legt diese Struktur an.
- Sortier-Agent: folgt in einem separaten Projekt.
- Daily-Briefing-Bot: folgt in einem separaten Projekt.
'@

$Template_NotfallKarte = @'
# NOTFALL-KARTE

Diese Datei ist absichtlich unverschluesselt. Sie soll Angehoerigen im
Ernstfall schnellen Zugriff auf die wichtigsten Informationen geben.

## Sofort-Zugriff (Kopien liegen in diesem Ordner)

- [ ] Patientenverfuegung (Kopie) -- Original im Tresor
- [ ] Vorsorgevollmacht (Kopie)   -- Original im Tresor
- [ ] Liste wichtiger Telefonnummern (Arzt, Anwalt, Notar, Steuerberater)
- [ ] Liste laufender Vertraege (Versicherungen, Bank)

## Tresor-Zugriff

- Speicherort:   `OneDrive\_Tresor\`
- Mount-App:     Cryptomator (im Startmenue)
- Master-Passwort hinterlegt:
  - Im Passwort-Manager (Bitwarden/1Password)
  - In versiegeltem Notfall-Umschlag bei: <NAME EINTRAGEN>

## Wichtige Personen

| Rolle | Name | Telefon |
|---|---|---|
| Hausarzt | | |
| Anwalt | | |
| Steuerberater | | |
| Notar | | |
| Hausverwaltung Muenchen | | |

## Wichtige Konten / Vertraege

(In Stichworten, ohne Kontonummern. Details im Tresor.)

- Hauptkonto (Privat):
- Sonderkonto Muenchen Dachauer 344:
- Versicherungen (Liste):
- Depots:

## Erste Schritte fuer Angehoerige

1. Hausarzt anrufen (siehe oben).
2. Patientenverfuegung an Krankenhaus uebergeben (liegt in diesem Ordner).
3. Bei laengerem Ausfall: Anwalt informieren, Vorsorgevollmacht aktivieren.
4. Tresor-Zugang aus Notfall-Umschlag holen, NICHT vorher oeffnen.
'@

$Template_RoutingRegeln = @'
# routing-regeln.yaml
# Regelbasierte Vor-Sortierung fuer den Eingangs-Agent.
# Patterns werden gegen den Dateinamen geprueft (Glob, case-insensitive).
# Erstes Match gewinnt. Kein Match -> Datei geht an den LLM-Agenten.

version: 1

regeln:
  - name: "Techem Heizkostenabrechnung"
    pattern: "*Techem*"
    ziel_kategorie: "Betriebskosten"
    ziel_immobilie: "Vermietung Muenchen_Dachauer344"
    anlage: "V"

  - name: "ista Heizkostenabrechnung"
    pattern: "*ista*"
    ziel_kategorie: "Betriebskosten"
    ziel_immobilie: "Vermietung Muenchen_Dachauer344"
    anlage: "V"

  - name: "Hausverwaltung WEG-Abrechnung"
    pattern: "*WEG*"
    ziel_kategorie: "Hausverwaltung"
    ziel_immobilie: "Vermietung Muenchen_Dachauer344"
    anlage: "V"

  - name: "Lohnzettel Wolfi"
    pattern: "*Lohnzettel*Wolfi*"
    ziel_kategorie: "Anlage_N_Wolfi"
    ziel_bereich: "Finanzen & Steuern/Steuern"

  - name: "Lohnzettel Daniela"
    pattern: "*Lohnzettel*Daniela*"
    ziel_kategorie: "Anlage_N_Daniela"
    ziel_bereich: "Finanzen & Steuern/Steuern"

  - name: "Versorger Hemhofen -- Strom"
    pattern: "*Stromrechnung*Hemhofen*"
    ziel_kategorie: "Versorger"
    ziel_immobilie: "Eigenheim Hemhofen"

# Hinweise:
# - "ziel_immobilie" matched gegen die Stammdaten in immobilien-stammdaten.yaml.
# - "anlage: V" bewirkt, dass der Agent zusaetzlich eine Beleg-Note
#   im Vault unter Steuern/<Jahr>/Anlage_V_<Immobilie> anlegt.
# - Wenn keine Regel matched, klassifiziert der LLM-Agent ueber OCR.
'@

$Template_HandwerkerStammdaten = @'
# handwerker-stammdaten.yaml
# Bekannte Firmen / Handwerker fuer automatische Kategorisierung.
# Aliase werden gegen den PDF-Text gematcht (case-insensitive substring).

version: 1

handwerker:
  - name: "Mueller Heizungsbau GmbH"
    aliase:
      - "Mueller Heizungsbau"
      - "Heizung Mueller"
      - "Mueller GmbH"
    gewerk: "Heizung"
    kategorie: "Instandhaltung"

  - name: "Bezirkskaminkehrer Huber"
    aliase:
      - "Schornsteinfeger Huber"
      - "Kaminkehrer Huber"
      - "Bezirkskaminkehrermeister"
    gewerk: "Kaminkehrer"
    kategorie: "Betriebskosten"

  - name: "Techem GmbH"
    aliase:
      - "Techem"
    gewerk: "Heizkostenabrechnung"
    kategorie: "Betriebskosten"

  - name: "ista Deutschland GmbH"
    aliase:
      - "ista"
    gewerk: "Heizkostenabrechnung"
    kategorie: "Betriebskosten"

# Hinweis:
# Der Sortier-Agent darf diese Liste selbst ergaenzen, wenn er einen
# neuen Absender mehrfach sieht. Vor dem ersten produktiven Einsatz
# einmal von Hand mit deinen tatsaechlichen Handwerkern befuellen.
'@

$Template_ImmobilienStammdaten = @'
# immobilien-stammdaten.yaml
# Identifikatoren fuer die drei Immobilien.
# Der Agent matched Adresse, IBAN, Mieter- oder HV-Namen aus dem
# PDF-Text gegen diese Liste, um eindeutig zu routen.

version: 1

immobilien:
  Vermietung_Muenchen_Dachauer344:
    nutzung: "vermietet"
    steuer_anlage: "V"
    adresse_pattern:
      - "Dachauer Str. 344"
      - "Dachauer Strasse 344"
      - "Dachauer Strasse 344"
      - "Dachauerstr. 344"
    plz: "80637"
    iban_sonderkonto: ""
    hausverwaltung:
      - ""
    mieter:
      - ""
    ziel_bereich: "02_Bereiche/Vermietung Muenchen_Dachauer344"

  Ferienwohnung_Marquartstein:
    nutzung: "eigennutzung"
    steuer_anlage: null
    adresse_pattern:
      - "Marquartstein"
      - "83250"
    plz: "83250"
    iban_sonderkonto: ""
    hausverwaltung: []
    mieter: []
    ziel_bereich: "02_Bereiche/Ferienwohnung Marquartstein"

  Eigenheim_Hemhofen:
    nutzung: "selbstgenutzt"
    steuer_anlage: "Haushaltsnahe"
    adresse_pattern:
      - "Hemhofen"
      - "91334"
    plz: "91334"
    iban_sonderkonto: ""
    hausverwaltung: []
    mieter: []
    ziel_bereich: "02_Bereiche/Eigenheim Hemhofen"

# Hinweis:
# - Eintraege mit leeren Strings vor dem ersten produktiven Lauf ausfuellen.
# - Mehrere Signale (Adresse + IBAN + Mieter) sollten zusammenpassen.
#   Bei Widerspruch -> Datei nach 00_Eingang/_unsicher/.
'@

$Template_PersonenStammdaten = @'
# personen-stammdaten.yaml
# Personen fuer automatische Zuordnung von Belegen.
# Wird vom Sortier-Agent und vom Briefing-Bot genutzt.

version: 1

familie:
  Wolfi:
    rolle: "Wolfi"
    geburtsjahr: ""
    versicherungsnummer_kk: ""
    steuerid: ""
  Daniela:
    rolle: "Ehepartnerin"
    versicherungsnummer_kk: ""
    steuerid: ""
  Paula:
    rolle: "Tochter"
    versicherungsnummer_kk: ""

mieter:
  - name: ""
    immobilie: "Vermietung_Muenchen_Dachauer344"
    mietzeit_von: ""
    mietzeit_bis: ""

aerzte:
  - name: ""
    fachrichtung: ""
    telefon: ""

anwaelte_steuerberater:
  - name: ""
    rolle: "Anwalt / Steuerberater"
    telefon: ""
    email: ""

# Hinweis:
# Sensitive Felder wie SteuerID und Versicherungsnummern haben
# Datenschutzbedarf. Wenn dir die Klartext-Ablage in OneDrive zu offen
# ist, leere Werte lassen und nur im Tresor pflegen.
'@

$Template_BelegIndex = @'
# Belege -- {IMMOBILIE} -- {JAHR}

Diese Datei kann der Sortier-Agent automatisch fuellen.
Manuell ergaenzbar.

| Datum | Kategorie | Firma | Betrag | Beleg |
|---|---|---|---|---|

## Summe Werbungskosten {JAHR}

Wird vom Agent berechnet.
'@

$Template_ObsidianSchema = @'
# Obsidian-Frontmatter-Schema

Stand: 1.0
Letzte Aenderung: siehe Datei-Datum.

## Zweck

Dieses Schema definiert, welche Frontmatter-Felder eine Beleg-Note im
Vault haben muss, damit Dataview-Queries und KI-Agenten konsistent
arbeiten koennen.

## Schema-Versionierung

Jede Note traegt das Feld `schema_version: 1.0`. Bei Migration auf 1.1
wird ein Migrations-Skript alle Notes anpassen.

## Pflichtfelder (alle Belege)

```yaml
---
schema_version: 1.0
typ: rechnung           # rechnung | beleg | mietvertrag | bescheid | sonstiges
datum: 2026-03-15
betrag: 1240.00
firma: "Mueller GmbH"
pfad: "02_Bereiche/.../2026-03-15_Heizung_Mueller_1240.pdf"
---
```

## Felder fuer Immobilien-Belege

```yaml
immobilie: Vermietung_Muenchen_Dachauer344
kategorie: Instandhaltung
gewerk: Heizung
jahr: 2026
anlage: V
```

## Felder fuer Steuer-Relevanz

```yaml
anlage: V
steuerjahr: 2026
abzugsfaehig: true
```

## Optional

```yaml
status: bezahlt
zahlungsdatum: 2026-03-20
tags: [beleg, heizung, anlageV]
```

## Beispiel-Note

```markdown
---
schema_version: 1.0
typ: rechnung
datum: 2026-03-15
betrag: 1240.00
firma: "Mueller Heizungsbau GmbH"
immobilie: Vermietung_Muenchen_Dachauer344
kategorie: Instandhaltung
gewerk: Heizung
jahr: 2026
anlage: V
steuerjahr: 2026
abzugsfaehig: true
status: bezahlt
pfad: "02_Bereiche/Vermietung Muenchen_Dachauer344/Instandhaltung/2026/2026-03-15_Heizung_Mueller_1240.pdf"
tags: [beleg, heizung, anlageV]
---

# Heizung Reparatur Dachauer 344

Pumpe defekt, Austausch + Spuelung.
```

## Dataview-Query: alle Anlage-V-Belege Muenchen 2026

```dataview
TABLE datum, kategorie, firma, betrag
FROM "02_Bereiche/Vermietung Muenchen_Dachauer344"
WHERE anlage = "V" AND jahr = 2026
SORT datum
```
'@

# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','PLAN','DO','SKIP','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"

    $color = switch ($Level) {
        'INFO'  { 'Gray' }
        'PLAN'  { 'Cyan' }
        'DO'    { 'Green' }
        'SKIP'  { 'Yellow' }
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red' }
    }
    Write-Host $line -ForegroundColor $color

    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $line -Encoding UTF8
    }
}

function Test-OneDriveRoot {
    param([string]$Path)
    if (-not $Path) {
        throw 'OneDrive-Pfad ist leer. Setze $env:OneDrive oder uebergib -OneDrivePath.'
    }
    if (-not (Test-Path $Path -PathType Container)) {
        throw "OneDrive-Pfad existiert nicht: $Path"
    }
    $marker = Join-Path $Path 'desktop.ini'
    if (-not (Test-Path $marker)) {
        Write-Log "Hinweis: kein desktop.ini in $Path gefunden. Trotzdem fortfahren." 'WARN'
    }
}

function Invoke-EnsureDir {
    param([string]$Path)
    if (Test-Path $Path) {
        Write-Log "Existiert bereits: $Path" 'SKIP'
        return $false
    }
    if ($Execute) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Log "Angelegt: $Path" 'DO'
    } else {
        Write-Log "WUERDE anlegen: $Path" 'PLAN'
    }
    return $true
}

function Invoke-EnsureFile {
    param(
        [string]$Path,
        [string]$Content
    )
    if (Test-Path $Path) {
        Write-Log "Datei existiert bereits, nicht ueberschrieben: $Path" 'SKIP'
        return $false
    }
    $parent = Split-Path $Path -Parent
    if ($parent -and -not (Test-Path $parent)) {
        if ($Execute) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
    }
    if ($Execute) {
        Set-Content -Path $Path -Value $Content -Encoding UTF8
        Write-Log "Datei geschrieben: $Path" 'DO'
    } else {
        Write-Log "WUERDE Datei schreiben: $Path" 'PLAN'
    }
    return $true
}

function Invoke-MoveDir {
    param(
        [string]$Source,
        [string]$Target
    )

    if (-not (Test-Path $Source)) {
        Write-Log "Quelle fehlt, uebersprungen: $Source" 'SKIP'
        return
    }

    if (Test-Path $Target) {
        Write-Log "Ziel existiert schon, NICHT ueberschrieben: $Source --> $Target" 'WARN'
        return
    }

    $parent = Split-Path $Target -Parent
    if ($parent -and -not (Test-Path $parent)) {
        if ($Execute) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
            Write-Log "Zwischenordner angelegt: $parent" 'DO'
        } else {
            Write-Log "WUERDE Zwischenordner anlegen: $parent" 'PLAN'
        }
    }

    if ($Execute) {
        try {
            Move-Item -LiteralPath $Source -Destination $Target -ErrorAction Stop
            Write-Log "Verschoben: $Source --> $Target" 'DO'
        } catch {
            Write-Log "Fehler beim Verschieben $Source --> $Target : $_" 'ERROR'
        }
    } else {
        Write-Log "WUERDE verschieben: $Source --> $Target" 'PLAN'
    }
}

function Show-Banner {
    $mode = if ($Execute) { 'AUSFUEHRUNG' } else { 'TROCKENLAUF' }
    Write-Host ''
    Write-Host '=============================================================' -ForegroundColor Cyan
    Write-Host "  OneDrive-PARA-Reorganisation -- Modus: $mode"               -ForegroundColor Cyan
    Write-Host "  Stamm : $OneDrivePath"                                       -ForegroundColor Cyan
    Write-Host "  Vault : $VaultName"                                          -ForegroundColor Cyan
    Write-Host "  Log   : $script:LogFile"                                     -ForegroundColor Cyan
    Write-Host '=============================================================' -ForegroundColor Cyan
    Write-Host ''
}

function Confirm-Execute {
    Write-Host ''
    Write-Host 'Bist du sicher, dass die obigen Aktionen ausgefuehrt werden sollen?' -ForegroundColor Yellow
    Write-Host 'Empfehlung: OneDrive-Sync auf diesem Geraet pausieren, andere Geraete schlafen lassen.' -ForegroundColor Yellow
    $answer = Read-Host 'Tippe JA zum Bestaetigen, alles andere bricht ab'
    return ($answer -eq 'JA')
}

# ---------------------------------------------------------------------------
# Lauf
# ---------------------------------------------------------------------------

$stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
if (-not $LogPath) {
    $logDir = Join-Path $OneDrivePath '_Logs'
    if (-not (Test-Path $logDir) -and $Execute) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $LogPath = Join-Path $logDir "reorganize-$stamp.txt"
}
$script:LogFile = $LogPath

try {
    Test-OneDriveRoot -Path $OneDrivePath
} catch {
    Write-Host "FEHLER: $_" -ForegroundColor Red
    exit 1
}

Show-Banner
Write-Log "Start. Execute=$Execute" 'INFO'

if ($Execute) {
    if (-not (Confirm-Execute)) {
        Write-Host 'Abgebrochen.' -ForegroundColor Red
        Write-Log 'Abgebrochen durch Benutzer.' 'INFO'
        exit 0
    }
}

# ===========================================================================
# Phase A: PARA-Wurzeln + System (top-level only, kollidiert nicht mit User)
# ===========================================================================
Write-Log '=== Phase A: PARA-Wurzeln + System ===' 'INFO'
foreach ($root in $ParaRoots) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $root) | Out-Null
}
foreach ($sub in $EingangSub) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $sub) | Out-Null
}

# ===========================================================================
# Phase B: Alte Top-Folder verschieben (Tier 1)
# Reihenfolge wichtig: erst Move, dann augmentieren, sonst Ziel-Kollision.
# ===========================================================================
Write-Log '=== Phase B: Alte Top-Folder verschieben ===' 'INFO'
foreach ($source in $Moves.Keys) {
    if ($Protected -contains $source) {
        Write-Log "Geschuetzt, wird nicht angefasst: $source" 'SKIP'
        continue
    }
    $src = Join-Path $OneDrivePath $source
    $dst = Join-Path $OneDrivePath $Moves[$source]
    Invoke-MoveDir -Source $src -Target $dst
}

# ===========================================================================
# Phase C: Aufteilungen (03_Beruf -> Wolfi/Daniela/Vortraege)
# ===========================================================================
Write-Log '=== Phase C: Aufteilungen ===' 'INFO'
foreach ($parent in $Splits.Keys) {
    $parentPath = Join-Path $OneDrivePath $parent
    if (-not (Test-Path $parentPath)) {
        Write-Log "Quelle fehlt, uebersprungen: $parent" 'SKIP'
        continue
    }
    foreach ($child in $Splits[$parent].Keys) {
        $src = Join-Path $parentPath $child
        $dst = Join-Path $OneDrivePath $Splits[$parent][$child]
        Invoke-MoveDir -Source $src -Target $dst
    }

    if ($Execute -and (Test-Path $parentPath)) {
        $rest = Get-ChildItem -LiteralPath $parentPath -Force | Where-Object {
            $_.Name -ne 'desktop.ini'
        }
        if (-not $rest) {
            try {
                Remove-Item -LiteralPath $parentPath -Force -Recurse -ErrorAction Stop
                Write-Log "Leeren Quellordner entfernt: $parentPath" 'DO'
            } catch {
                Write-Log "Konnte leeren Ordner nicht entfernen: $parentPath ($_)" 'WARN'
            }
        } else {
            Write-Log "Quellordner nicht leer, bleibt: $parentPath" 'SKIP'
        }
    }
}

# ===========================================================================
# Phase D: Augment -- fehlende Unterordner ergaenzen
# Ab hier sind alle Tier-1-Moves passiert. Wir ergaenzen Strukturen,
# ohne user-content zu ueberschreiben (EnsureDir skipped, wenn vorhanden).
# ===========================================================================
Write-Log '=== Phase D: Augment (fehlende Strukturen) ===' 'INFO'

# Projekt-Container
foreach ($sub in $ProjekteSub) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $sub) | Out-Null
}

# Familie, CoWork, Beruf, Vorsorge, Freizeit -- fehlende Subordner
foreach ($sub in $BereichSub) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $sub) | Out-Null
}

# Eigenheim Hemhofen (komplett neu)
foreach ($sub in $EigenheimSub) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $sub) | Out-Null
}
foreach ($base in $EigenheimYearly) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $base) | Out-Null
    foreach ($year in $BelegYears) {
        Invoke-EnsureDir -Path (Join-Path $OneDrivePath "$base\$year") | Out-Null
    }
}

# Ferienwohnung Marquartstein (komplett neu)
foreach ($sub in $FewoSub) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $sub) | Out-Null
}
foreach ($base in $FewoYearly) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $base) | Out-Null
    foreach ($year in $BelegYears) {
        Invoke-EnsureDir -Path (Join-Path $OneDrivePath "$base\$year") | Out-Null
    }
}

# Vermietung Muenchen_Dachauer344
# Nach Phase B existiert dieser Ordner mit dem User-Inhalt aus 04_Immobilien.
# Wir ergaenzen die Standard-Subordner (falls fehlend) und Jahres-Subordner.
# Hinweis: User-Subordner mit abweichenden Namen (z.B. "Bilder Dachauer Str. 344")
# bleiben unangetastet -- haendisch umbenennen, wenn gewuenscht.
foreach ($sub in $VermietungSub) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $sub) | Out-Null
}
foreach ($base in $VermietungYearly) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $base) | Out-Null
    foreach ($year in $BelegYears) {
        Invoke-EnsureDir -Path (Join-Path $OneDrivePath "$base\$year") | Out-Null
    }
}

# Finanzen
foreach ($sub in $FinanzenSub) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $sub) | Out-Null
}

# Steuern pro Jahr mit allen Anlagen
foreach ($year in $BelegYears) {
    foreach ($anlage in $SteuerAnlagen) {
        $p = "02_Bereiche\Finanzen & Steuern\Steuern\$year\$anlage"
        Invoke-EnsureDir -Path (Join-Path $OneDrivePath $p) | Out-Null
    }
}

# Ressourcen
foreach ($sub in $RessourcenSub) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $sub) | Out-Null
}

# Archiv-Slots
foreach ($sub in $ArchivSub) {
    Invoke-EnsureDir -Path (Join-Path $OneDrivePath $sub) | Out-Null
}

# ===========================================================================
# Phase E: Templates schreiben (Stammdaten, Schema, Notfall, README)
# ===========================================================================
Write-Log '=== Phase E: Templates schreiben ===' 'INFO'

# Stammdaten-YAMLs
$stammBase = Join-Path $OneDrivePath '03_Ressourcen\KI_Skills_und_Prompts'
Invoke-EnsureFile -Path (Join-Path $stammBase 'routing-regeln.yaml')         -Content $Template_RoutingRegeln           | Out-Null
Invoke-EnsureFile -Path (Join-Path $stammBase 'handwerker-stammdaten.yaml')  -Content $Template_HandwerkerStammdaten    | Out-Null
Invoke-EnsureFile -Path (Join-Path $stammBase 'immobilien-stammdaten.yaml')  -Content $Template_ImmobilienStammdaten    | Out-Null
Invoke-EnsureFile -Path (Join-Path $stammBase 'personen-stammdaten.yaml')    -Content $Template_PersonenStammdaten      | Out-Null

# Beleg-Index-Stubs Anlage V Muenchen je Jahr
foreach ($year in $BelegYears) {
    $indexPath = Join-Path $OneDrivePath `
        "02_Bereiche\Finanzen & Steuern\Steuern\$year\Anlage_V_Muenchen-Dachauer344\_Belege.md"
    $content = $Template_BelegIndex `
        -replace '\{IMMOBILIE\}', 'Muenchen Dachauer 344' `
        -replace '\{JAHR\}', $year
    Invoke-EnsureFile -Path $indexPath -Content $content | Out-Null
}

# Beleg-Index-Stubs Haushaltsnahe Hemhofen je Jahr
foreach ($year in $BelegYears) {
    $indexPath = Join-Path $OneDrivePath `
        "02_Bereiche\Finanzen & Steuern\Steuern\$year\Anlage_Haushaltsnahe_Hemhofen\_Belege.md"
    $content = $Template_BelegIndex `
        -replace '\{IMMOBILIE\}', 'Eigenheim Hemhofen (Haushaltsnahe)' `
        -replace '\{JAHR\}', $year
    Invoke-EnsureFile -Path $indexPath -Content $content | Out-Null
}

# Vault-Schema
$vaultPath = Join-Path $OneDrivePath $VaultName
if (Test-Path $vaultPath) {
    $schemaDir = Join-Path $vaultPath '99_Konfiguration'
    Invoke-EnsureDir -Path $schemaDir | Out-Null
    Invoke-EnsureFile `
        -Path (Join-Path $schemaDir 'obsidian-schema.md') `
        -Content $Template_ObsidianSchema | Out-Null
} else {
    Write-Log "Vault nicht gefunden ($vaultPath) -- Vault-Konfiguration uebersprungen." 'WARN'
}

# Notfall-Karte
Invoke-EnsureFile `
    -Path (Join-Path $OneDrivePath '02_Bereiche\Vorsorge & Notfall\Wichtig\NOTFALL-KARTE.md') `
    -Content $Template_NotfallKarte | Out-Null

# README im OneDrive-Stamm
Invoke-EnsureFile `
    -Path (Join-Path $OneDrivePath 'README.md') `
    -Content $Template_README | Out-Null

# ===========================================================================
# Phase F: Tier-2-Hinweise (manuelle Pruefung)
# ===========================================================================
Write-Log '=== Phase F: Manuelle Pruefung empfohlen ===' 'INFO'
foreach ($item in $ManualReview) {
    $p = Join-Path $OneDrivePath $item.Path
    if (Test-Path $p) {
        Write-Log "$($item.Path) -- $($item.Reason)" 'WARN'
    }
}

# ---------------------------------------------------------------------------
# Abschluss
# ---------------------------------------------------------------------------
Write-Log '--- Fertig ---' 'INFO'

if (-not $Execute) {
    Write-Host ''
    Write-Host 'Das war ein TROCKENLAUF. Es wurde nichts veraendert.' -ForegroundColor Cyan
    Write-Host 'Wenn die Vorschau gut aussieht, starte erneut mit -Execute.' -ForegroundColor Cyan
} else {
    Write-Host ''
    Write-Host 'Ausfuehrung beendet. Pruefe das Logfile:' -ForegroundColor Green
    Write-Host "  $script:LogFile" -ForegroundColor Green
    Write-Host 'OneDrive-Sync jetzt wieder aktivieren und einmal komplett durchlaufen lassen.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Naechste Schritte:' -ForegroundColor Cyan
    Write-Host '  1. Stammdaten-YAMLs unter 03_Ressourcen\KI_Skills_und_Prompts\ ausfuellen' -ForegroundColor Cyan
    Write-Host '  2. NOTFALL-KARTE.md unter Vorsorge & Notfall\Wichtig\ vervollstaendigen' -ForegroundColor Cyan
    Write-Host '  3. Cryptomator-Tresor in _Tresor\ anlegen (App startet, Speicherort waehlen)' -ForegroundColor Cyan
    Write-Host '  4. ScanSnap-Profile umstellen: Standard -> 00_Eingang\Scans\, Tresor -> X:\' -ForegroundColor Cyan
}
