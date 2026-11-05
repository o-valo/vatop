#!/usr/bin/env bash
# vatop - Shell-Snapshot von CPU, Speicher und Top-Prozessen
# Copyright (C) 2026 Olav Surawski (o-valo)
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Dieses Programm ist freie Software: Sie koennen es unter den Bedingungen
# der GNU Affero General Public License, Version 3 oder spaeter,
# weitergeben und/oder veraendern. Es kommt ohne jede Gewaehrleistung.
# Volltext: LICENSE.
# Version: 1.0
#
# 04.11.2026 - Reparatur. Drei Fehler, einer davon mit Totalausfall:
#   1. `-v load=...` kollidiert mit dem gawk-Builtin load() -> "fatal: cannot use
#      gawk builtin `load' as variable name". awk brach ab, bevor eine Zeile
#      geschrieben war; top.txt begann mit einer Leerzeile, der CPU-Block fehlte
#      komplett. Variable heisst jetzt ldavg.
#   2. mpstat lief in der Systemsprache und lieferte "25,00". awk rechnet das
#      stillschweigend als 25 weiter (bleibt am Komma stehen). Jetzt LC_ALL=C,
#      damit der Punkt der Dezimaltrenner ist.
#   3. PROC_COUNT zaehlte die ps-Kopfzeile mit (195 statt 194), RUN_COUNT traf
#      mit grep 'R' auch andere Treffer. Beides jetzt ueber --no-headers und
#      einen Anker auf den Prozesszustand.
#   4. Mem und Swap bekommen Balken wie die CPU-Zeilen. Die
#      Prozentwerte kommen aus `free -b` (Bytes), weil `free -h` nur "1,2Gi"
#      liefert und sich daraus nichts rechnen laesst. Die Klammern stehen
#      dadurch auf derselben Spalte wie bei den CPUs.

{
  # 1. Systemdaten ermitteln
  UPTIME_STR=$(uptime -p | sed 's/^up //')
  LOAD_STR=$(uptime | sed 's/.*load average:[[:space:]]*//')
  PROC_COUNT=$(ps ax -o state --no-headers | wc -l)
  RUN_COUNT=$(ps ax -o state --no-headers | awk '$1 ~ /^R/' | wc -l)

  # RAM & Swap: Groesse in -h fuer die Anzeige, Prozent aus -b zum Rechnen.
  MEM_LINE=$(free -h | awk '/^Mem:/ { printf "%s / %s", $3, $2 }')
  SWAP_LINE=$(free -h | awk '/^Swap:/ { printf "%s / %s", $3, $2 }')
  MEM_PCT=$(LC_ALL=C free -b | awk '/^Mem:/ { if ($2 > 0) printf "%.1f", $3 / $2 * 100; }')
  SWAP_PCT=$(LC_ALL=C free -b | awk '/^Swap:/ { if ($2 > 0) printf "%.1f", $3 / $2 * 100; else printf "0.0" }')

  # 2. mpstat ausfuehren und CPU-Kerne + rechte Seite sauber mappen
  if command -v mpstat >/dev/null 2>&1; then
    LC_ALL=C mpstat -P ALL 1 1
  else
    echo "mpstat fehlt - bitte 'sudo apt install sysstat' installieren" >&2
  fi | awk -v uptime="$UPTIME_STR" -v ldavg="$LOAD_STR" -v tasks="$PROC_COUNT" \
           -v running="$RUN_COUNT" -v mem="$MEM_LINE" -v swap="$SWAP_LINE" \
           -v mempct="${MEM_PCT:-0}" -v swappct="${SWAP_PCT:-0}" '
    # Ein Balken aus "|", 20 Zeichen = 100 %, ein Zeichen = 5 %.
    function bar(pct,   n, s, k) {
      n = int(pct / 5 + 0.5);
      if (n > 20) n = 20;
      if (n < 0) n = 0;
      s = "";
      for (k = 0; k < n; k++) s = s "|";
      return s;
    }

    /^Average:/ { next }
    $2 ~ /^[0-9]+$/ {
      # jeder neue Messblock beginnt bei CPU 0 -> vorherige Werte verwerfen
      if ($2 == "0") { delete cpus; i = 0 }
      cpus[i++] = $2 " " $3 " " $4 " " $5;
    }
    END {
      for (j = 0; j < i; j++) {
        split(cpus[j], fields);
        cpu = fields[1];
        usr = fields[2] + fields[3];
        sys = fields[4];
        total = usr + sys;

        left = sprintf("%-7s[%-20s] %5.1f%%", "CPU " cpu, bar(total), total);

        # Rechte Seite htop-like fuer die ersten Zeilen
        right = "";
        if (j == 0)      right = sprintf("Tasks: %s total, %s running", tasks, running);
        else if (j == 1) right = sprintf("Load avg: %s", ldavg);
        else if (j == 2) right = sprintf("Uptime: %s", uptime);

        printf "%s    %s\n", left, right;
      }

      printf "%-7s[%-20s] %5.1f%%    %s\n", "Mem",  bar(mempct),  mempct,  mem;
      printf "%-7s[%-20s] %5.1f%%    %s\n", "Swap", bar(swappct), swappct, swap;
    }
  '

  echo ""
  ps -eo pid,psr,user,%cpu,%mem,comm --sort=-%cpu | head -n 20
} | tee top.txt

#EOF
