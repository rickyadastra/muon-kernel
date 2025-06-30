#include "size.h"
#include <utils/string.h>
#include <null.h>

__attribute__((used, optnone))
void memcpy(char* to, const char* from, Size size) {
    for (Size i=0; i<size; i++) {
        to[i] = from[i];
    }
}
