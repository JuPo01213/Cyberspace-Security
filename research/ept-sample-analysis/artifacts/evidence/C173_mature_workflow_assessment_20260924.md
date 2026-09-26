# C173 Mature Workflow Assessment

Date: 2026-09-24
RunId: C173-mature-workflow-20260924-01
Status: GEN1_COMMUNICATION_READY / SAMPLE_LAUNCH_HELD

## Decision

The active communication path is narrowed to a native Windows workflow: Hyper-V for
VM lifecycle and checkpoints, PowerShell Direct for guest control, and WinDbg for
interactive user-mode debugging. CAPE and DRAKVUF are assessment references only;
neither is deployed on this Windows host.

This decision matches the current constraint that nested virtualization is not
available. Native Hyper-V on a physical Windows host does not require nested
virtualization. CAPE's documented reference host is GNU/Linux with KVM/QEMU, while
DRAKVUF Sandbox is built around Xen and external introspection. WSL2 is not treated
as a substitute for either hypervisor requirement.

## Host observations

- OS: Windows 10 Pro, build 19045, x64.
- Physical memory reported: 16,870,006,784 bytes.
- CPU: 12th Gen Intel(R) Core(TM) i5-12400.
- VirtualMachinePlatform: Enabled.
- Microsoft-Windows-Subsystem-Linux: Enabled.
- Hyper-V before this run: all three queried components were Disabled.
- Hyper-V after this run: Microsoft-Hyper-V-All, Microsoft-Hyper-V-Hypervisor, and
  Microsoft-Hyper-V-Management-PowerShell are Enabled.
- bcdedit: hypervisorlaunchtype Auto.
- Feature operation reported RestartNeeded: True; reboot is pending.
- Hyper-V PowerShell cmdlets were absent before enablement and have not yet been
  validated after reboot.
- VirtualizationFirmwareEnabled, SecondLevelAddressTranslationExtensions, and
  VMMonitorModeExtensions were reported false while the existing Windows
  hypervisor/VBS layer was active. This is a pre-reboot observation, not a final
  hardware rejection.
- Secure Boot reported false.
- WSL has an Ubuntu distribution, currently stopped, version 2.
- Docker server was not available.
- Registered VirtualBox machines are only <OTHER_VM_LABEL> and <OTHER_VM_LABEL>; neither was
  touched. <OTHER_VM_LABEL> is not registered.

## Official capability boundary

- Microsoft documents PowerShell Direct for a local, running Windows 10-or-newer
  Hyper-V guest, with a configured user profile and valid guest credentials:
  https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/powershell-direct
- Microsoft documents Hyper-V VM creation and optional checkpoints through the
  Hyper-V PowerShell/Manager workflow:
  https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/create-a-virtual-machine-in-hyper-v
- Microsoft documents WinDbg remote/process-server sessions and user-mode
  debugging separately from the guest lifecycle:
  https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/remote-debugging-using-windbg
  https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/getting-started-with-windbg
- CAPE's host documentation uses GNU/Linux as the reference host and recommends
  KVM/QEMU for the supported analysis-machine path:
  https://capev2.readthedocs.io/en/latest/installation/host/index.html
  https://capev2.readthedocs.io/en/latest/installation/host/installation.html
- DRAKVUF Sandbox is an external-introspection/Xen-oriented platform; its official
  project documentation and release material are not a direct Hyper-V/Windows-host
  deployment path:
  https://drakvuf-sandbox.readthedocs.io/en/latest/
  https://github.com/CERT-Polska/drakvuf-sandbox

## Reboot gate

The following checks remain pending until the host is restarted:

1. Get-Command Get-VM, New-VM, Get-VMSwitch, Checkpoint-VM.
2. Get-VMHost and Get-VMSwitch.
3. Create a disposable Windows test VM from the existing ISO without the EPT
   sample and verify boot plus checkpoint creation.
4. Verify PowerShell Direct with a non-empty local test account and a marker file
   stored outside the guest's unique research data.
5. Verify host-persistent logs and checkpoint restore before any target sample
   work.

The former VirtualBox <OTHER_VM_LABEL>/Guest Additions/GuestControl objective is
superseded by this route. Its C171/C172 evidence remains immutable historical
material and is not mixed with the Hyper-V verification.

