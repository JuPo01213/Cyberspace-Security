import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.SourceType;
import java.io.*;

public class DecompileTargets2 extends GhidraScript {
    PrintWriter out;

    void dumpFn(long t, String tag) throws Exception {
        Address a = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(t);
        disassemble(a);
        Function f = getFunctionAt(a);
        if (f == null) {
            f = createFunction(a, "state_" + tag);
        }
        out.println("== " + tag + " target=0x" + Long.toHexString(t) + " fn=" + (f == null ? "CREATE_FAILED" : f.getName()) + " ==");
        if (f == null) return;
        DecompInterface di = new DecompInterface();
        DecompileOptions opts = new DecompileOptions();
        di.setOptions(opts);
        di.openProgram(currentProgram);
        DecompileResults res = di.decompileFunction(f, 240, monitor);
        if (res.decompileCompleted()) {
            out.println(res.getDecompiledFunction().getC());
        } else {
            out.println("DECOMPILE FAILED: " + res.getErrorMessage());
        }
        out.println();
    }

    public void run() throws Exception {
        String outPath = "<HOST_PATH>/EPT/artifacts/agent/ghidra/ept-proto-1029/decompile_out2.txt";
        out = new PrintWriter(new FileWriter(outPath));
        dumpFn(0x14014731cL, "body_received_handler");
        dumpFn(0x14014206cL, "event40_handler");
        dumpFn(0x140131455L, "after_len_read");
        dumpFn(0x14017713fL, "after_body_recv");
        dumpFn(0x140170895L, "after_len_recv");
        dumpFn(0x140141fefL, "body_proc_cont");
        out.close();
        println("DECOMPILE_TARGETS2_DONE");
    }
}
