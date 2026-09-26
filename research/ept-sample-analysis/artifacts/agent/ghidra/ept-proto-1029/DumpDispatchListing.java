import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import java.io.*;

public class DumpDispatchListing extends GhidraScript {
    public void run() throws Exception {
        PrintWriter out = new PrintWriter(new FileWriter("<HOST_PATH>/EPT/artifacts/agent/ghidra/ept-proto-1029/dispatch_listing.txt"));
        Address a = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(0x1400f77aeL);
        disassemble(a);
        Function f = getFunctionAt(a);
        if (f == null) f = createFunction(a, "dispatch_after_body");
        out.println("fn=" + (f == null ? "NONE" : f.getName() + " body=" + f.getBody().getNumAddresses()));
        InstructionIterator it = currentProgram.getListing().getInstructions(f.getBody(), true);
        int n = 0;
        while (it.hasNext() && n < 30000) {
            Instruction ins = it.next();
            out.println(ins.getAddress() + "  " + ins.getMnemonicString() + " " + ins.toString());
            n++;
        }
        out.println("TOTAL " + n);
        out.close();
        println("DUMP_DISPATCH_LISTING_DONE n=" + n);
    }
}
