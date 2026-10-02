# 分析分支工具链

This reference maps tools to decisions. It is deliberately not an installation recipe and should be read only when choosing a tool for a named question.

## Recommended order

1. **Independent PE and coordinate parser**

   Use [LIEF’s PE Python API](https://lief.re/doc/latest/formats/pe/python.html) or a separate stdlib parser to inspect the pristine PE. Keep `ImageBase`, section RVA, virtual size, raw size, raw pointer, and the custom capture layout separate. A parser validates format and mapping; it does not prove runtime behavior.

2. **Reproducible static analysis**

   Use [Ghidra Headless Analyzer](https://github.com/NationalSecurityAgency/ghidra/blob/master/Ghidra/RuntimeScripts/support/analyzeHeadlessREADME.md) for repeatable import/process runs and pre/post scripts. Export memory maps, section boundaries, function ranges, raw bytes, and xrefs into artifacts. Use the GUI or Ghidra RPC only after the same address map has passed the coordinate gate.

3. **Low-cost triage**

   Use [FLOSS](https://github.com/mandiant/flare-floss/blob/master/doc/usage.md) for static, stack, tight, and decoded strings; use [capa](https://mandiant.github.io/capa/) for capability candidates and JSON/verbose evidence; use [YARA](https://github.com/VirusTotal/yara/tree/master/docs) for repeatable byte/string pattern queries. These tools route analysis to candidate functions or regions. Their matches and non-matches are not branch-execution proof.

4. **One dynamic discriminator**

   Use [WinDbg user-mode debugging](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/getting-started-with-windbg) when the question is process exit, exception, return value, or stack. Use [Frida](https://frida.re/docs/home/) when the question is a narrow native function/API event. Do not run both as uncoordinated observers in the same arm; each can change timing and failure modes.

5. **Standardized analysis environment**

   [REMnux](https://docs.remnux.org/) and [FLARE-VM](https://github.com/mandiant/flare-vm) are useful for reproducible tool availability and host/guest separation. They do not repair a slow NEM base or an invalid collection channel. Static work should remain offline whenever it can answer the question.

6. **Only when the base supports it**

   [CAPE](https://github.com/kevoreilly/CAPEv2) and [DRAKVUF](https://github.com/tklengyel/drakvuf) can automate dynamic collection or provide hypervisor-level observation, but they require their own supported environment and introduce setup cost. They are not the next step for a coordinate-mapping defect or an already-invalid harvest path.

## Selection rule

Before adding a tool, state the discriminator it supplies, the artifact it will emit, and the stop condition. If those three items cannot be written, keep the tool out of the critical path.

