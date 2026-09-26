import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import java.io.*;

public class DecompileTargets extends GhidraScript {
    public void run() throws Exception {
        String outPath = "<HOST_PATH>/EPT/artifacts/agent/ghidra/ept-proto-1029/decompile_out.txt";
        PrintWriter out = new PrintWriter(new FileWriter(outPath));
        long[] targets = {0x140131455L, 0x140141fefL, 0x14014731cL, 0x140170895L, 0x14017713fL};

        FunctionManager fm = currentProgram.getFunctionManager();
        FunctionIterator it = fm.getFunctions(true);
        int total = 0;
        StringBuilder sb = new StringBuilder();
        while (it.hasNext()) {
            Function f = it.next();
            long ea = f.getEntryPoint().getOffset();
            if (ea >= 0x140130000L && ea < 0x140180000L) {
                sb.append(String.format("FUNC 0x%08x %s%n", ea, f.getName()));
                total++;
            }
        }
        out.println("== FUNCTIONS IN 0x140130000-0x140180000: " + total + " ==");
        out.print(sb);

        DecompInterface di = new DecompInterface();
        di.openProgram(currentProgram);
        for (long t : targets) {
            Address a = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(t);
            Function f = getFunctionContaining(a);
            out.println("== TARGET 0x" + Long.toHexString(t) + " function=" + (f == null ? "NONE" : f.getName() + " @0x" + Long.toHexString(f.getEntryPoint().getOffset())) + " ==");
            if (f == null) continue;
            DecompileResults res = di.decompileFunction(f, 180, monitor);
            if (res.decompileCompleted()) {
                out.println(res.getDecompiledFunction().getC());
            } else {
                out.println("DECOMPILE FAILED: " + res.getErrorMessage());
            }
        }
        out.close();
        println("DECOMPILE_TARGETS_DONE");
    }
}
