module muon::demo::term;

import std::io;
import muon::authority;
import dev::serial;
import arch::mem;
import process;
import muon;
import lang;
import muon::sync @public;

faultdef BREAK_SIGNAL;

const char BREAK_KEY = 0x3;
const char RETURN_KEY = 0xd;
const char BACKSPACE_KEY = 0x8;
const char BACKSPACE_KEY_ALT = 0x7f;
const char PRINT_KEYS_START = 0x20;
const char PRINT_KEYS_END = 0x7e;

const usz LINEBUF_SIZE = 128;

const char ESCAPE_SEQ = 0x1b;
const String CLEAR_SCREEN = "[2J";
const String BACKSPACE = "[0K";

struct Terminal (KernelObject) {
    Serial* serial;
    RefCount refcount;
    char[LINEBUF_SIZE] linebuf;
}

enum Color : char (String fg, String bg) {
    BLACK   = {"30", "40"},
    RED     = {"31", "41"},
    GREEN   = {"32", "42"},
    BLUE    = {"33", "43"},
    BROWN   = {"34", "44"},
    MAGENTA = {"35", "45"},
    CYAN    = {"36", "46"},
    WHITE   = {"37", "47"},
}

fn usz Terminal.get_ref_count(&self) @dynamic => self.refcount.load();

fn void Terminal.track_ref(&self) @dynamic {
    usz v = self.refcount.increment()+1;
    logging::printn("Terminal@%x's refcount after track_ref(): %d", self, v);
}

fn void Terminal.drop_ref(&self) @dynamic {
    usz v = self.refcount.decrement()-1;
    logging::printn("Terminal@%x's refcount after drop_ref(): %d", self, v);
}

macro Terminal.begin_escape_seq(&self) => self.serial.put(ESCAPE_SEQ);
macro Terminal.print_newline(&self) => self.serial.write("\r\n");
macro Terminal.print_backspace(&self) => self.serial.write("\b");

fn void Terminal.send_escape_seq(&self, String seq) {
    self.begin_escape_seq();
    self.serial.write(seq);
}

fn void Terminal.clear(&self) {
    self.send_escape_seq(CLEAR_SCREEN);
}

fn void Terminal.set_color(&self, Color textColor, Color backgroundColor) {
    self.begin_escape_seq();
    self.serial.write("[1;");
    self.serial.write(textColor.fg);
    self.serial.put(';');
    self.serial.write(backgroundColor.bg);
    self.serial.put('m');
}

fn void Terminal.reset_color(&self) {
    self.begin_escape_seq();
    self.serial.write("[m");
}

fn void Terminal.print(&self, String str, Color textColor, Color backgroundColor) {
    if (backgroundColor != BLACK || textColor != WHITE) self.set_color(textColor, backgroundColor);
    self.serial.write(str);
    if (backgroundColor != BLACK || textColor != WHITE) self.reset_color();
}

fn String? Terminal.read_line(&self) {
    usz len = 0;

    while LOOP: (true) {
        char c = self.serial.get()!!;
        
        switch {
            case c == BREAK_KEY:
                self.serial.write("^C");
                return BREAK_SIGNAL?;

            case c == RETURN_KEY:
                self.print_newline();
                break LOOP;

            case c == BACKSPACE_KEY:
            case c == BACKSPACE_KEY_ALT:
                if (len > 0) {
                    self.print_backspace();
                    self.send_escape_seq(BACKSPACE);
                    len--;
                }
            
            case c >= PRINT_KEYS_START && c <= PRINT_KEYS_END:
                self.linebuf[len++] = c;
                self.serial.put(c);
        }
    }

    return (String)self.linebuf[:len];
}

macro Terminal*? resolve_handle_to_term(Handle handle, ObjectRights rights = {}) @local {
    KernelObject obj = handle::resolve(scheduler::get_current_task().handles, handle, (ObjectRights)rights)!;
    return anycast(obj, Terminal);
}

<*
    @require scheduler::get_current_task() != null
*>
fn Handle? create(SerialPort port) {
    Serial* serial = serial::of(port);
    serial.setup(port);
    serial.set_rx_buffer((SerialBuffer*)mem::alloc(SerialBuffer.sizeof));
    serial.set_semaphore(semaphore::alloc());
    serial.enable_rx();

    // alloc new terminal object
    Terminal* term = (Terminal*)mem::alloc(Terminal.sizeof);
    term.serial = serial;
    
    // create handle for terminal in current task
    Handle handle = scheduler::get_current_task().handles.insert(term, {})!;
    term.track_ref();

    // register object
    object::register(term);
    return handle;
}

fn void? clear(Handle handle) {
    Terminal* term = resolve_handle_to_term(handle)!;
    term.clear();
}

fn void? print(Handle handle, String str, Color textColor = WHITE, Color backgroundColor = BLACK) {
    Terminal* term = resolve_handle_to_term(handle)!;
    term.print(str, textColor, backgroundColor);
}

fn void? printn(Handle handle, String str, Color textColor = WHITE, Color backgroundColor = BLACK) {
    Terminal* term = resolve_handle_to_term(handle)!;
    term.print(str, textColor, backgroundColor);
    term.print_newline();
}

fn void? print_newline(Handle handle) {
    Terminal* term = resolve_handle_to_term(handle)!;
    term.print_newline();
}

fn String? read_line(Handle handle) {
    Terminal* term = resolve_handle_to_term(handle)!;
    return term.read_line();
}

fn void? set_color(Handle handle, Color textColor = WHITE, Color backgroundColor = BLACK) {
    Terminal* term = resolve_handle_to_term(handle)!;
    term.set_color(textColor, backgroundColor);
}

fn void? reset_color(Handle handle) {
    Terminal* term = resolve_handle_to_term(handle)!;
    term.reset_color();
}
