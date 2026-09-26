import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import java.io.*;

public class DecompileDispatch2 extends GhidraScript {
    PrintWriter out;
    void dumpFn(long t, String tag) throws Exception {
        Address a = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(t);
        disassemble(a);
        Function f = getFunctionAt(a);
        if (f == null) f = createFunction(a, "dispatch_" + tag);
        out.println("== " + tag + " target=0x" + Long.toHexString(t) + " fn=" + (f == null ? "CREATE_FAILED" : f.getName()) + " ==");
        if (f == null) return;
        DecompInterface di = new DecompInterface();
        di.openProgram(currentProgram);
        DecompileResults res = di.decompileFunction(f, 240, monitor);
        if (res.decompileCompleted()) out.println(res.getDecompiledFunction().getC());
        else out.println("DECOMPILE FAILED: " + res.getErrorMessage());
        out.println();
    }
    public void run() throws Exception {
        out = new PrintWriter(new FileWriter("<HOST_PATH>/EPT/artifacts/agent/ghidra/ept-proto-1029/decompile_dispatch2.txt"));
        dumpFn(0x1400f77aeL, "dispatch_after_body");
        dumpFn(0x14019349dL, "trampoline");
        out.close();
        println("DECOMPILE_DISPATCH2_DONE");
    }
}
