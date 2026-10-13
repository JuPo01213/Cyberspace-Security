# Host–guest transport matrix

This reference selects a transport by experiment needs. It does not authorize changing a production host or weakening an isolation boundary.

| Transport | Good for | Main dependency | Main failure mode | Evidence posture |
|---|---|---|---|---|
| SSH / WinRM | Bootstrap, diagnosis, ordinary admin | Guest network and service | Session dies, banner stalls, output buffering | Medium; keep out of the measured runtime |
| VirtualBox Guest Additions | Short `guestcontrol` commands, file copy, small `guestproperty` events | Guest Additions, running guest, credentials for many operations | VBoxService/session startup stalls | Must be fixed in the baseline; may be visible to the sample |
| Shared Folder | Bulk input/output without guest IP | Guest Additions and mounted share | Host exposure, guest integration, open-file visibility | Fast but higher perturbation; use transient/read-only where possible |
| Hyper-V PowerShell Direct | Windows guest control without network | Hyper-V host and supported Windows guest | Hypervisor-specific; not portable to VirtualBox | Strong control channel, but requires a new hypervisor baseline |
| QEMU Guest Agent / virtio | Host control and events independent of guest IP | Guest agent plus virtio-serial/vsock setup | Agent not running or channel misconfigured | Good for controlled labs; integration must be part of the baseline |
| Local spool + offline disk | Final forensic artifacts and low-perturbation runs | Reliable guest writes and host read-only mount | Unflushed tail, wrong disk, incomplete extraction | Highest for behavior evidence when identity and read path are controlled |
| Host Computer Use / VM console screenshot | Human/UI observation, visible-window corroboration, controlled GUI interaction | Visible VM display and a separately declared GUI arm | Session-0 invisibility, console not attached, focus/input drift, screenshot-only ambiguity | Auxiliary visual evidence; never the sole negative, completion, or artifact channel |

## Visual/UI plane

Computer Use is a host-side Windows UI controller. It is not normally a package that can be copied into the guest to obtain a semantic guest-control or evidence channel. A guest-side remote-control agent can be installed in a lab, but that is a different instrument, changes the baseline, and must be declared and isolated in its own snapshot/arm.

For VirtualBox, use a visible console or a controlled VM screenshot only as a separate visual arm. Use only a platform adapter that is present in the active capability registry; the generic skill does not ship a substitute wrapper or assume a particular capture script. Record `run_id`, wall-clock timestamp, VM state, capture method/path, visible window/session, and the limitation of what the pixels can prove. A screenshot may corroborate a dialog, desktop state, or user-visible prompt; it does not prove branch entry, process exit, file persistence, memory state, or absence of behavior. If the target runs in Session 0/service context, the console may not show the relevant UI at all.

The preferred arrangement is:

1. control plane: short bootstrap/signaling operations;
2. data plane: guest-local spool plus offline harvest;
3. completion plane: explicit marker, process exit, guest property, or VM power state;
4. visual plane: optional screenshots/UI interaction, isolated from the measured no-communication arm.

If the Computer Use inventory does not return exactly one current VM window, do not guess a native window handle or reuse stale coordinates. Classify UI binding as `VISUAL_UNAVAILABLE` and keep the guest-side evidence channels unchanged; use a registered platform adapter only when one exists.

Never attach Computer Use to a running zero-communication arm merely to make it easier to observe. Start a separate GUI clone when visual evidence is worth the perturbation, and never treat screenshot absence as a sample negative.

### Program-state observation

A guest process census is a better health signal than a screenshot. Prefer an in-guest command such as `tasklist` / `Get-CimInstance Win32_Process` through the currently verified SSH, WinRM, or Guest Control adapter. The adapter must preserve a raw result plus a timing/status/hash sidecar and must not become a second sample runner. Their explicit outcomes are:

