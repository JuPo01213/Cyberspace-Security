import capstone
engine=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_64)
items=list(engine.disasm(bytes.fromhex('4831c0c3'),4096))
assert [item.mnemonic for item in items]==['xor','ret']
print('BENIGN_CAPSTONE_CANARY_OK')
