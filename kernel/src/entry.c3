import dev::port;

fn void kstart() @export("kstart") {
    Port com1 = 0x3f8;

    com1.out8(1, 0x00);
    com1.out8(3, 0x80);
    com1.out8(0, 0x03);
    com1.out8(1, 0x00);
    com1.out8(3, 0x03);
    com1.out8(2, 0xc7);
    com1.out8(4, 0x0f);

    com1.out8(0, 'H');
    
    for (;;) {
        asm { nop; }
    }
}
