# C171: <OTHER_VM_LABEL> rebuild method and install stall

Run ID: C171-rebuild-win10-20260923-01
Status: CONTROL_NOT_READY / INSTALL_STALLED_REPORTED_AT_78_PERCENT

## Scope

This run rebuilt a new Windows 10 VM from the local ISO. The old VM was deleted before this run. No EPT sample was launched, no target process was started, and no target-level evidence exists from this run.

## Host inputs and identity

- Windows ISO: <HOST_PATH>/Windows.iso
- ISO SHA-256: 5352E57EAA546FFDBFB89CFD1A215FF4BBE044DF4016ECAF76BAC6219736674F
- Authoritative sample directory: <HOST_PATH>/EPT/sample
- Authoritative sample SHA-256: CA6B4C6A9A4DDC1C791A0BB3E98585856540C2BAA7CAC73F92CB21D87ACAA3B2
- Guest Additions source: C:/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso
- No sample copy was made.

## Rebuild method

1. Detect the ISO with VBoxManage unattended detect; it reported Windows10_64, OS version 2004, language zh-cn, and IsInstallSupported=on.
2. Create and register <OTHER_VM_LABEL> under <HOST_PATH>/VMs, with a 64 GiB dynamic VDI, 2 vCPUs, 4096 MiB RAM, SATA disk, IDE installation DVD, BIOS firmware, and NAT networking.
3. Generate a random non-empty password for the local Guest account <VM_USER> on the host only.
4. Store the password only at <HOST_PATH>/VMs/<OTHER_VM_LABEL>/host-secrets/<VM_USER>.password.txt. The directory and file are restricted to the current host identity with icacls; this path is not a shared folder and the password is not recorded here.
5. Run VirtualBox unattended Windows installation with --user-password-file, --admin-password-file, --install-additions, and hostname <OTHER_VM_LABEL>.lab.local.
6. Add the persistent writable HexPatch share:
   - Host: <HOST_PATH>/HexPatch
   - Guest root: VBoxSvr/HexPatch
   - Automount: enabled
7. Add the sample share only after the VM reached running, because VirtualBox rejects --transient shared-folder creation while the VM is powered off:
   - Host: <HOST_PATH>/EPT/sample
   - Guest root: VBoxSvr/EPTSample
   - Read-only: enabled
   - Automount: enabled
   - Transient: enabled
8. Do not run guestcontrol_preflight.ps1 with Launch until Guest Additions, GuestControl authentication, Guest ACK, and the Guest-side sample hash all pass.

The reusable host setup is in method/harnesses/rebuild_win10_control.ps1. Its unattended-install output is suppressed because VirtualBox can print password values while preparing an unattended installation. The first dry-run did expose the generated throwaway password in host tool output; that password was immediately rotated before the actual installation. The rotated password was never written to the repository or shared folders.

## Image reading method

The reliable image path is:

1. Capture the VM display without touching the Guest:

   VBoxManage controlvm <OTHER_VM_LABEL> screenshotpng <HOST_PATH>/EPT/artifacts/evidence/C171_rebuild_stall78_screen.png

2. Read the PNG directly with the image-capable read API, not as text:

   codemode.read({ path: <HOST_PATH>/EPT/artifacts/evidence/C171_rebuild_stall78_screen.png, offset: 0, limit: 1 })

3. Expected tool result:

   - content[0].type = text, value Read image file [image/png]
   - content[1].type = image, mimeType = image/png

The PNG is a visual evidence item. OCR may be used only as an auxiliary text extraction method; the direct image result is the primary image-reading method.

Screenshot evidence:

- Path: artifacts/evidence/C171_rebuild_stall78_screen.png
- SHA-256: ACA746426ABF8E2320183BC18895091550867193059EBB7CCC6F87C4DF58FDA8
- The operator reported the Windows installer was stuck at 78 percent. The screenshot is retained for direct visual review.

## Observed state at record time

- VM name: <OTHER_VM_LABEL>
- VM UUID: e560fa3d-eb6d-4a78-b154-633bdd8bc4fc
- VM config: <HOST_PATH>/VMs/<OTHER_VM_LABEL>/<OTHER_VM_LABEL>.vbox
- VM state: running
- RAM/vCPU: 4096 MiB / 2 vCPU
- HexPatch: configured as a machine mapping to <HOST_PATH>/HexPatch
- EPTSample: configured as a read-only transient mapping to <HOST_PATH>/EPT/sample
- Guest Additions properties: No value set! for RunLevel and Version
- Guest OS properties: No value set! for OS product and logged-in users
- GuestControl ACK: absent
- EPT launch: not requested
- Target PID/PPID: unknown and not applicable

The VM process remained responsive, but the absence of Guest Additions properties means the Windows installation had not reached a usable post-install Guest state. This is an installation/control readiness issue, not an EPT result.

## Current gate

CONTROL_NOT_READY: do not force power off, do not launch the sample, and do not interpret the 78 percent installer stall as a target failure. Preserve the screenshot, VBox log, VM state, and password isolation. Any recovery or restart must create a new run ID and record whether the installer resumed, completed, or required a clean rebuild.
