"""The composition of the devkits: what compose.py writes, and the rules every kit and feature of the repository must keep."""

import json
import re
import shutil
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
import compose  # noqa: E402

KITS = sorted(p.stem for p in (ROOT / "kits").glob("*.json"))
FEATURES = sorted(p.name for p in (ROOT / "features").iterdir() if p.is_dir())


@pytest.fixture
def copy(tmp_path):
    target = tmp_path / "devkits"
    shutil.copytree(ROOT, target, ignore=shutil.ignore_patterns(".git", "__pycache__", ".pytest_cache"))
    return target


@pytest.mark.parametrize("kit", KITS)
def test_every_kit_composes(kit):
    text = compose.compose(kit, ROOT, "abc1234")
    spec = json.loads((ROOT / "kits" / f"{kit}.json").read_text())
    assert text.startswith(f"# Devkit {kit}:") and "FROM docker.io/library/debian@sha256:" in text
    copies = re.findall(r"^COPY features/([a-z0-9-]+)/", text, re.M)
    assert copies == spec["features"]  # the order of the kit file is the order of the layers
    assert 'devkit.commit="abc1234"' in text and f'devkit.kit="{kit}"' in text and "USER 1000:1000" in text


@pytest.mark.parametrize("kit", KITS)
def test_the_hardening_comes_after_every_feature(kit):
    text = compose.compose(kit, ROOT)
    last_feature = max(m.start() for m in re.finditer(r"^RUN cd /tmp/devkit", text, re.M))
    assert last_feature < text.index("perm /6000") < text.index("useradd --uid 1000") < text.index("USER 1000:1000")
    assert "claude" not in text.lower().replace("not claude", "")


def test_the_output_is_stable():
    assert compose.compose("python", ROOT) == compose.compose("python", ROOT)


def test_a_changed_feature_changes_its_label(copy):
    before = re.search(r'devkit.feature.git="(\w+)"', compose.compose("python", copy)).group(1)
    (copy / "features" / "git" / "install.sh").write_text((copy / "features" / "git" / "install.sh").read_text() + "\n# changed\n")
    after = re.search(r'devkit.feature.git="(\w+)"', compose.compose("python", copy)).group(1)
    assert before != after


@pytest.mark.parametrize("feature", FEATURES)
def test_every_feature_is_well_formed(feature):
    meta = compose.feature(ROOT, feature)
    assert meta["id"] == feature and meta["description"]
    script = (ROOT / "features" / feature / "install.sh").read_text()
    assert script.startswith("#!/usr/bin/env bash") and "set -euo pipefail" in script
    assert not re.search(r"\|\s*(ba)?sh\b", script), "no 'download | sh'"
    commands = "\n".join(l for l in script.splitlines() if not l.lstrip().startswith(("#", "apt-get install")))
    if "network" not in meta:   # the one allowed exception is a feature that declares its network use (see test below)
        assert "curl" not in commands and "wget" not in commands, "packages come from the dated apt snapshot, not from the net"
    assert (ROOT / "features" / feature / "install.sh").stat().st_mode & 0o111


@pytest.mark.parametrize("kit", KITS)
def test_every_kit_is_well_formed(kit):
    spec = json.loads((ROOT / "kits" / f"{kit}.json").read_text())
    assert spec["description"] and compose.SNAPSHOT.fullmatch(spec["apt_snapshot"])
    assert len(spec["features"]) == len(set(spec["features"])) and set(spec["features"]) <= set(FEATURES)


def test_the_base_image_is_pinned_by_digest():
    assert compose.DIGEST.fullmatch(json.loads((ROOT / "base.json").read_text())["image"])


@pytest.mark.parametrize("change,message", [
    (lambda c: (c / "base.json").write_text(json.dumps({"image": "docker.io/library/debian:trixie-slim"})), "by digest"),
    (lambda c: (c / "kits" / "python.json").write_text(json.dumps({"apt_snapshot": "yesterday", "features": ["git"]})), "apt_snapshot"),
    (lambda c: (c / "kits" / "python.json").write_text(json.dumps({"apt_snapshot": "20261019T000000Z", "features": []})), "non-empty"),
    (lambda c: (c / "kits" / "python.json").write_text(json.dumps({"apt_snapshot": "20261019T000000Z", "features": ["git", "git"]})), "duplicates"),
    (lambda c: (c / "kits" / "python.json").write_text(json.dumps({"apt_snapshot": "20261019T000000Z", "features": ["nope"]})), "no install.sh"),
    (lambda c: (c / "kits" / "python.json").write_text("not json"), "not readable"),
    (lambda c: (c / "features" / "git" / "feature.json").write_text(json.dumps({"id": "other"})), "another id"),
])
def test_a_broken_kit_or_feature_is_refused_with_a_reason(copy, change, message):
    change(copy)
    with pytest.raises(compose.KitError, match=message):
        compose.compose("python", copy)


@pytest.mark.parametrize("name", ["../x", "A", "a b", "", "a" * 60])
def test_bad_kit_names_are_refused(name):
    with pytest.raises(compose.KitError):
        compose.compose(name, ROOT)


def test_the_command_line_prints_the_containerfile_or_an_error(capsys):
    assert compose.main(["python"]) == 0 and capsys.readouterr().out.startswith("# Devkit python:")
    assert compose.main(["nope"]) == 2 and "error" in capsys.readouterr().err


NETWORK_FEATURES = [f for f in FEATURES if "network" in json.loads((ROOT / "features" / f / "feature.json").read_text())]


@pytest.mark.parametrize("feature", NETWORK_FEATURES)
def test_a_feature_with_network_is_pinned_by_hash(feature):
    """The exception to 'Debian packages only' is narrow: named hosts, Python packages only with hashes, no curl/wget."""
    directory = ROOT / "features" / feature
    meta = json.loads((directory / "feature.json").read_text())
    assert isinstance(meta["network"], list) and meta["network"] and all(re.fullmatch(r"[a-z0-9.-]+", h) for h in meta["network"])
    script = (directory / "install.sh").read_text()
    code = "\n".join(l for l in script.splitlines() if not l.lstrip().startswith("#"))
    assert "curl" not in code and "wget" not in code
    for line in re.findall(r"pip\"? install[^\n]*", code):
        assert "--require-hashes" in line, f"pip install without --require-hashes: {line}"
    requirements = sorted(directory.glob("requirements*.txt"))
    assert requirements, "a feature that uses pip needs pinned requirements with hashes"
    for req in requirements:
        entries = re.findall(r"^([A-Za-z0-9_.-]+)==\S+ \\\n(?:    --hash=sha256:[0-9a-f]{64}(?: \\)?\n)+", req.read_text(), re.M)
        names = re.findall(r"^[A-Za-z0-9_.-]+==", req.read_text(), re.M)
        assert entries and len(entries) == len(names), f"{req.name}: every package needs == and sha256 hashes"
