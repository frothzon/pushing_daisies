#!/usr/bin/env python3
"""Switch this project between the installed Windows GameMaker and Linux beta.

Run from any directory:
    python switch_gamemaker_version.py
    python switch_gamemaker_version.py windows --dry-run
    python switch_gamemaker_version.py linux-beta

The project must be closed in GameMaker before applying a switch.
"""

from __future__ import annotations

import argparse
import difflib
import hashlib
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent

TARGETS = {
    "windows": {
        "label": "Windows installed GameMaker 2024.14.4.222",
        "ide_version": "2024.14.4.222",
        "extension_record": "v0",
    },
    "linux-beta": {
        "label": "Linux beta GameMaker 2026.100.0.1139",
        "ide_version": "2026.100.0.1139",
        "extension_record": "v1",
    },
}

# These are the two extension records that differed between the IDE versions.
EXTENSION_FILES = (
    ("extensions/Simple_Game_Engine/Simple_Game_Engine.yy", "Simple_Game_Engine"),
    ("extensions/Static_Inventory/Static_Inventory.yy", "Static_Inventory"),
)


class SwitchError(RuntimeError):
    """A safe switch cannot be completed with the project in its current state."""


def load_gm_json() -> Any:
    """Load the repository's lossless GameMaker JSON parser."""
    tools_path = ROOT / "python_tools"
    if not (tools_path / "gm" / "yy.py").is_file():
        raise SwitchError("python_tools/gm/yy.py was not found beside this script.")
    sys.path.insert(0, str(tools_path))
    try:
        from gm import yy
    except ImportError as exc:
        raise SwitchError(f"Could not load the project parser: {exc}") from exc
    return yy


def find_project_file() -> Path:
    projects = sorted(ROOT.glob("*.yyp"))
    if len(projects) != 1:
        raise SwitchError(
            f"Expected one .yyp file beside the script; found {len(projects)}."
        )
    return projects[0]


