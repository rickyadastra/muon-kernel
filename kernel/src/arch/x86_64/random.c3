module random;

import arch::cpu;

faultdef RAND_FAIL, RAND_NOT_AVAIL, RAND_AVAIL_NOT_SET;

const usz MAX_RDRAND_RETRIES = 10;
bool? rdrandAvail = RAND_AVAIL_NOT_SET?;

fn ulong? rdrand64() @local {
    ulong rand;
    char valid;

    for (usz i=0; i<MAX_RDRAND_RETRIES; i++) {
        asm("rdrand %rax");
        asm("setc %ch");
        asm { 
            movb valid, $ch;
            movq rand, $rax; 
        }

        if (valid) break;
    }

    return valid ? rand : RAND_FAIL?;
}

fn ulong? random() {
    if (try rdrandAvail) {
        if (!rdrandAvail) return RAND_NOT_AVAIL?;
    } else {
        rdrandAvail = cpuid::query_feature(RDRAND_SUPPORT)!;
    }

    return rdrand64();
}