## Evidence references

- Prior VirtualBox evidence remains under artifacts/evidence/C171_* and
  artifacts/evidence/C172_*.
## C173 Gen1 communication result

The Gen1 fallback VM is now the active communication Guest:

- VM: <VM_LABEL>, Generation 1, Windows 10 Pro build 19045.
- Guest hostname: <VM_LABEL>; local account: <VM_USER>; marker: C:\\<VM_LABEL>_guest_ready.txt.
- PowerShell Direct returned hostname, account, OS version, marker state, and free-space data.
- Standard checkpoint: C173-gen1-comm-ready. Channel checkpoint: <VM_LABEL>-gen1-channel-ready.
- Channel checkpoint restore was verified: a post-checkpoint mutation disappeared after restore while the ready marker and Guest ACK remained.
- The control plane is PowerShell Direct. The data plane is a host SMB read-only share named C173_EPTSample, backed by <HOST_PATH>\\EPT\\sample. SMB access is Read and NTFS access is RX for C173SampleReader; the firewall rule is restricted to Guest IP <PRIVATE_IP>.
- Guest ACK: <HOST_PATH>\\HexPatch\\spool\\C173-GEN1-ACK-20260924-04.guest.json. The ACK reports exactly one EPT*.exe, sample_hash_state=HASHED, and the authoritative SHA-256 CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2.
- Guest tools include cdb.exe, windbg.exe, ntsd.exe, kd.exe, 7z.exe, and Rizin. Tool hashes and paths are in <VM_LABEL>_gen1_tool_inventory_20260924.json.
- The sample was not copied, launched, or observed as a process. The ACK and channel evidence both record ept_launch_state=NOT_REQUESTED and sample_launch_requested=false.
- The normal EPT run remains held because the real card value is not present in the host-only secrets directory. Historical length/hash records and redacted placeholders are not used as input.

Evidence:

- <VM_LABEL>_gen1_powershell_direct_20260924.json
- <VM_LABEL>_gen1_checkpoint_restore_20260924.json
- <VM_LABEL>_gen1_tool_inventory_20260924.json
- <VM_LABEL>_gen1_channel_preflight_20260924.json
- <VM_LABEL>_gen1_channel_checkpoint_restore_20260924.json
- <VM_LABEL>_gen1_vmconnect_screen.png

## C173 card source audit

- Read-only filename and metadata audit across C173 host-secrets, the authoritative sample directory, evidence, and method trees found zero candidate card-input files.
- The two host-only secret files are account credentials for Guest control and the SMB reader; their values were not read into evidence.
- Result: real_card_input_present=false, sample_launch_requested=false, launch_gate=SAMPLE_LAUNCH_HELD. Evidence: C173_card_source_audit_20260924.json.

## C173 debugger smoke closure

- CDB attached to benign Guest ping.exe through a PowerShell Direct PSSession, executed a -cf command file, and exited with stdout/stderr harvested using Copy-Item -FromSession.
- Clean smoke evidence contains the attach marker, ping module listing, and thread listing; stderr length is 0. No EPT sample was opened or launched, and no target process remained.
- Active debugger path: CDB PASS_BENIGN_ATTACH. Rizin remains runtime dependency missing and is waived for this CDB-based workflow; WinDbg remains optional GUI-only.
- Evidence: <VM_LABEL>_gen1_debugger_smoke_20260924.json and <VM_LABEL>_gen1_cdb_benign_smoke_20260924_02/.

## C173 post-debugger preflight

- CDB smoke temporary directories were removed from Guest; Guest and host relevant process counts are zero; <VM_LABEL>-gen1-channel-ready remains present.
- The current <VM_USER> PowerShell Direct session does not hold the separate C173SampleReader SMB mapping, so sample access in this probe is recorded as DEFERRED_TO_EXISTING_ACK rather than a hash result.
- Host authoritative SHA-256 and the existing C173-GEN1-ACK-20260924-04 Guest SHA-256 still match. sample_launch_requested=false and SAMPLE_LAUNCH_HELD remain unchanged.
- Evidence: C173_post_debugger_preflight_20260924.json.