def find_ide_processes() -> list[str]:
    """Return GameMaker IDE process names if they can be detected."""
    if sys.platform == "win32":
        try:
            result = subprocess.run(
                ["tasklist", "/FI", "IMAGENAME eq GameMaker.exe", "/FO", "CSV", "/NH"],
                capture_output=True,
                text=True,
                check=False,
            )
        except OSError:
            return []
        return ["GameMaker.exe"] if re.search(
            r'"GameMaker\.exe"', result.stdout, re.IGNORECASE
        ) else []

    proc = Path("/proc")
    if proc.is_dir():
        found: list[str] = []
        for entry in proc.iterdir():
            if not entry.name.isdigit():
                continue
            try:
                args = (entry / "cmdline").read_bytes().decode(
                    "utf-8", errors="replace"
                ).split("\0")
            except OSError:
                continue
            if not args:
                continue
            executable = Path(args[0]).name.lower()
            if executable in {"gamemaker", "gamemaker.exe", "gamemakerstudio"}:
                found.append(executable)
        return sorted(set(found))

    try:
        result = subprocess.run(
            ["ps", "-A", "-o", "comm="],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError:
        return []
    return sorted({
        Path(line.strip()).name
        for line in result.stdout.splitlines()
        if Path(line.strip()).name.lower() in {
            "gamemaker", "gamemaker.exe", "gamemakerstudio"
        }
    })


def insert_after(yy: Any, source: Any, key: str, value: Any, anchor: str) -> Any:
    """Return an ordered GameMaker object with key inserted after anchor."""
    result = yy.GmObject(inline=getattr(source, "inline", False))
    inserted = False
    for current, item in source.items():
        if current == key:
            result[current] = value
            inserted = True
            continue
        result[current] = item
        if current == anchor and not inserted:
            result[key] = value
            inserted = True
    if not inserted:
        result[key] = value
    return result


def transform_extension(yy: Any, source: Any, record_version: str) -> Any:
    if not isinstance(source, dict):
        raise SwitchError("An extension resource did not parse as an object.")
    if source.get("resourceType") != "GMExtension":
        raise SwitchError(
            f"Expected a GMExtension resource, got {source.get('resourceType')!r}."
        )
    if source.get("$GMExtension") not in {"", "v1"}:
        raise SwitchError(
            f"Unsupported extension record {source.get('$GMExtension')!r}; "
            "only the v0 and v1 formats are handled."
        )

    code_injection = source.get("maccodeinjection", "")
    mac_props = source.get("macProps", False)
    config_values = source.get("ConfigValues", {})
    if code_injection not in ("", None):
        raise SwitchError(
            "maccodeinjection has a non-default value; refusing to discard it."
        )
    if mac_props not in (False, None):
        raise SwitchError("macProps is enabled; refusing to discard it.")
    if config_values not in ({}, None):
        raise SwitchError(
            "ConfigValues is non-empty; refusing to discard extension settings."
        )

    data = yy.GmObject(inline=getattr(source, "inline", False))
    for key, value in source.items():
        if record_version == "v0" and key in {"maccodeinjection", "macProps"}:
            continue
        if record_version == "v1" and key == "ConfigValues":
            continue
        if key == "$GMExtension":
            value = "" if record_version == "v0" else "v1"
        if key == "ConfigValues" and record_version == "v0":
            value = yy.GmObject(inline=True)
        data[key] = value

    if record_version == "v0":
        if "ConfigValues" not in data:
            data = insert_after(
                yy, data, "ConfigValues", yy.GmObject(inline=True), "classname"
            )
    else:
        if "maccodeinjection" not in data:
            data = insert_after(yy, data, "maccodeinjection", "", "license")
        if "macProps" not in data:
            data = insert_after(yy, data, "macProps", False, "maclinkerflags")

    return data


def build_changes(
    yy: Any, target_key: str
) -> tuple[str, dict[Path, bytes], dict[Path, bytes]]:
    target = TARGETS[target_key]
    yyp_path = find_project_file()
    yyp_doc = yy.Document.from_file(yyp_path)
    yyp_data = yyp_doc.data

    metadata = yyp_data.get("MetaData")
    if not isinstance(metadata, dict):
        raise SwitchError("The project has no MetaData object.")
    current_version = metadata.get("IDEVersion")
    supported_versions = {item["ide_version"] for item in TARGETS.values()}
    if current_version not in supported_versions:
        raise SwitchError(
            f"Project IDEVersion {current_version!r} is not one of the two "
            "known versions; refusing to guess its resource formats."
        )

    resource_paths = {
        entry.get("id", {}).get("path")
        for entry in yyp_data.get("resources", [])
        if isinstance(entry, dict) and isinstance(entry.get("id"), dict)
    }
    changed_paths = [yyp_path]
    original: dict[Path, bytes] = {yyp_path: yyp_path.read_bytes()}
    documents: dict[Path, bytes] = {}

    for relative, expected_name in EXTENSION_FILES:
        rel_path = Path(relative)
        if relative not in resource_paths:
            raise SwitchError(f"{relative} is not registered in the project file.")
        path = ROOT / rel_path
        if not path.is_file():
            raise SwitchError(f"Required extension file is missing: {relative}")
        doc = yy.Document.from_file(path)
        data = doc.data
        if data.get("name") != expected_name:
            raise SwitchError(
                f"{relative} contains extension {data.get('name')!r}, "
                f"expected {expected_name!r}."
            )
        original[path] = path.read_bytes()
        doc.data = transform_extension(yy, data, target["extension_record"])
        documents[path] = doc.dumps().encode("utf-8")
        changed_paths.append(path)

    metadata["IDEVersion"] = target["ide_version"]
    documents[yyp_path] = yyp_doc.dumps().encode("utf-8")
    desired = {
        path: body for path, body in documents.items()
        if body != original[path]
    }
    return current_version, original, desired


def show_plan(
    original: dict[Path, bytes], desired: dict[Path, bytes], target_key: str
) -> None:
    if not desired:
        print(f"Project is already set to {TARGETS[target_key]['label']}.")
        return
    print(f"Target: {TARGETS[target_key]['label']}")
    for path, new_bytes in desired.items():
        old_text = original[path].decode("utf-8").splitlines(keepends=True)
        new_text = new_bytes.decode("utf-8").splitlines(keepends=True)
        diff = difflib.unified_diff(
            old_text,
            new_text,
            fromfile=path.relative_to(ROOT).as_posix(),
            tofile=f"{path.relative_to(ROOT).as_posix()} (target)",
        )
        sys.stdout.writelines(diff)


def backup_files(
    original: dict[Path, bytes], target_key: str, current_version: str
) -> Path:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup_root = ROOT / ".gm-version-switcher" / "backups"
    backup_dir = backup_root / f"{stamp}-{target_key}"
    backup_dir.mkdir(parents=True, exist_ok=False)
    manifest = {
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "from_ide_version": current_version,
        "to_ide_version": TARGETS[target_key]["ide_version"],
        "files": [],
    }
    for path, body in original.items():
        relative = path.relative_to(ROOT)
        destination = backup_dir / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(body)
        manifest["files"].append({
            "path": relative.as_posix(),
            "sha256": hashlib.sha256(body).hexdigest(),
        })
    (backup_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    return backup_dir


def apply_changes(
    original: dict[Path, bytes],
    desired: dict[Path, bytes],
    target_key: str,
    current_version: str,
) -> Path:
    for path, body in original.items():
        if path.read_bytes() != body:
            raise SwitchError(
                f"{path.relative_to(ROOT)} changed after analysis; run again."
            )
    backup_dir = backup_files(original, target_key, current_version)
    staged: dict[Path, Path] = {}
    replaced: list[Path] = []
    try:
        for path, body in desired.items():
            temp = path.with_name(f".{path.name}.{os.getpid()}.switch-tmp")
            temp.write_bytes(body)
            staged[path] = temp

        for path, temp in staged.items():
            if path.read_bytes() != original[path]:
                raise SwitchError(
                    f"{path.relative_to(ROOT)} changed before commit; run again."
                )
            os.replace(temp, path)
            replaced.append(path)
    except Exception:
        for path in replaced:
            rollback = path.with_name(f".{path.name}.{os.getpid()}.rollback-tmp")
            rollback.write_bytes(original[path])
            os.replace(rollback, path)
        raise
    finally:
        for temp in staged.values():
            if temp.exists():
                temp.unlink()
    return backup_dir


def choose_target(requested: str | None) -> str:
    if requested:
        return requested
    print("GameMaker version switcher")
    print("  1) Windows installed — 2024.14.4.222")
    print("  2) Linux beta — 2026.100.0.1139")
    choice = input("Choose a target (1, 2, or q): ").strip().lower()
    if choice == "1":
        return "windows"
    if choice == "2":
        return "linux-beta"
    raise SwitchError("No version selected.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "version",
        nargs="?",
        choices=tuple(TARGETS),
        help="target IDE profile; omit to choose interactively",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print the metadata diff without writing project files",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="apply without the final confirmation prompt",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="bypass the running-IDE check if GameMaker is open for another project",
    )
    args = parser.parse_args()

    try:
        target_key = choose_target(args.version)
        yy = load_gm_json()
        current_version, original, desired = build_changes(yy, target_key)
        show_plan(original, desired, target_key)
        if not desired or args.dry_run:
            return 0

        running = find_ide_processes()
        if running and not args.force:
            raise SwitchError(
                "GameMaker appears to be running. Close the IDE before switching. "
                "Use --force only if it is open for a different project."
            )
        if running:
            print("Warning: bypassing running IDE check.")

        if not args.yes:
            answer = input("Apply these changes? [y/N]: ").strip().lower()
            if answer not in {"y", "yes"}:
                print("Cancelled; no project files changed.")
                return 0

        backup = apply_changes(original, desired, target_key, current_version)
        print(f"Switched to {TARGETS[target_key]['label']}.")
        print(f"Backup: {backup.relative_to(ROOT).as_posix()}")
        print("Close and reopen the project in the selected GameMaker IDE.")
        return 0
    except (OSError, SwitchError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())