# devkits

Container für die Software-Factory, die **alles Nötige schon enthalten** und im Lauf **nichts nachinstallieren**: ein Basis-Image plus Features, wie bei einer `devcontainer.json`, aber ohne fremde Registries und ohne Zusatzwerkzeug. Ergebnis ist ein Image mit fester ID, das ein Test- oder Build-Schritt der Factory ohne Netz benutzt.

Zusammenhang: Issue [#383](https://github.com/paul-fleischmann-com/ai-native-embedded-engineering/issues/383) und die Test-Profile (#335) im Repository `ai-native-embedded-engineering`.

## Aufbau

```
base.json                 Basis-Image, immer per Digest
features/<id>/            ein Baustein: feature.json (id, description, options) und install.sh (läuft einmal als root im Build)
kits/<name>.json          ein Devkit: description, apt_snapshot (Datum bei snapshot.debian.org), features (Liste, die Reihenfolge zählt)
scripts/compose.py        schreibt aus einem Kit das Containerfile (nur Text; gebaut wird in der Factory)
tests/                    prüft die Regeln für Kits und Features
```

Ein Kit sieht so aus:

```json
{
  "description": "ARM Cortex-M bare metal: gcc-arm-none-eabi mit newlib, CMake, Ninja und cppcheck",
  "apt_snapshot": "20261019T000000Z",
  "features": ["git", "build-essential", "cmake-ninja", "python3", "arm-none-eabi-gcc", "cppcheck"]
}
```

## Was `compose.py` daraus macht

```
python3 scripts/compose.py arm-none-eabi --commit "$(git rev-parse HEAD)"
```

- `FROM` das Basis-Image per Digest, dann die Paketquellen auf den **datierten Debian-Snapshot** des Kits gestellt: dasselbe Kit liefert immer dieselben Pakete.
- Je Feature eine Schicht (`COPY` und `bash install.sh`, danach Aufräumen).
- Zum Schluss die **Härtung** wie bei jedem Image der Factory: keine setuid-Bits, Benutzer `worker` (uid 1000), kein `claude`, kein Token.
- Je Feature ein Label mit der Prüfsumme seines Ordners und das Label `devkit.commit`: das Image sagt, woraus es gebaut wurde.

## Regeln (die Tests halten sie fest)

- Das Basis-Image steht per Digest, nie per Tag.
- Jedes `install.sh` beginnt mit `#!/usr/bin/env bash`, hat `set -euo pipefail`, und holt **nichts aus dem Netz außer Debian-Paketen** aus dem Snapshot (kein `curl`, kein `wget`, kein `| sh`). Ein Werkzeug von außen wird bewusst ins Repository übernommen und mit Prüfsumme festgehalten.
- Ein Kit hat mindestens ein Feature, keine doppelten, und jedes gibt es.
- Features haben einen Namen aus `a-z`, `0-9` und `-`.

## Neues Feature oder Kit

1. Ordner `features/<id>/` mit `feature.json` und `install.sh` anlegen (Vorlage: ein vorhandenes Feature).
2. Es in ein Kit unter `kits/` aufnehmen.
3. `python3 -m pytest -q tests` ausführen.
4. Pull Request; jedes `install.sh` läuft als root im Build und wird deshalb gelesen, bevor es gemergt wird.

## Bauen und benutzen

Gebaut wird **in der Factory** (`infra/factory-test/build-devkit.sh <Kit>`, folgt in #383, Paket 2) als Benutzer `factory-worker` mit rootless Podman. Das Skript gibt die Image-ID aus; sie wird im Control Room als Test-Profil eingetragen (Admin > Factory > Einstellungen (Server), `FACTORY_TEST_PROFILES`). Das Eintragen bleibt eine Entscheidung eines Menschen.

**Stand:** noch nie gebaut. Der erste Bau am Server kann an der Paketquelle (Snapshot-Datum, Schlüsselring) oder an einem Paketnamen scheitern; das wird dann hier korrigiert.

## Spiegel

Dieses Repository liegt auf GitHub (privat). Im Forgejo des Servers ist es ein **Pull-Spiegel**: Änderungen entstehen hier, der Server holt sie.
