# Mature patterns behind the skill

This reference explains provenance. It is not required on every run.

The skill is a project-specific profile over established components and engineering patterns. It is not evidence that one industry-standard workflow already covers this exact Windows reverse-engineering laboratory.

## Agent Skills packaging

OpenAI documents a Skill as a directory with one SKILL.md manifest plus optional references, scripts, and assets. The model sees name/description for discovery, then reads the full instructions and supporting files when the skill is selected.

This supports the current split:

- SKILL.md: routing, invariants, autonomy;
- references/runbook.md: mandatory procedure;
- references/adapters.md: backend-specific command families;
- references/failure-routing.md: incident decision table;
- scripts/preflight.ps1: repeatable read-only environment discovery;
- assets/: fallback templates only.

Official reference:
https://developers.openai.com/api/docs/guides/tools-skills

## Sandbox orchestration

CAPE/Cuckoo-style systems separate Host orchestration, disposable Windows analysis Guests, task identity/status, result collection, and snapshots. Reuse these platform features when available instead of rebuilding them.

## Durable execution

Temporal-style durable execution provides a relevant model for worker/network failure: durable history/state, explicit external side effects, retry semantics, and recovery after worker loss. This skill borrows the pattern; it does not require Temporal.

## Single writer

Kubernetes Lease/optimistic concurrency illustrates why an owner field is not a lock. Use an atomic Lease/CAS/transaction/mutex.

## Evidence provenance

CASE/UCO and W3C PROV provide established provenance concepts: source/entity, action/activity, agent/tool, and resulting artifact. Runtime Markdown duplication is not required to preserve provenance.

## Backend command sources

PowerShell Direct:
https://learn.microsoft.com/windows-server/virtualization/hyper-v/powershell-direct

VirtualBox guestcontrol:
https://docs.oracle.com/en/virtualization/virtualbox/7.1/user/vboxmanage.html

CDB command-line options:
https://learn.microsoft.com/windows-hardware/drivers/debugger/cdb-command-line-options

## Evidence status

- Official command syntax above: externally verifiable documentation.
- Failure routes in this Skill: project-derived synthesis informed by recorded incidents and the cited platform semantics.
- The complete combined workflow: not yet an externally standardized end-to-end workflow and must not be described as mature merely because individual components are mature.
