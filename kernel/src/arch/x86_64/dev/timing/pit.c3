module dev::timing::pit;

import dev::port;

const char PIT_PORT = 0x40;
const char LOHI_SWSTROBE = 0x38;    // read high/low bytes, set software strobe interrupt mode

enum PortOffset : const inline char {
    CHANNEL_0       = 0x00,
    CHANNEL_1       = 0x01,
    CHANNEL_2       = 0x02,
    MODE_COMMAND    = 0x03,
}

Port pit = PIT_PORT;

macro void disable() {
    pit.out8(PortOffset.MODE_COMMAND, LOHI_SWSTROBE);
    pit.out8(PortOffset.CHANNEL_0, char.max);
    pit.in8(PortOffset.CHANNEL_0);
}
