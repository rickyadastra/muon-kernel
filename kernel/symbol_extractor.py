import subprocess
import sys

def extract(path):
    result = subprocess.run(["nm", "-n", path], stdout=subprocess.PIPE)
    lines = result.stdout.decode('utf-8').split('\n')

    symbols = set()

    for line in lines:
        parts = line.split(' ')
        if len(parts) < 2 or parts[1] not in ['T', 't', 'W', 'w']: continue
        symbols.add((parts[0], parts[2]))

    return symbols

def main():
    in_path = sys.argv[1]
    out_path = sys.argv[2]

    symbols = (extract(sys.argv[1]))
    strings = [(", ".join([f"{hex(int(s[0], 16))}", f'"{s[1]}"'])) for s in sorted(symbols)]

    with open(out_path, 'w') as f:
        f.write("module muon::symbols;\n\n")
        f.write("const SymbolEntry[*] KERNEL_SYMS @private = {\n    ")
        f.write(",\n    ".join([f"{{ {s} }}" for s in strings]))
        f.write("\n};\n")
        f.write('''
const bool SYMBOLS_INCLUDED = true;
      
fn SymbolResult resolve_internal(uptr addr) @private {
    SymbolEntry entry = {0x0, "(unknown)"};

    for (usz i=0; i<KERNEL_SYMS.len && KERNEL_SYMS[i].addr < addr; i++) {
        entry = KERNEL_SYMS[i];
    }

    return {entry.name, addr-entry.addr};
}

        ''')

if __name__ == '__main__':
    main()