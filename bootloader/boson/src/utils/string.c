#include <utils/string.h>
#include <null.h>
#include <int.h>
#include <size.h>
#include <wchar.h>
#include <vargs.h>

char tbuf[32] = {0};
char bchars[] = {'0','1','2','3','4','5','6','7','8','9',
    'A','B','C','D','E','F'};

unsigned int strlen(const char* str) {
    int l;
    for(l=0; str[l]!='\0'; l++);
    return l;
}

unsigned int strlenw(const WChar16* str) {
    int l;
    for(l=0; str[l]!='\0'; l++);
    return l;
}

char* ltoa(UInt64 i, unsigned base, char* buf) {
    int pos = 0;
    int opos = 0;
    int top = 0;

    if (i == 0 || base > 16) {
        buf[0] = '0';
        buf[1] = '\0';
        return null;
    }

    while (i != 0) {
        tbuf[pos] = bchars[i % base];
        pos++;
        i /= base;
    }

    top=pos--;
    for (opos = 0; opos < top; pos--, opos++) {
        buf[opos] = tbuf[pos];
    }
    buf[opos] = 0;

    return buf;
}

void ltoa_s(Int64 i, unsigned base, char* buf) {
    if (base > 16) return;
    if (i < 0) {
        *buf++ = '-';
        i *= -1;
    }
    ltoa(i, base, buf);
}

WChar16* vstrf(const char* istr, WChar16* buffer, VAList args) {
    if (!istr) return 0;

    WChar16* bufferPtr = buffer;
    Size i = 0;

    while (istr[i] != '\0') {
        switch (istr[i]) {
            case '%':
                switch (istr[i+1]) {
                    case 'w': {
                        WChar16* c = VAARG(args, WChar16*);

                        for (int j=0; j < strlenw(c); j++) {
                            *bufferPtr = c[j];
                            bufferPtr++;
                        }

                        i++;
                        break;
                    }

                    case 's': {
                        char* c = VAARG(args, char*);

                        for (int j=0; j < strlen(c); j++) {
                            *bufferPtr = (WChar16)c[j];
                            bufferPtr++;
                        }

                        i++;
                        break;
                    }

                    case 'u': {
                        UInt64 c = VAARG(args, UInt64);
                        char str[32] = {0};

                        ltoa(c, 10, str);

                        for (int j=0; j < strlen(str); j++) {
                            *bufferPtr = (WChar16)str[j];
                            bufferPtr++;
                        }

                        i++;
                        break;
                    }

                    case 'd':
                    case 'i': {
                        Int64 c = VAARG(args, Int64);
                        char str[32] = {0};

                        ltoa_s(c, 10, str);

                        for (int j=0; j < strlen(str); j++) {
                            *bufferPtr = (WChar16)str[j];
                            bufferPtr++;
                        }

                        i++;
                        break;
                    }

                    case 'X':
                    case 'x': {
                        UInt64 c = VAARG(args, UInt64);
                        char str[32] = {0};

                        ltoa(c, 16, str);

                        *bufferPtr++ = L'0';
                        *bufferPtr++ = L'x';
                        for (int j=0; j < strlen(str); j++) {
                            *bufferPtr = (WChar16)str[j];
                            bufferPtr++;
                        }

                        i++;
                        break;
                    }

                    case 'b': {
                        Int64 c = VAARG(args, Int64);
                        char str[128] = {0};

                        ltoa(c, 2, str);

                        for (int j=0; j < strlen(str); j++) {
                            *bufferPtr = (WChar16)str[j];
                            bufferPtr++;
                        }

                        i++;
                        break;
                    }
                    default:
                        VAEND(args);
                        return (WChar16*)1;
                }
                break;

            default:
                *bufferPtr = (WChar16)istr[i];
                bufferPtr++;
                break;
        }
        i++;
    }

    *bufferPtr = L'\0';
    VAEND(args);
    return buffer;
}
