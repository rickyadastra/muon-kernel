module muon::demo::shell;

import muon;
import process;
import dev;
import string;

const String PROMPT = "muon> ";

fn int shell_main(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    logging::printn("Shell started. Terminal handle is %x", termHandle);

    term::clear(termHandle)!!;

    while (true) {
        term::print(termHandle, PROMPT, textColor: term::Color.CYAN)!!;
        term::set_color(termHandle, textColor: term::Color.WHITE)!!;
        String? line = term::read_line(termHandle);
        term::reset_color(termHandle)!!;

        if (catch f = line) {
            if (f == term::BREAK_SIGNAL) {
                term::print_newline(termHandle)!!;
                term::printn(termHandle, "Shell terminated via break sequence. Bye bye!")!!;
                break;
            }

        } else {
            if (line.len > 0) {
                logging::printn("shell received cmd: %s", line);
                switch (line) {
                    case "clear":
                        term::clear(termHandle)!!;

                    case "time":
                        Handle procHandle = process::create((EntryPointFn)&shell_time)!!;
                        process::set_aux_handle(procHandle, 0, termHandle)!!;
                        process::start(procHandle)!!;
                        process::wait(procHandle)!!;

                    default:
                        term::print(termHandle, "Comando sconosciuto: ")!!;
                        term::print(termHandle, line)!!;
                        term::print_newline(termHandle)!!;
                }
            }
        } 
    }

    logging::printn("Shell exited");
    return 0;
}

fn int shell_time(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    logging::printn("Time program started");

    ulong time = timing::get_current();
    Formatter formatter;
    String s = formatter.format("Unix time attuale: %d", time)!!;
    term::printn(termHandle, s)!!;

    logging::printn("Time program exited");
    return 0;
}
