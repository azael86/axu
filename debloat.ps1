# Debloat Samsung Galaxy S24 Ultra prin ADB (fara root) - Windows.
# Utilizare:  powershell -ExecutionPolicy Bypass -File debloat.ps1           -> elimina aplicatii
#             powershell -ExecutionPolicy Bypass -File debloat.ps1 -Restore  -> reinstaleaza tot ce a fost eliminat
param([switch]$Restore)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Dir = $PSScriptRoot
$Log = Join-Path $Dir 'eliminate.log'

# adb poate fi în PATH sau în folderul platform-tools de lângă script.
$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $adb) {
    foreach ($p in @("$Dir\adb.exe", "$Dir\platform-tools\adb.exe")) { if (Test-Path $p) { $adb = $p; break } }
}
if (-not $adb) { Write-Host "EROARE: nu găsesc adb. Pune adb.exe lângă script sau adaugă platform-tools în PATH." -ForegroundColor Red; exit 1 }

$state = (& $adb get-state 2>$null) -join ''
if ($state.Trim() -ne 'device') {
    Write-Host "EROARE: niciun telefon autorizat. Conectează-l prin USB, activează Depanare USB" -ForegroundColor Red
    Write-Host "și acceptă pe ecranul telefonului mesajul 'Permiteți depanarea USB?'."
    exit 1
}

if ($Restore) {
    if (-not (Test-Path $Log) -or -not (Get-Content $Log)) { Write-Host "Nu există nimic de restaurat."; exit 0 }
    Write-Host "Reinstalez aplicațiile din $Log ..."
    foreach ($pkg in Get-Content $Log) {
        if (-not $pkg.Trim()) { continue }
        $out = (& $adb shell cmd package install-existing $pkg 2>&1) -join ' '
        Write-Host "  $pkg -> $out"
    }
    Move-Item $Log "$Log.restaurat-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Write-Host "Gata."
    exit 0
}

function Ask($q) { $a = Read-Host "$q [d/N]"; return ($a -match '^[dDyY]$') }

$model = ((& $adb shell getprop ro.product.model) -join '').Trim()
Write-Host "Telefon detectat: $model"
if ($model -notlike 'SM-S928*') {
    if (-not (Ask "Atenție: listele sunt făcute pentru S24 Ultra (SM-S928*). Continui?")) { exit 0 }
}

$installed = @{}
foreach ($l in (& $adb shell pm list packages)) { $installed[($l -replace '^package:', '').Trim()] = $true }

$script:ok = 0; $script:fail = 0
function Remove-Pkg($pkg) {
    $out = ((& $adb shell pm uninstall -k --user 0 $pkg 2>&1) -join ' ').Trim()
    if ($out -like 'Success*') {
        Add-Content -Path $Log -Value $pkg
        Write-Host "    ✔ eliminat" -ForegroundColor Green; $script:ok++
    } else {
        Write-Host "    ✘ eșuat: $out" -ForegroundColor Yellow; $script:fail++
    }
}

function Load-List($file) {
    $items = @()
    foreach ($line in Get-Content -Encoding UTF8 (Join-Path $Dir "liste\$file")) {
        if (-not $line.Trim() -or $line.TrimStart().StartsWith('#')) { continue }
        $pkg = ($line -split '\s+')[0]
        $desc = if ($line -match '#\s*(.*)$') { $Matches[1] } else { '' }
        if ($installed.ContainsKey($pkg)) { $items += [pscustomobject]@{ Pkg = $pkg; Desc = $desc } }
    }
    return ,$items
}

Write-Host "`n=== 1/3  Sigur de eliminat ===" -ForegroundColor Cyan
$list = Load-List '1-sigur.txt'
if ($list.Count -eq 0) { Write-Host "Nimic de eliminat din această categorie." }
else {
    foreach ($i in $list) { Write-Host ("  - {0,-45} {1}" -f $i.Pkg, $i.Desc) }
    if (Ask "Elimin toate cele $($list.Count) aplicații de mai sus?") {
        foreach ($i in $list) { Write-Host "  $($i.Pkg)"; Remove-Pkg $i.Pkg }
    }
}

foreach ($f in @('2-optional-samsung.txt', '3-optional-google-microsoft.txt')) {
    Write-Host "`n=== $f (te întreb pentru fiecare) ===" -ForegroundColor Cyan
    $list = Load-List $f
    if ($list.Count -eq 0) { Write-Host "Nimic instalat din această categorie."; continue }
    foreach ($i in $list) { if (Ask "  Elimin $($i.Desc) ($($i.Pkg))?") { Remove-Pkg $i.Pkg } }
}

Write-Host "`nTerminat: $script:ok eliminate, $script:fail eșuate."
if ($script:ok -gt 0) { Write-Host "Lista e salvată în $Log. Pentru a le pune la loc rulează scriptul cu -Restore." }
Write-Host "Recomand o repornire a telefonului."
