module dev::port;

macro out8(ushort port, char data) @private {
    asm {
        movw $dx, port;
        movb $al, data;
    }
    asm("out %al, %dx");
}

macro out16(ushort port, ushort data) @private {
    asm {
        movw $dx, port;
        movw $ax, data;
    }
    asm("out %ax, %dx");
}

macro out32(ushort port, uint data) @private {
    asm {
        movw $dx, port;
        movl $eax, data;
    }
    asm("out %eax, %dx");
}

macro char in8(ushort port) @private {
    char data;
    asm {
        movw $dx, port;
        in data, $dx;
    }
    return data;
}

macro ushort in16(ushort port) @private {
    ushort data;
    asm {
        movw $dx, port;
        in data, $dx;
    }
    return data;
}

macro uint in32(ushort port) @private {
    uint data;
    asm {
        movw $dx, port;
        in data, $dx;
    }
    return data;
}
