#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path

FRONTMATTER_RE = re.compile(r"\A---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|$)", re.DOTALL)
PORTABLE_NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

def parse_frontmatter_fields(text: str) -> dict[str, str]:
    m = FRONTMATTER_RE.match(text)
    if not m:
        raise ValueError("SKILL.md must start with closed YAML front matter")

    lines = m.group(1).splitlines()
    fields: dict[str, str] = {}
    i = 0
    while i < len(lines):
        raw = lines[i]
        if not raw.strip() or raw.lstrip().startswith("#"):
            i += 1
            continue
        if raw[:1].isspace():
            i += 1
            continue
        if ":" not in raw:
            i += 1
            continue

        key, value = raw.split(":", 1)
        key = key.strip()
        value = value.strip()

        if key in {"name", "description"}:
            if value in {"|", ">"}:
                block: list[str] = []
                i += 1
                while i < len(lines) and (not lines[i].strip() or lines[i][:1].isspace()):
                    block.append(lines[i].strip())
                    i += 1
                fields[key] = " ".join(x for x in block if x).strip()
                continue
            fields[key] = value.strip('"').strip("'")
        i += 1

    return fields

def check_openai_yaml(path: Path, errors: list[str]) -> None:
    if not path.exists():
        return
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        errors.append("agents/openai.yaml must be valid UTF-8")
        return

    for token in ("interface:", "display_name:", "short_description:"):
        if token not in text:
            errors.append(f"agents/openai.yaml missing {token}")

    m = re.search(r"(?m)^[ \t]*default_prompt:[ \t]*(.*)$", text)
    if m is not None and not m.group(1).strip().strip('"').strip("'"):
        errors.append("agents/openai.yaml has an empty default_prompt")

def main() -> int:
    p = argparse.ArgumentParser(
        description="Lightweight repository validation for an Agent Skill. "
                    "This does not replace the target platform's validator."
    )
    p.add_argument("skill_dir")
    args = p.parse_args()

    root = Path(args.skill_dir)
    errors: list[str] = []
    warnings: list[str] = []

    if not root.is_dir():
        print("[ERROR] skill directory does not exist")
        return 1

    skill_md = root / "SKILL.md"
    if not skill_md.is_file():
        errors.append("missing SKILL.md")
        text = ""
    else:
        try:
            text = skill_md.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            errors.append("SKILL.md must be valid UTF-8")
            text = ""

    if text:
        try:
            fm = parse_frontmatter_fields(text)
        except ValueError as exc:
            errors.append(str(exc))
            fm = {}

        name = fm.get("name", "").strip()
        description = fm.get("description", "").strip()

        if not name:
            errors.append("front matter requires non-empty name")
        if not description:
            errors.append("front matter requires non-empty description")
        if len(description) > 1024:
            errors.append("description exceeds current OpenAI 1024-character limit")
        if name and not PORTABLE_NAME_RE.fullmatch(name):
            warnings.append("name is not lowercase hyphen-case; recommended here for portability")

        body = FRONTMATTER_RE.sub("", text, count=1).strip()
        if not body:
            errors.append("SKILL.md body is empty")
        if "TODO:" in text:
            warnings.append("SKILL.md still contains TODO placeholders")

    manifests = [p for p in root.rglob("*") if p.is_file() and p.name.lower() == "skill.md"]
    if len(manifests) != 1:
        errors.append(f"skill bundle should contain exactly one SKILL.md/skill.md; found {len(manifests)}")

    check_openai_yaml(root / "agents" / "openai.yaml", errors)

    all_files = [p for p in root.rglob("*") if p.is_file()]
    if len(all_files) > 500:
        errors.append("file count exceeds current OpenAI hosted-skill limit of 500 files")

    total_size = 0
    for pth in all_files:
        size = pth.stat().st_size
        total_size += size
        if size > 25 * 1024 * 1024:
            errors.append(f"file exceeds current OpenAI 25 MB uncompressed-file limit: {pth.relative_to(root)}")

    if total_size > 50 * 1024 * 1024:
        warnings.append(
            "raw bundle size exceeds 50 MB; current hosted upload limit applies to the compressed zip, "
            "so validate the actual archive before upload"
        )

    for warning in warnings:
        print(f"[WARN] {warning}")
    for error in errors:
        print(f"[ERROR] {error}")

    if errors:
        return 1
    print("[OK] lightweight skill validation passed")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
