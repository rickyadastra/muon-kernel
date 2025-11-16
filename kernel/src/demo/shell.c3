module muon::demo::shell;

import muon;
import process;
import dev;
import string;
import env;

const String PROMPT = "muon> ";

fn int shell_main(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    logging::printn("Shell started. Terminal handle is %x", termHandle);

    term::clear(termHandle)!!;
                                            
    term::printn(termHandle, "                      _                   _ ")!!;
    term::printn(termHandle, " _____ _ _ ___ ___   | |_ ___ ___ ___ ___| |")!!;
    term::printn(termHandle, "|     | | | . |   |  | '_| -_|  _|   | -_| |")!!;
    term::printn(termHandle, "|_|_|_|___|___|_|_|  |_,_|___|_| |_|_|___|_|")!!;
    term::printn(termHandle, "                                            ")!!;
    term::printn(termHandle, "muon kernel shell (mush) - Version " +++ muon::VERSION)!!;
    term::printn(termHandle, "Type 'help' for a list of available commands.\n")!!;

    process::sleep_ms(1500)!!;

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
                logging::printn("Shell received cmd: %s", line);
                switch (line) {
                    case "clear":
                        term::clear(termHandle)!!;

                    case "exit":
                        term::printn(termHandle, "Shell terminated via 'exit' command. Bye bye!")!!;
                        process::exit();

                    case "time":
                        @run_program(shell_time, termHandle);

                    default:
                        term::print(termHandle, "Unknown command: ")!!;
                        term::print(termHandle, line)!!;
                        term::print_newline(termHandle)!!;
                }
            }
        }
    }

    logging::printn("Shell exited");
    return 0;
}

macro @run_program(#f, #termHandle) {
    Handle procHandle = process::create((EntryPointFn)&#f)!!;
    process::set_aux_handle(procHandle, 0, #termHandle)!!;
    process::start(procHandle)!!;
    process::wait(procHandle)!!;
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
