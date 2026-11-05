# Changelog

## 1.0 – 2026-11-05

Erste veröffentlichte Fassung. Vorher gab es nur Entwicklungsstände ohne
Release-Nummer; deren Änderungen sind hier zusammengefasst.

- CPU-Balken je Kern aus `mpstat -P ALL 1 1`, daneben Tasks, Load avg und Uptime.
- Mem und Swap mit Balken wie die CPU-Zeilen: Prozentwerte aus `free -b`,
  lesbare Grösse aus `free -h`. Beide erscheinen auch, wenn `mpstat` fehlt.
- Prozessliste nach `%CPU`, die zehn stärksten Prozesse.
- `LC_ALL=C` für `mpstat` und `free -b`, weil eine deutsche Locale `25,00`
  liefert und `awk` davon stillschweigend nur `25` lesen würde.
- Prozess- und Running-Zahl über `ps --no-headers` und `$1 ~ /^R/`, damit die
  Kopfzeile nicht mitgezählt und nicht jedes `R` in einem Namen getroffen wird.
- Fehlt `mpstat`, wird das auf stderr gemeldet, statt stumm nichts anzuzeigen.
- `install.sh` prüft die Abhängigkeiten (`bash`, `awk`, `procps`, `sysstat`) und
  installiert fehlende Pakete per `apt-get`. `--check` prüft nur, ohne etwas zu
  ändern. Am Ende Nachkontrolle und ein Lauf von `vatop.sh` als Selbsttest.
- Lizenz AGPL-3.0-or-later (`LICENSE`, SPDX-Kopf in beiden Skripten).
- README zweisprachig: `README.md` englisch (zeigt GitHub standardmässig an),
  `README.ger.md` deutsch, gegenseitig verlinkt.
