#include "efi/efi.h"
#include <utils/string.h>

__attribute__((used, optnone))
void memcpy(char* to, const char* from, Size size) {
    for (Size i=0; i<size; i++) {
        to[i] = from[i];
    }
}

__attribute__((used, optnone))
int memcmp(const void *str1, const void *str2, Size count) {
  const unsigned char *s1 = str1;
  const unsigned char *s2 = str2;

  while (count-- > 0)
    {
      if (*s1++ != *s2++)
	  return s1[-1] < s2[-1] ? -1 : 1;
    }
  return 0;
}

Bool compare_guid(const EfiGUID* a, const EfiGUID* b) {
    return a->TimeLow == b->TimeLow &&
           a->TimeMid == b->TimeMid &&
           a->TimeHighAndVersion == b->TimeHighAndVersion &&
           memcmp(a->Data, b->Data, 8) == 0;
}
