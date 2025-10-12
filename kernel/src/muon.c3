module muon;

import arch;
import boson;
import scheduler;

fn void kmain(BootloaderPayload* payload) {
    logging::init();

    arch::init(payload);

    scheduler::init()!!;
    muon::init();
    scheduler::start();
    
    idle();
}

fn void init() {
    task::spawn(&test)!!;
    task::spawn(&test2)!!;

    logging::printn("Muon init complete");
}

fn void test() @local {
    logging::printn("task 2 says hello world!");
    task::yield();
    logging::printn("task 2 says i wont crash no more");
}

fn void test2() @local {
    logging::printn("task 3 says hello world, again!");
    task::yield();
    logging::printn("task 3 says what will happen now?");
}

fn void idle() @local {
    while (true) arch::cpu::idle();
}

macro panic(String message) => arch::log_and_panic(message, $$FILE, $$FUNC, $$LINE);
