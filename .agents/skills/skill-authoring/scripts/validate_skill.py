#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path

FRONTMATTER_RE = re.compile(r"\\A---\\s*\\n(.*?)\\n---\\s*\\n", re.DOTALL)
KEY_RE = re.compile(r"^([A-Za-z0-9_-]+)\\s*:\\s*(.*)$")
PORTABLE_NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

def parse_simple_frontmatter(text: str) -> dict[str, str]:
    m = FRONTMATTER_RE.match(text)
    if not m:
        raise ValueError("SKILL.md must start with closed YAML front matter")
    out: dict[str, str] = {}
    for raw in m.group(1).splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        km = KEY_RE.match(line)
        if not km:
            raise ValueError(f"unsupported front-matter line for lightweight validator: {raw}")
        key, value = km.groups()
        out[key] = value.strip().strip('"').strip("'")
    return out

def check_openai_yaml(path: Path, errors: list[str]) -> None:
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    for token in ("interface:", "display_name:", "short_description:"):
        if token not in text:
            errors.append(f"agents/openai.yaml missing {token}")
    if "default_prompt:" in text and re.search(r"default_prompt:\\s*[\\\"']?\\s*[\\\"']?\\s*$", text, re.MULTILINE):
        errors.append("agents/openai.yaml has an empty default_prompt")

def main() -> int:
    p = argparse.ArgumentParser(description="Validate a repository Agent Skill scaffold.")
    p.add_argument("skill_dir")
    args = p.parse_args()

    root = Path(args.skill_dir)
    errors: list[str] = []
    warnings: list[str] = []

    if not root.is_dir():
        errors.append("skill directory does not exist")

    skill_md = root / "SKILL.md"
    if not skill_md.is_file():
        errors.append("missing SKILL.md")
    else:
        try:
            text = skill_md.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            errors.append("SKILL.md must be valid UTF-8")
            text = ""

        if text:
            try:
                fm = parse_simple_frontmatter(text)
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

    file_count = sum(1 for p in root.rglob("*") if p.is_file())
    if file_count > 500:
        errors.append("file count exceeds current OpenAI hosted-skill limit of 500 files")

    for pth in root.rglob("*"):
        if pth.is_file() and pth.stat().st_size > 25 * 1024 * 1024:
            errors.append(f"file exceeds current OpenAI 25 MB uncompressed-file limit: {pth.relative_to(root)}")

    for warning in warnings:
        print(f"[WARN] {warning}")
    for error in errors:
        print(f"[ERROR] {error}")

    if errors:
        return 1
    print("[OK] basic skill validation passed")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
