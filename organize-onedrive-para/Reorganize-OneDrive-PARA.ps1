<#
.SYNOPSIS
    Ordnet deinen OneDrive-Stamm nach PARA neu (00_Eingang, 01_Projekte,
    02_Bereiche, 03_Ressourcen, 04_Archiv).

.DESCRIPTION
    Trockenlauf ist die Voreinstellung — nichts wird angefasst, alles wird
    nur angezeigt und protokolliert. Erst mit -Execute werden die Ordner
    tatsaechlich verschoben/umbenannt.

    Sicherheits-Regeln:
    - Vorhandene Zielordner werden nicht ueberschrieben (Skip mit Hinweis).
    - Windows-Spezialordner (Desktop, Dokumente, Bilder, Anlagen,
      Anwendungen) und der Obsidian-Vault (Schaur_Vault) werden nie
      angefasst.
    - Jede Aktion landet im Logfile.

.PARAMETER OneDrivePath
    Pfad zum OneDrive-Stamm. Standard: $env:OneDrive
    (oder C:\Users\<dein-name>\OneDrive).

.PARAMETER Execute
    Erst dieser Schalter fuehrt die Aktionen wirklich aus.

.PARAMETER LogPath
    Pfad zum Logfile. Standard: <OneDrive>\_reorganize-log-<Zeitstempel>.txt

.EXAMPLE
    .\Reorganize-OneDrive-PARA.ps1
    Zeigt nur an, was passieren wuerde.

.EXAMPLE
    .\Reorganize-OneDrive-PARA.ps1 -Execute
    Fuehrt die Reorganisation durch (mit Rueckfrage).

.NOTES
    Vor dem Lauf: OneDrive-Sync auf diesem Geraet pausieren, andere Geraete
    schlafen lassen. Nach dem Lauf: Sync wieder aktivieren und einmal voll
    durchlaufen lassen, bevor du an einem anderen Geraet weiterarbeitest.
#>

[CmdletBinding()]
param(
    [string]$OneDrivePath = $env:OneDrive,
    [switch]$Execute,
    [string]$LogPath
)

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

# Fuenf PARA-Ordner, die immer angelegt werden
$ParaRoots = @(
    '00_Eingang',
    '01_Projekte',
    '02_Bereiche',
    '03_Ressourcen',
    '04_Archiv'
)

# Tier-1-Verschiebungen: eindeutige Faelle.
# Schluessel = Quelle (relativ zum OneDrive-Stamm)
# Wert       = Ziel   (relativ zum OneDrive-Stamm)
$Moves = [ordered]@{
    '01_Inbox_Scans'  = '00_Eingang'
    '02_Dienst_Bw'    = '02_Bereiche\Bundeswehr Wolfi'
    '02_Steuern'      = '02_Bereiche\Finanzen & Steuern\Steuern'
    '04_Immobilien'   = '02_Bereiche\Immobilien Bestand'
    '05_Finanzen'     = '02_Bereiche\Finanzen & Steuern\Finanzen'
    '06_CoWork'       = '02_Bereiche\CoWork'
    '07_Familie'      = '02_Bereiche\Familie'
    '08_Vorsorge'     = '02_Bereiche\Vorsorge & Notfall'
    '09_Freizeit'     = '02_Bereiche\Freizeit'
    '10_Archiv'       = '04_Archiv'
    '!!!WICHTIGES'    = '02_Bereiche\Vorsorge & Notfall\Wichtig'
}

# Spezielle Aufteilungen: Quellordner enthaelt Unterordner, die jeweils
# woandershin sollen.
$Splits = @{
    '03_Beruf' = @{
        'Wolfi_Freistaat'   = '02_Bereiche\Beruf Wolfi'
        'Daniela_Freistaat' = '02_Bereiche\Beruf Daniela'
        'Vortraege_Grundbuch' = '02_Bereiche\Beruf Wolfi\Vortraege_Grundbuch'
    }
}

# Ordner, die niemals angefasst werden
$Protected = @(
    'Schaur_Vault',
    'Desktop',
    'Dokumente',
    'Bilder',
    'Anlagen',
    'Anwendungen',
    '.OneDrive'
)

# Tier-2-Faelle: nicht automatisch, nur am Ende auflisten
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

    # Farbe in der Konsole
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
    # Sanity-Check: typischer OneDrive-Marker
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

    # Elternverzeichnis des Ziels sicherstellen
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

# Logdatei vorbereiten
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
if (-not $LogPath) {
    $LogPath = Join-Path $OneDrivePath "_reorganize-log-$stamp.txt"
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

# Vor echter Ausfuehrung explizit bestaetigen lassen
if ($Execute) {
    if (-not (Confirm-Execute)) {
        Write-Host 'Abgebrochen.' -ForegroundColor Red
        Write-Log 'Abgebrochen durch Benutzer.' 'INFO'
        exit 0
    }
}

# Schritt 1: PARA-Wurzeln anlegen
Write-Log '--- Schritt 1: PARA-Wurzeln ---' 'INFO'
foreach ($root in $ParaRoots) {
    $full = Join-Path $OneDrivePath $root
    Invoke-EnsureDir -Path $full
}

# Schritt 2: Einfache Verschiebungen
Write-Log '--- Schritt 2: Eindeutige Verschiebungen ---' 'INFO'
foreach ($source in $Moves.Keys) {
    if ($Protected -contains $source) {
        Write-Log "Geschuetzt, wird nicht angefasst: $source" 'SKIP'
        continue
    }
    $src = Join-Path $OneDrivePath $source
    $dst = Join-Path $OneDrivePath $Moves[$source]
    Invoke-MoveDir -Source $src -Target $dst
}

# Schritt 3: Aufteilungen
Write-Log '--- Schritt 3: Aufteilungen ---' 'INFO'
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

    # Wenn der Quellordner nach allen Splits leer ist, kann er weg.
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

# Schritt 4: Tier-2-Hinweise (manuelle Pruefung)
Write-Log '--- Schritt 4: Manuelle Pruefung empfohlen ---' 'INFO'
foreach ($item in $ManualReview) {
    $p = Join-Path $OneDrivePath $item.Path
    if (Test-Path $p) {
        Write-Log "$($item.Path) -- $($item.Reason)" 'WARN'
    }
}

# Schritt 5: Zusammenfassung
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
}

