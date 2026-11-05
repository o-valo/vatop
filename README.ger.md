<p align="center">
  <img src="vatop.jpg" alt="Vatop in Action " width="100%">
</p>




# vatop

- Sprache: Deutsch | [English version](README.md)

Ein htop-artiger Blick auf CPU, Speicher und die stärksten Prozesse — aber als
**einmaliger Lauf** statt als Vollbild-Anwendung. `vatop` gibt einen fertigen
Textblock aus, schreibt ihn nach `top.txt` und beendet sich. Dadurch ist die
Ausgabe greppbar, per `ssh` einsammelbar und in Cron oder Monitoring verwendbar.

Der Name: **va** von *o-valo*, **top** von `top` — also „valos top“.

```
CPU 0  [|||                 ]  15.3%    Tasks: 201 total, 2 running
CPU 1  [|||||||||           ]  46.5%    Load avg: 1,11, 0,69, 0,47
CPU 2  [|||                 ]  12.5%    Uptime: 4 days, 8 hours, 18 minutes
CPU 3  [||                  ]   9.3%
Mem    [||||||              ]  32.2%    1,2Gi / 3,8Gi
Swap   [|                   ]   4.8%    182Mi / 3,8Gi

    PID PSR USER     %CPU %MEM COMMAND
 807001   2 bot      55.6  1.8 freebuff
 806965   3 bot       4.2  0.8 python3
```

## Warum nicht htop?

`htop` braucht ein Terminal, zeichnet Vollbild und läuft, bis jemand `q` drückt.
Für „wie steht die Kiste gerade da?" ist das umständlich: in einem Skript, über
`ssh` oder aus einem Cron-Job gibt es keine Tastatur. `vatop` macht genau
einen Messlauf, gibt Text aus und ist fertig.

| | htop | vatop |
|---|---|---|
| Bedienung | Tastatur, Vollbild | keine, ein Aufruf |
| Ausgabe | Bildschirm | stdout + `top.txt` |
| Dauer | bis `q` | ~1 Sekunde |
| In Pipelines | nein | ja (`grep`, `awk`, `ssh`) |

## Voraussetzungen

- `bash`
- `awk` (`gawk` oder `mawk`)
- `procps` (`ps`, `free`, `uptime`)
- `sysstat` für `mpstat` — unter Debian/Ubuntu: `sudo apt install sysstat`

Fehlt `mpstat`, sagt das Skript es auf stderr; Mem und Swap werden trotzdem
angezeigt. `./install.sh` prüft diese Liste und installiert, was fehlt.

## Installation

```bash
git clone https://github.com/o-valo/vatop.git
cd vatop
./install.sh          # prüft die Abhängigkeiten, installiert Fehlendes
./vatop.sh
```

`./install.sh --check` prüft nur und ändert nichts. Der Installer braucht nur
für fehlende Pakete `sudo`; ist alles vorhanden, tut er nichts. Die Dateien
kommen mit gesetztem Ausführungsrecht aus dem Repo, ein `chmod` ist nicht nötig.

`vatop.sh` ist ein einzelnes Shell-Skript ohne Abhängigkeiten ausser den obigen
Systemwerkzeugen; das Skript selbst braucht kein Root. `install.sh` ist nur zur
Bequemlichkeit da und lässt sich genauso gut weglassen.

## Aufruf

```bash
./vatop.sh                  # Ausgabe auf stdout, zusätzlich in top.txt
./vatop.sh | grep '^Mem'    # nur die Speicherzeile
ssh host ./vatop.sh         # über ssh einsammeln
```

## Cron

`vatop` überschreibt `top.txt` bei jedem Lauf. Wer den Verlauf braucht, hängt
selbst an:

```cron
*/5 * * * * cd /var/log && /home/bot/vatop.sh >> /var/log/vatop.log 2>&1
```

## Wie gerechnet wird

- **CPU:** `mpstat -P ALL 1 1`, also ein Messfenster von einer Sekunde. Der
  Balken zeigt `%usr + %nice + %sys`; `%idle` und `%iowait` stecken nicht darin.
  Der `Average:`-Block von `mpstat` wird übersprungen, damit keine Mischwerte in
  die Kernliste geraten.
- **Balken:** 20 Zeichen = 100 %, ein Zeichen = 5 %, kaufmännisch gerundet.
- **Mem/Swap:** Prozentwerte aus `LC_ALL=C free -b` (Bytes, rechenbar), die
  lesbare Grösse aus `free -h`. `LC_ALL=C` ist nötig, weil `mpstat` in einer
  deutschen Locale `25,00` liefert und `awk` davon stillschweigend nur `25`
  lesen würde.

## Grenzen

- Keine Historie, keine Farben, kein Vollbild — bewusst.
- „Tasks total" ist aus dem Skript heraus um einige Prozesse höher als von
  aussen gemessen, weil `bash`, `awk`, `tee`, `mpstat` und `ps` sich selbst
  mitzählen. `htop` macht es genauso.
- Getestet unter Debian/Ubuntu mit `gawk`. `mawk` sollte funktionieren, ist
  aber nicht gegengeprüft.

## Lizenz

AGPL-3.0-or-later — siehe [LICENSE](LICENSE).

## Powered by AI

Dieses Projekt wurde mit Unterstützung KI-gestützter Werkzeuge 
für die Codeänderungen und die Dokumentation entwickelt. Der 
Code, die Tests und die Architekturentscheidungen stammen von 
einer menschlich verantwortlichen Person; für verbleibende 
Fehler ist entsprechend das Projekt verantwortlich.

Die eingesetzten Modelle werden nicht namentlich genannt. Die 
verwendeten Werkzeuge haben keinen Einfluss auf die Lizenz: Das 
Projekt steht weiterhin unter AGPL-3.0-or-later (siehe Lizenz).
