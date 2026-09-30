#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

SKILL_TEMPLATE = """---
name: {name}
description: TODO: 用一句话说明这个 Skill 提供什么可复用能力，以及哪些用户目标或条件应该触发它。
---

# {title}

## 能力与边界

说明：
- 这个 Skill 帮用户完成什么；
- 哪些请求应该触发；
- 哪些相邻请求不应该触发；
- 哪些能力属于 Harness / Tool，不能由本 Skill 伪造。

## 共享指导

只写所有触发都真正需要的 instructions。
如果需要复杂阶段/分支，再加入最小 Workflow；如果 Example 有独立教学价值，再加入最小 Example。

## 按需资源

列出真正需要的 references / scripts / assets，并说明何时读取或运行。
不要为了结构完整创建无消费者的资源。
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
    short_description = args.short_description or f"Use {title} for a reusable capability"
    default_prompt = args.default_prompt or f"Use the {name} skill when it is relevant to the user's goal."
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
