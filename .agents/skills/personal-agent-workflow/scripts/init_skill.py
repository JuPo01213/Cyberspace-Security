#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

SKILL_TEMPLATE = """---
name: {name}
description: TODO: 用一句话说明这个 Skill 完成什么用户目标，以及哪些请求/条件应触发它。
---

# {title}

## 目标与边界

写清输入、步骤、输出、禁止性推断、追问/停止条件，以及需要按需读取的 supporting files。

## 工作流

1. TODO
2. TODO

## Supporting resources

只保留实际需要的 references / scripts / assets，并在这里说明何时读取或运行。
"""

OPENAI_YAML_TEMPLATE = """interface:
  display_name: "{display_name}"
  short_description: "{short_description}"
  default_prompt: "{default_prompt}"
"""

def normalize_name(raw: str) -> str:
    name = re.sub(r"[^a-z0-9]+", "-", raw.strip().lower()).strip("-")
    return re.sub(r"-{2,}", "-", name)

def main() -> int:
    p = argparse.ArgumentParser(description="Initialize a minimal Agent Skill scaffold.")
    p.add_argument("name")
    p.add_argument("--path", required=True, help="Parent directory where the skill folder will be created.")
    p.add_argument("--resources", default="", help="Comma-separated subset of references,scripts,assets.")
    p.add_argument("--display-name")
    p.add_argument("--short-description")
    p.add_argument("--default-prompt")
    args = p.parse_args()

    name = normalize_name(args.name)
    if not name or not NAME_RE.fullmatch(name):
        raise SystemExit("invalid skill name after normalization")
    if len(name) > 64:
        raise SystemExit("skill name should be <= 64 characters for broad compatibility")

    allowed = {"references", "scripts", "assets"}
    resources = [x.strip() for x in args.resources.split(",") if x.strip()]
    invalid = sorted(set(resources) - allowed)
    if invalid:
        raise SystemExit(f"unsupported resources: {', '.join(invalid)}")

    skill_dir = Path(args.path).resolve() / name
    if skill_dir.exists():
        raise SystemExit(f"refusing to initialize existing directory: {skill_dir}")
    skill_dir.mkdir(parents=True)

    title = " ".join(part.capitalize() for part in name.split("-"))
    (skill_dir / "SKILL.md").write_text(SKILL_TEMPLATE.format(name=name, title=title), encoding="utf-8")

    for resource in resources:
        (skill_dir / resource).mkdir()

    agents = skill_dir / "agents"
    agents.mkdir()
    display_name = args.display_name or title
    short_description = args.short_description or f"Create and use {title}"
    default_prompt = args.default_prompt or f"Use the {name} skill for this task."
    (agents / "openai.yaml").write_text(
        OPENAI_YAML_TEMPLATE.format(
            display_name=display_name.replace('"', '\\"'),
            short_description=short_description.replace('"', '\\"'),
            default_prompt=default_prompt.replace('"', '\\"'),
        ),
        encoding="utf-8",
    )

    print(skill_dir)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
