module muon::test @feat(TEST_ENABLED);

import muon::log;
import dev::port;

import std::atomic;

struct TestRunnerContext {
	usz totalCount;
	Atomic{usz} currentTest;
	Atomic{usz} runCount;
	Atomic{usz} successCount;
	Atomic{usz} failedCount;
	Atomic{bool} didLastFail;
}

alias TestFn = fn void();

TestRunnerContext context @local;
Port isaDebugPort @local = 0xf4;

fn bool run_all(String[] tests) {
	context.totalCount = tests.len;

	foreach (usz i, TestFn testfn : $$TEST_FNS) {
		context.currentTest.store(i);
		context.didLastFail.store(false);

		testfn();

		if (!context.didLastFail.load()) {
			log::info("[PASS] Test %s passed", $$TEST_NAMES[context.currentTest.load()]);
			context.successCount.increment();
		}

		context.runCount.increment();
	}

	usz run = context.runCount.load();
	usz failed = context.failedCount.load();
	usz success = context.successCount.load();
	double fraction = run > 0 ? success / (double)run : 0;

	log::info("Integration test complete. Ran %d/%d tests, %f%% successful (%d failed)", 
		run, context.totalCount, fraction * 100.0, failed);

	return success == context.totalCount;
}

macro run_all_and_exit(String[] tests) {
	bool b = run_all(tests);
	isaDebugPort.out8(0x0, b ? 0 : 1);
}

macro print_fail(String $msg) {
	log::error("[FAIL] Test %s failed on " +++ $msg, $$TEST_NAMES[context.currentTest.load()]);
}

macro @expect(#cond) {
	if (!#cond) {
		print_fail("@expect(" +++ $stringify(#cond) +++ ")");
		context.failedCount.increment();
		context.didLastFail.store(true);
		return;
	}
}
