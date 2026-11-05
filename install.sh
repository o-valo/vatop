#!/usr/bin/env bash
# vatop - Installer: prueft die Abhaengigkeiten und installiert, was fehlt
# Copyright (C) 2026 Olav Surawski (o-valo)
# SPDX-License-Identifier: AGPL-3.0-or-later
# Volltext: LICENSE
# Version: 1.0
#
# Aufruf:
#   ./install.sh            pruefen, Fehlendes installieren (fragt nach sudo)
#   ./install.sh --check    nur pruefen, nichts aendern
#   ./install.sh -h         diese Hilfe

set -u

NUR_PRUEFEN=0
for arg in "$@"; do
  case "$arg" in
    --check)   NUR_PRUEFEN=1 ;;
    -h|--help) sed -n '/^# Aufruf:/,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)         printf 'Unbekannte Option: %s\nAufruf: %s [--check|-h]\n' "$arg" "$0" >&2; exit 2 ;;
  esac
done

# Werkzeug:Paket:Zweck
LISTE=(
  "bash:bash:Shell"
  "awk:gawk:Auswertung der Messwerte"
  "ps:procps:Prozessliste"
  "free:procps:Speicher und Swap"
  "uptime:procps:Laufzeit"
  "mpstat:sysstat:CPU-Auslastung je Kern"
  "tee:coreutils:Ausgabe nach top.txt"
)

FEHLEND=()
FEHLT_NR=0

vormerken() {
  local p="$1" x
  for x in ${FEHLEND[@]+"${FEHLEND[@]}"}; do
    [ "$x" = "$p" ] && return
  done
  FEHLEND+=("$p")
}

durchlauf() {
  local e werkzeug paket zweck
  FEHLEND=()
  FEHLT_NR=0
  for e in "${LISTE[@]}"; do
    IFS=: read -r werkzeug paket zweck <<<"$e"
    if command -v "$werkzeug" >/dev/null 2>&1; then
      printf '  vorhanden  %-7s  %s\n' "$werkzeug" "$zweck"
    else
      printf '  FEHLT      %-7s  %s  (Paket: %s)\n' "$werkzeug" "$zweck" "$paket"
      FEHLT_NR=$((FEHLT_NR + 1))
      vormerken "$paket"
    fi
  done
}

echo "vatop - Abhaengigkeiten pruefen"
durchlauf
echo

if [ "$FEHLT_NR" -eq 0 ]; then
  echo "Alles da, vatop.sh kann laufen."
  exit 0
fi

if [ "$NUR_PRUEFEN" -eq 1 ]; then
  echo "Es fehlt: ${FEHLEND[*]}"
  echo "Ohne --check wird das installiert."
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "Es fehlt: ${FEHLEND[*]}"
  echo "apt-get gibt es hier nicht, bitte mit dem eigenen Paketmanager installieren:"
  echo "  Fedora/RHEL:  sudo dnf install ${FEHLEND[*]}"
  echo "  Arch:         sudo pacman -S ${FEHLEND[*]}"
  exit 1
fi

echo "Installiere: ${FEHLEND[*]}"
sudo apt-get update -qq || { echo "apt-get update fehlgeschlagen." >&2; exit 1; }
# shellcheck disable=SC2086  # bewusst ohne Anfuehrungszeichen: mehrere Pakete
sudo apt-get install -y ${FEHLEND[*]} || { echo "Installation fehlgeschlagen." >&2; exit 1; }
echo

# Nachkontrolle: derselbe Durchlauf noch einmal
echo "vatop - Nachkontrolle"
durchlauf
echo

if [ "$FEHLT_NR" -ne 0 ]; then
  echo "Immer noch nicht alles vorhanden. Bitte oben die Meldungen lesen." >&2
  exit 1
fi

# Selbsttest, wenn das Skript daneben liegt
if [ -x ./vatop.sh ]; then
  echo "Selbsttest (./vatop.sh, erste zwei Zeilen):"
  ./vatop.sh | sed -n '1,2p'
fi

echo "Fertig."