- `PROCESS_LIST`: the guest returned a process list;
- `SSH_UNAVAILABLE`: the SSH connection, banner, or bounded command did not become usable before the deadline;
- `GUEST_CONTROL_UNAVAILABLE`: the Guest Additions execution session was not ready, timed out, or otherwise failed to start;
- `SSH_ERROR` / `GUEST_CONTROL_ERROR`: another command or tool error.

Every non-`PROCESS_LIST` outcome is an instrument result, never evidence that the sample is absent. Bound the probe from the current task deadline and expected command cost; do not treat a fixed interval as a universal contract or retry indefinitely while a protected process is under load. A first timeout followed by a later process list is a guest/service readiness measurement, not a contradiction and not a sample negative. If SSH or Guest Control is unreliable during the measured interval, have the guest-side arm emit a durable process/exit/branch record before launch and mirror small state transitions through `guestproperty`.

`VBoxManage guestcontrol list processes` should not be treated as a complete Windows process census: a complete answer requires an in-guest query such as `tasklist` or CIM/WMI. The host-side CUA/GUI plane is separate and remains useful only for desktop-visible prompts or interaction.

## Timing contract

Every long-running arm records timing separately from transport:

```json
{
  "timing": {
    "expected_duration_sec": 0,
    "deadline_sec": 0,
    "poll_interval_sec": 0,
    "completion_event": "",
    "started_at": "",
    "last_progress_at": "",
    "elapsed_sec": 0,
    "timeout_action": "classify_WAIT_TIMEOUT_and_preserve_artifacts"
  }
}
```

## Semantic delivery contract

Every command, file, parameter and result crosses a semantic boundary. Record its producer, consumer, `run_id`, `task_id`, `artifact_id`, source and target path context, byte length, encoding, hash, channel, session/job identity and timestamps. A Host path is not a Guest path; a Host `Test-Path` is not proof that a Guest file exists.

Treat delivery as a transaction:

```text
producer snapshot
  → receiver-context resolution
  → Guest/consumer read-back
  → structured acknowledgement
  → consumer observation
  → per-item harvest
```

The strongest proof available at each boundary is the one to record: bytes/hash for files, parsed schema for parameters, `accepted` plus durable `job_id` for submission, and a consumer event for actual use. If a response was sent but its durable job identity or result was lost, classify `SUBMISSION_UNKNOWN` and do not resubmit until the original run is resolved.

Control calls should be short and single-purpose. Complex enumeration and long work run through a Guest-local runner with a durable completion event. On timeout preserve raw output, reap only the exact wrappers and descendants created by this batch, then issue one minimal recovery probe before retrying.

The optional Collaboration plane uses [agent-collaboration.md](agent-collaboration.md). It shares the same delivery and evidence rules; an Agent report or status label never replaces the raw session, Guest artifact or Host harvest.

`deadline_sec` is a wall-clock failure boundary, not the expected runtime. It must be justified from the current arm's internal bound and measured environment timing. A loop such as `95 * sleep 10` is not a timing contract unless those values are derived and recorded for this run. When the deadline expires, stop or perform explicitly classified cleanup; do not silently add another wait window.

## VirtualBox conventions

Use `guestproperty` only for small strings such as `/lab/<run_id>/state=READY`; it is not a log transport. Use `guestcontrol copyto/copyfrom` for short, completed files and `run` for short commands. A long-running process should be detached or pre-placed and should write its own local spool.

Shared Folders do not require guest networking, but they expand the host/guest attack surface. Do not expose the host project directory to an untrusted sample. Prefer a narrow transient share, a read-only input share, or no share at all for low-perturbation evidence.

## Manifest fields

Record at least:

```json
{
  "communication": {
    "control": "guestcontrol|guestproperty|ssh|winrm|none",
    "data": "guest_local_spool|shared_folder|guestcontrol|ssh_scp|offline_disk",
    "completion": "guestproperty|marker_file|vm_power_state|offline_disk|none",
    "run_id": "...",
    "channel_events": [
      {"plane":"control|data|completion", "channel":"...", "event":"...", "latency_ms":0, "bytes":0, "detail":"..."}
    ]
  }
}
```

