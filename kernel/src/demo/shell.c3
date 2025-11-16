module muon::demo::shell;

import muon;
import process;
import dev;
import string;
import env;

const String PROMPT = "muon> ";
const usz MAX_TOKENS = 64;

String[MAX_TOKENS] tokens;

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
            usz toks = tokenize_line(line, &tokens);
            String[] cmdTokens = tokens[:toks];

            if (cmdTokens.len == 0) continue;
            String cmd = cmdTokens[0];

            logging::printn("Shell received cmd: %s", cmd);

            switch (cmd) {
                case "clear":
                    term::clear(termHandle)!!;

                case "exit":
                    term::printn(termHandle, "Shell terminated via 'exit' command. Bye bye!")!!;
                    process::exit();

                case "time":
                    @run_program(programs::time, termHandle, line);

                case "sleep":
                    @run_program(programs::sleep, termHandle, line);

                case "shutdown":
                    term::printn(termHandle, "* This only works on QEMU and VirtualBox. If nothing happens, you know why.")!!;
                    term::printn(termHandle, "Shutting down...")!!;
                    Port shutdownPort;
                    logging::printn("Trying QEMU/Bochs shutdown port...");
                    shutdownPort.out16(0xb004, 0x2000); // qemu
                    process::sleep_ms(100)!!;

                    logging::printn("Trying VirtualBox shutdown port...");
                    shutdownPort.out16(0x4004, 0x3400); // virtualbox
                    process::sleep_ms(100)!!;

                case "rand":
                    @run_program(programs::random, termHandle, line);

                case "info":
                    @print_shell_info(termHandle);

                case "help":
                    @print_shell_info(termHandle);
                    term::print_newline(termHandle)!!;
                    term::printn(termHandle, " clear                Clear the screen")!!;
                    term::printn(termHandle, " exit                 Exit the shell (also Ctrl+C)")!!;
                    term::printn(termHandle, " help                 Display this message")!!;
                    term::printn(termHandle, " info                 Display info about the kernel")!!;
                    term::printn(termHandle, " rand [min] [max]     Run a program that returns a random numeric value")!!;
                    term::printn(termHandle, " shutdown             Shutdown the computer (only on QEMU and VirtualBox)")!!;
                    term::printn(termHandle, " sleep <time>         Run a program that sleeps for <time> seconds")!!;
                    term::printn(termHandle, " time                 Run a program that shows current time and uptime")!!;
                    term::print_newline(termHandle)!!;

                default:
                    term::print(termHandle, "Unknown command: ")!!;
                    term::print(termHandle, cmd)!!;
                    term::print_newline(termHandle)!!;
            }
        }
    }

    logging::printn("Shell exited");
    return 0;
}

macro @print_shell_info(#termHandle) {
    term::printn(#termHandle, "muon kernel shell (mush) - Version " +++ muon::VERSION +++ " for " +++ env::ARCH_TYPE.nameof)!!;
    term::printn(#termHandle, "Build " +++ muon::COMMIT_HASH +++ " @ " +++ $$DATE +++ " " +++ $$TIME)!!;
}

macro @run_program(#f, #termHandle, #cmdline) {
    Handle procHandle = process::create((EntryPointFn)&#f)!!;
    process::set_aux_handle(procHandle, 0, #termHandle)!!;
    process::set_command_line(procHandle, #cmdline)!!;
    process::start(procHandle)!!;
    int ret = process::wait(procHandle)!!;
    logging::printn("Program '%s' terminated with exit code: %d", $nameof(#f), ret);
}

fn usz tokenize_line(String line, String[MAX_TOKENS]* tokens) {
    usz tok, i, j;

    while (i < line.len && j < line.len && tok < (*tokens).len) {
        if (line[i] == ' ') {
            i++;
            continue;
        }

        if (line[j] == ' ' && j >= i) {
            (*tokens)[tok++] = line[i..j-1];
            i = j+1;
        }

        j++;
    }

    if (i < line.len) (*tokens)[tok++] = line[i..^1];

    return tok;
}

macro String[] @get_args(SpawnInfo* #info, String[MAX_TOKENS] #tokens) {
    usz toks = shell::tokenize_line(#info.commandLine, &#tokens);
    return #tokens[:toks];
}
