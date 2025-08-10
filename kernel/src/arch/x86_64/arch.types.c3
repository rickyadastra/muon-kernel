module arch;

enum PrivilegeLevel : char {
    KERNEL,
    LEVEL_1,
    LEVEL_2,
    USER,
}

alias Register = ulong;
