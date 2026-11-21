# Debloat Samsung Galaxy S24 Ultra (fără root)

Scripturile scot aplicațiile preinstalate inutile prin ADB, cu `pm uninstall --user 0`.
Nu e nevoie de root, garanția rămâne valabilă, iar orice aplicație se poate pune la loc.

## Ce se elimină

| Listă | Ce conține | Cum se aplică |
|---|---|---|
| `liste/1-sigur.txt` | Bixby, AR Emoji/Zone, Samsung Kids, Members, TV Plus, Global Goals, telemetrie Samsung, Facebook, LinkedIn, Netflix, Google One/TV | confirmi o dată pentru toate |
| `liste/2-optional-samsung.txt` | Game Launcher, Rutine, Samsung Internet/Email/Calendar, Wallet, Pass, Health, SmartThings, Galaxy Store etc. | te întreabă pe rând |
| `liste/3-optional-google-microsoft.txt` | Meet, YouTube, Drive, Foto, Gmail, Maps, OneDrive, Office, Outlook, Spotify | te întreabă pe rând |

**Nu se ating niciodată:** Google Play Services, Play Store, launcher-ul (One UI Home), tastatura,
Telefon/Mesaje/Contacte, Camera, Galeria, Setările, Knox/Secure Folder, S Pen (Air Command, Samsung Notes),
Galaxy AI. Poți edita listele: o linie = `pachet # descriere`. Ca să excluzi o linie, pune `#` în față.

## Pași

1. **Pe telefon:** Setări → Despre telefon → Informații software → apasă de 7 ori pe *Număr versiune*.
   Apoi Setări → Opțiuni dezvoltator → activează **Depanare USB**.
2. **Pe calculator:** descarcă [Android SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools)
   și dezarhivează-l. Pune folderul `platform-tools` lângă scripturi (sau adaugă-l în PATH).
3. Conectează telefonul prin cablu și acceptă pe ecran *„Permiteți depanarea USB?”*.
4. Rulează:
   - **Windows:** click dreapta în folder → *Deschide în Terminal*, apoi
     `powershell -ExecutionPolicy Bypass -File .\debloat.ps1`
   - **macOS / Linux:** `./debloat.sh`
5. Repornește telefonul.

## Restaurare

Tot ce a fost eliminat se salvează în `eliminate.log`. Pentru a pune totul la loc:

- Windows: `powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -Restore`
- macOS / Linux: `./debloat.sh restore`

O singură aplicație: `adb shell cmd package install-existing <pachet>`.
Un reset din fabrică readuce și el toate aplicațiile.

## Notă

După un update major de One UI, unele aplicații pot reveni. Rulează din nou scriptul.
