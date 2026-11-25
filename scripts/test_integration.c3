import std::io;
import std::io::file;
import std::os::process;
import std::core::string;

struct CommandOutput {
	int exitCode;
	String output;
}

fn CommandOutput run_command(String[] cmd) {
	SpawnOptions opts = SpawnOptions.INHERIT_ENV | SpawnOptions.STDERR_TO_STDOUT;
	Process? proc = process::spawn(cmd, opts, out: process::CAPTURE);
	if (catch proc) {
		return { -1, "Failed to launch process" };
	}
	Process p = proc;
	defer (void)p.destroy();

	DString output = dstring::new(tmem);
	char[4096] buf;
	while (true) {
		sz? n = p.read_stdout(&buf[0], buf.len);
		if (catch n) break;
		if (n <= 0) break;
		output.append((String)buf[:n]);
	}

	int exitCode = p.join() ?? -1;
	return { exitCode, output.str_view() };
}

fn bool execute_step(String step_name, String[] cmd) {
	CommandOutput res = run_command(cmd);
	if (res.exitCode != 0) {
		io::eprintfn("[FAIL] Error during '%s' (exit code %d):", step_name, res.exitCode);
		if (res.output.len > 0) {
			io::eprintn(res.output);
		}
		return false;
	}
	return true;
}

fn void cleanup_temp_files() {
	(void)file::delete("fat-test.img");
	(void)file::delete("test-result.log");
}

fn int main(String[] args) {
	defer cleanup_temp_files();

	// 1. Compile kernel with integration tests
	String[] compile_cmd = {
		"c3c", "compile",
		"--trust=full",
		"--use-stdlib=no",
		"--link-libc=no",
		"--warn-builtin=no",
		"--x86cpu=baseline",
		"--linker=builtin",
		"--no-entry",
		"--testfn", "muon::test::run_all",
		"--panicfn", "muon::panicfn",
		"--target", "elf-x64",
		"--lib", "boson_protocol",
		"--libdir", "boot/boson/lib",
		"--sources", "kernel/**", "boot/boot.c3i", "boot/adapters/boson.c3", "libs/**", "test/**",
		"--build-dir", ".build/muon",
		"--output-dir", ".build/muon",
		"-o", "muon-test.elf",
		"-D", "BOOT_BOSON",
		"-D", "LOG_INFO",
		"-D", "ANSI_COLORS_NO",
		"-D", "ARCH_X86_64",
		"-D", "TEST_ENABLED",
		"-z", "-Tscripts/x86_64.ld",
		"-z", "-zmax-page-size=0x1000",
		"-z", "-ztext",
		"--testing"
	};

	if (!execute_step("Compiling kernel with integration tests", compile_cmd)) {
		return 1;
	}

	// 2. Strip test ELF
	String[] strip_cmd = {
		"strip", ".build/muon/muon-test.elf"
	};
	if (!execute_step("Stripping muon-test.elf", strip_cmd)) {
		return 1;
	}

	// 3. Compile boson bootloader
	String[] make_cmd = {
		"make", "-C", "boot/boson", "BUILD_DIR=../../.build/boson"
	};
	if (!execute_step("Compiling boson bootloader", make_cmd)) {
		return 1;
	}

	// 4. Create and populate fat-test.img
	String[] dd_cmd = { "dd", "if=/dev/zero", "of=fat-test.img", "bs=1k", "count=1440" };
	if (!execute_step("Creating fat-test.img", dd_cmd)) {
		return 1;
	}

	String[] mformat_cmd = { "mformat", "-i", "fat-test.img", "-f", "1440", "::" };
	if (!execute_step("Formatting fat-test.img", mformat_cmd)) {
		return 1;
	}

	String[] mmd_efi_cmd = { "mmd", "-i", "fat-test.img", "::/EFI" };
	if (!execute_step("Creating /EFI directory", mmd_efi_cmd)) {
		return 1;
	}

	String[] mmd_boot_cmd = { "mmd", "-i", "fat-test.img", "::/EFI/BOOT" };
	if (!execute_step("Creating /EFI/BOOT directory", mmd_boot_cmd)) {
		return 1;
	}

	String[] mcopy_boot_cmd = { "mcopy", "-i", "fat-test.img", ".build/boson/boson.efi", "::/EFI/BOOT/BOOTX64.EFI" };
	if (!execute_step("Copying BOOTX64.EFI", mcopy_boot_cmd)) {
		return 1;
	}

	String[] mcopy_sys_cmd = { "mcopy", "-i", "fat-test.img", ".build/muon/muon-test.elf", "::/EFI/BOOT/muon.sys" };
	if (!execute_step("Copying muon.sys", mcopy_sys_cmd)) {
		return 1;
	}

	// 5. Launch QEMU
	String[] qemu_cmd = {
		"qemu-system-x86_64",
		"-bios", "/usr/share/ovmf/OVMF.fd",
		"-net", "none",
		"-m", "1G",
		"-enable-kvm",
		"-cpu", "host",
		"-serial", "file:test-result.log",
		"-nographic",
		"-no-reboot",
		"-device", "isa-debug-exit,iobase=0xf4,iosize=0x04",
		"-drive", "file=fat-test.img,format=raw",
		"-monitor", "none"
	};

	CommandOutput qemu_res = run_command(qemu_cmd);
	if (qemu_res.exitCode == -1) {
		io::eprintfn("[FAIL] Failed to launch QEMU: %s", qemu_res.output);
		return 1;
	}

	// 6. Inspect test-result.log
	if (!file::exists("test-result.log")) {
		io::eprintn("[FAIL] Integration tests aborted (kernel crash or timeout)");
		return 1;
	}

	char[]? log_data = file::load_temp("test-result.log");
	if (catch log_data) {
		io::eprintn("[FAIL] Integration tests aborted (unable to read test-result.log)");
		return 1;
	}

	String content = (String)log_data;
	String[] lines = content.tsplit("\n");

	bool has_done = false;
	String done_line = "";
	bool has_failures = false;

	foreach (String line : lines) {
		if (!line.contains("[muon::test]")) continue;

		if (line.contains("[FAIL]")) {
			has_failures = true;
			io::eprintn(line);
		}

		if (line.contains("[DONE]")) {
			has_done = true;
			done_line = line;
		}
	}

	if (!has_done) {
		io::eprintn("[FAIL] Integration tests aborted (kernel crash or timeout)");
		return 1;
	}

	if (has_failures) {
		return 1;
	}

	// Print minimal summary
	if (try idx = done_line.index_of("[DONE]")) {
		io::printn(done_line[idx..]);
	} else {
		io::printn(done_line);
	}

	return 0;
}
