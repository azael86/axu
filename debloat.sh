#!/usr/bin/env bash
# Debloat Samsung Galaxy S24 Ultra prin ADB (fără root).
# Utilizare:  ./debloat.sh            -> elimină aplicații (interactiv)
#             ./debloat.sh restore    -> reinstalează tot ce a fost eliminat
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$DIR/eliminate.log"

command -v adb >/dev/null 2>&1 || { echo "EROARE: 'adb' nu este instalat sau nu e în PATH."; exit 1; }
if [ "$(adb get-state 2>/dev/null)" != "device" ]; then
  echo "EROARE: niciun telefon autorizat. Conectează-l prin USB, activează Depanare USB"
  echo "și acceptă pe ecranul telefonului mesajul 'Permiteți depanarea USB?'."
  exit 1
fi

if [ "${1:-}" = "restore" ]; then
  [ -s "$LOG" ] || { echo "Nu există nimic de restaurat ($LOG lipsește sau e gol)."; exit 0; }
  echo "Reinstalez aplicațiile din $LOG ..."
  while read -r pkg; do
    [ -n "$pkg" ] || continue
    out=$(adb shell cmd package install-existing "$pkg" 2>&1 | tr -d '\r')
    echo "  $pkg -> $out"
  done < "$LOG"
  mv "$LOG" "$LOG.restaurat-$(date +%Y%m%d-%H%M%S)"
  echo "Gata."
  exit 0
fi

model=$(adb shell getprop ro.product.model | tr -d '\r')
echo "Telefon detectat: $model"
case "$model" in
  SM-S928*) ;;
  *) read -r -p "Atenție: listele sunt făcute pentru S24 Ultra (SM-S928*). Continui? [d/N] " a
     [[ "$a" =~ ^[dDyY]$ ]] || exit 0 ;;
esac

installed=$(adb shell pm list packages | tr -d '\r' | sed 's/^package://')
is_installed() { grep -qxF "$1" <<<"$installed"; }

ok=0; fail=0
remove() {
  local out
  out=$(adb shell pm uninstall -k --user 0 "$1" 2>&1 | tr -d '\r')
  if [[ "$out" == Success* ]]; then
    echo "$1" >> "$LOG"; echo "    ✔ eliminat"; ok=$((ok+1))
  else
    echo "    ✘ eșuat: $out"; fail=$((fail+1))
  fi
}

# Încarcă o listă: doar pachetele instalate efectiv pe telefon.
load() {
  PKGS=(); DESCS=()
  while IFS= read -r line; do
    line="${line%%$'\r'}"
    [[ -z "${line// }" || "$line" == \#* ]] && continue
    local pkg desc
    pkg=$(awk '{print $1}' <<<"$line")
    desc=$(sed -n 's/^[^#]*#[[:space:]]*//p' <<<"$line")
    is_installed "$pkg" && { PKGS+=("$pkg"); DESCS+=("$desc"); }
  done < "$1"
}

echo
echo "=== 1/3  Sigur de eliminat ==="
load "$DIR/liste/1-sigur.txt"
if [ ${#PKGS[@]} -eq 0 ]; then
  echo "Nimic de eliminat din această categorie."
else
  for i in "${!PKGS[@]}"; do printf "  - %-45s %s\n" "${PKGS[$i]}" "${DESCS[$i]}"; done
  read -r -p "Elimin toate cele ${#PKGS[@]} aplicații de mai sus? [d/N] " a
  if [[ "$a" =~ ^[dDyY]$ ]]; then
    for i in "${!PKGS[@]}"; do echo "  ${PKGS[$i]}"; remove "${PKGS[$i]}"; done
  fi
fi

for f in 2-optional-samsung 3-optional-google-microsoft; do
  echo
  echo "=== ${f} (te întreb pentru fiecare) ==="
  load "$DIR/liste/$f.txt"
  [ ${#PKGS[@]} -eq 0 ] && { echo "Nimic instalat din această categorie."; continue; }
  for i in "${!PKGS[@]}"; do
    read -r -p "  Elimin ${DESCS[$i]} (${PKGS[$i]})? [d/N] " a
    [[ "$a" =~ ^[dDyY]$ ]] && remove "${PKGS[$i]}"
  done
done

echo
echo "Terminat: $ok eliminate, $fail eșuate."
[ $ok -gt 0 ] && echo "Lista e salvată în $LOG. Pentru a le pune la loc: ./debloat.sh restore"
echo "Recomand o repornire a telefonului."
