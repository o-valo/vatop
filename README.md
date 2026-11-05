<p align="center">
  <img src="vatop.jpg" alt="Vatop in action" width="100%">
</p>

# vatop

- Language: English | [Deutsche Fassung](README.ger.md)

An htop-like view of CPU, memory and the busiest processes — but as a **one-shot
run** instead of a full-screen application. `vatop` prints a finished text block,
writes it to `top.txt` and exits. That makes the output greppable, collectable
over `ssh` and usable in cron or monitoring.

The name: **va** from *o-valo*, **top** from `top` — "valo's top".

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

## Why not htop?

`htop` needs a terminal, draws a full screen and runs until someone presses `q`.
For "how is this box doing right now?" that is awkward: in a script, over `ssh`
or from a cron job there is no keyboard. `vatop` does exactly one measuring run,
prints text and is done.

| | htop | vatop |
|---|---|---|
| Interaction | keyboard, full screen | none, one call |
| Output | screen | stdout + `top.txt` |
| Duration | until `q` | ~1 second |
| In pipelines | no | yes (`grep`, `awk`, `ssh`) |

## Requirements

- `bash`
- `awk` (`gawk` or `mawk`)
- `procps` (`ps`, `free`, `uptime`)
- `sysstat` for `mpstat` — on Debian/Ubuntu: `sudo apt install sysstat`

If `mpstat` is missing the script says so on stderr; memory and swap are shown
anyway. `./install.sh` checks this list and installs what is missing.

## Installation

```bash
git clone https://github.com/o-valo/vatop.git
cd vatop
./install.sh          # checks the dependencies, installs what is missing
./vatop.sh
```

`./install.sh --check` only checks and changes nothing. The installer needs
`sudo` only for missing packages; if everything is present it does nothing. The
files come with the executable bit set from the repository, no `chmod` needed.

`vatop.sh` is a single shell script without dependencies apart from the system
tools above; the script itself needs no root. `install.sh` is there for
convenience only and can just as well be left out.

## Usage

```bash
./vatop.sh                  # output on stdout, additionally in top.txt
./vatop.sh | grep '^Mem'    # memory line only
ssh host ./vatop.sh         # collect over ssh
```

## Cron

`vatop` overwrites `top.txt` on every run. If you need history, append yourself:

```cron
*/5 * * * * cd /var/log && /home/bot/vatop.sh >> /var/log/vatop.log 2>&1
```

## How the numbers are calculated

- **CPU:** `mpstat -P ALL 1 1`, i.e. a one-second measuring window. The bar shows
  `%usr + %nice + %sys`; `%idle` and `%iowait` are not included. The `Average:`
  block from `mpstat` is skipped so that no mixed values end up in the core list.
- **Bars:** 20 characters = 100 %, one character = 5 %, rounded half up.
- **Mem/Swap:** percentages from `LC_ALL=C free -b` (bytes, computable), the
  readable size from `free -h`. `LC_ALL=C` is needed because `mpstat` under a
  German locale returns `25,00` and `awk` would silently read only `25`.

## Limits

- No history, no colours, no full screen — deliberately.
- "Tasks total" is a few processes higher than measured from outside, because
  `bash`, `awk`, `tee`, `mpstat` and `ps` count themselves. `htop` does the same.
- Tested on Debian/Ubuntu with `gawk`. `mawk` should work but has not been
  cross-checked.

## License

AGPL-3.0-or-later — see [LICENSE](LICENSE).

## Powered by AI

This project was developed with the support of AI-assisted tools for the code
changes and the documentation. The code, the tests and the architecture
decisions come from a human accountable person; the project is accordingly
responsible for any errors that remain.

The models used are not named. The tools used have no influence on the license:
the project remains under AGPL-3.0-or-later (see license).
