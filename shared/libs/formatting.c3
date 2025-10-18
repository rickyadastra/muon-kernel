module string::formatting;

import lang;
import std::math;

const usz INTERNAL_BUFFER_SIZE = 1024;
const usz INTERNAL_FORMAT_BUFFER_SIZE = 128;
const char[*] DIGITS = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};

faultdef BAD_VALUE, FORMAT_BUFFER_EXCEEDED, INTERNAL_BUFFER_EXCEEDED, MISSING_ARGUMENT;

struct Formatter {
    char[INTERNAL_BUFFER_SIZE] buffer;
    usz base;
}

<*
    @param [in] arg
    @param [out] negative
    @param [out] type
*>
fn ulong? any_to_decimal(any arg, bool* negative, typeid* type) {
    ulong value = 0;
    *negative = false;

    switch (arg.type.kindof) {
        case TypeKind.FUNC.ordinal:
        case TypeKind.POINTER.ordinal:
            return (ulong)(uptr)*(void**)arg.ptr;
        case TypeKind.DISTINCT.ordinal:
        case TypeKind.BITSTRUCT.ordinal:
        case TypeKind.CONST_ENUM.ordinal: 
            return any_to_decimal(arg.as_inner(), negative, type)!;
        default:
            switch (arg.type) {
                case bool: 
                    value = (ulong)*(bool*)arg;
                case ichar: 
                    value = *(ichar*)arg;
                    *negative = (ichar)value < 0;
                case char: 
                    value = *(char*)arg;
                case short: 
                    value = *(short*)arg;
                    *negative = (short)value < 0;
                case ushort: 
                    value = *(ushort*)arg;
                case int: 
                    value = *(int*)arg;
                    *negative = (int)value < 0;
                case uint: 
                    value = *(uint*)arg;
                case long: 
                    value = *(long*)arg;
                    *negative = (long)value < 0;
                case ulong: 
                    value = *(ulong*)arg;
                case float:
                    value = (ulong)*(float*)arg;
                    *negative = (float)value < 0;
                case double:
                    value = (ulong)*(double*)arg;
                    *negative = (double)value < 0;
                default: 
                    return BAD_VALUE?;
            }
    }

    *type = arg.type;
    return value;
}

<*
    @param [in] arg
    @param [out] type
*>
fn double? any_to_float(any arg, typeid* type) {
    double value = 0;

    switch (arg.type.kindof) {
        case TypeKind.DISTINCT.ordinal:
        case TypeKind.CONST_ENUM.ordinal: 
            return any_to_float(arg.as_inner(), type)!;
        default:
            switch (arg.type) {
                case bool: 
                    value = (double)*(bool*)arg;
                case ichar: 
                    value = *(ichar*)arg;
                case char: 
                    value = *(char*)arg;
                case short: 
                    value = *(short*)arg;
                case ushort: 
                    value = *(ushort*)arg;
                case int: 
                    value = *(int*)arg;
                case uint: 
                    value = *(uint*)arg;
                case long: 
                    value = *(long*)arg;
                case ulong: 
                    value = *(ulong*)arg;
                case float:
                    value = (double)*(float*)arg;
                case double:
                    value = (double)*(double*)arg;
                default: 
                    return BAD_VALUE?;
            }
    }

    *type = arg.type;
    return value;
}

<*
    @param [in] arg
    @param [inout] buf
    @require base > 1, base <= 16
*>
fn usz? format_any_to_decimal(any arg, char[] buf, usz base = 10) {
    bool negative = false;
    typeid actualType = ulong.typeid;
    char[INTERNAL_FORMAT_BUFFER_SIZE] fmtBuf @noinit;
    ulong value = any_to_decimal(arg, &negative, &actualType)!;
    usz fmtLen = 0;

    if (negative) {
        if (arg.type == float.typeid) {
            value = (ulong)-((float)value);
        } else if (arg.type == double.typeid) {
            value = (ulong)-((double)value);
        } else {
            value = (~(ulong)value) + 1;
        }
    }

    do {
        fmtBuf[fmtLen++] = DIGITS[(char)(value % base)];
        value /= base;
    } while (value != 0);

    if (base == 16) {
        while (fmtLen < (actualType.sizeof*2)) {
            fmtBuf[fmtLen++] = '0';
        }
    }

    usz totalBufLen = fmtLen + (base != 10 ? 2 : 0) + (negative ? 1 : 0);
    if (totalBufLen > buf.len) return FORMAT_BUFFER_EXCEEDED?;

    usz j = 0;
    if (negative) {
        buf[j++] = '-';
    }
        
    switch {
        case base == 2:
            buf[j:2] = "0b"[..];
            j += 2;
        case base == 8:
            buf[j:2] = "0o"[..];
            j += 2;
        case base == 16:
            buf[j:2] = "0x"[..];
            j += 2;
    }
    
    for (int i = (int)fmtLen-1; i >= 0; i--, j++) {
        buf[j] = fmtBuf[i];
    }

    return totalBufLen;
}

fn char* fmt_u(ulong x, char* s) {
    for (; x > ulong.max; x /= 10) *--s = '0' + (char)(x % 10);
    for (ulong y = (ulong)x; y; y /= 10) *--s = '0' + (char)(y % 10);
    return s;
}

enum FloatFormatting @local {
    ADAPTIVE,
    EXPONENTIAL,
    FLOAT,
}

fn usz? format_any_to_float(any arg, char[] buf, FloatFormatting formatting = ADAPTIVE) {
    bool negative = false;
    typeid actualType = ulong.typeid;
    const BUF_SIZE = (math::DOUBLE_MANT_DIG + 28) / 29 + 1 + (math::DOUBLE_MAX_EXP + math::DOUBLE_MANT_DIG + 28 + 8) / 9;
    uint[BUF_SIZE] big;
    double value = any_to_float(arg, &actualType)!;

    // check sign
    if (math::signbit(value)) {
        negative = true;
        value = -value;
    }

    // handle nan/inf values
    if (!math::is_finite(value)) {
        String s = math::is_nan(value) ? "NaN" : "Inf";
        usz len = s.len + (negative ? 1 : 0);

        if (negative) {
            buf[0] = '-';
            buf[1..] = s[..];
        } else {
            buf[:len] = s[..];
        }

        return len;
    }

    int exponent2;
    isz precision = 6;
    double mantix = math::frexp(value, &exponent2) * 2;

    if (mantix) exponent2--;
    
    char[12] ebuf;
    char* ebufPtr = 12 + (char*)&ebuf;
    char[9 + math::DOUBLE_MANT_DIG / 4] mbuf;
    char* mbufPtr = &mbuf;

    if (mantix) {
        mantix *= 0x1p28;
        exponent2 -= 28;
    }

    uint* a, z, r;
    if (exponent2 < 0) {
        a = r = z = &big;
    } else {
        a = r = z = (uint*)&big + big.len - math::DOUBLE_MANT_DIG - 1;
    }

    // convert mantix to big decimal blocks
    do {
        uint v = z++[0] = (uint)mantix;
        mantix = 1000000000 * (mantix - v);
    } while (mantix);

    // positive exponent
    while (exponent2 > 0) {
        uint carry = 0;
        int sh = math::min(29, exponent2);

        for (uint* d = z - 1; d >= a; d--) {
            ulong x = (ulong)*d << sh + carry;
            *d = (uint)(x % 1000000000);
            carry = (uint)(x / 1000000000);
        }

        if (carry) *--a = carry;
        while (z > a && !z[-1]) z--;
        exponent2 -= sh;
    }

    // negative exponent
    while (exponent2 < 0) {
        uint carry = 0;
        uint* b;
        int sh = math::min(9, -exponent2);
        int need = (int)(1 + (precision + math::DOUBLE_MANT_DIG / 3u + 8) / 9);

        for (uint* d = a; d < z; d++) {
            uint rm = *d & ((1 << sh) - 1);
            *d = (*d >> sh) + carry;
            carry = (1000000000 >> sh) * rm;
        }

        if (!a[0]) a++;
        if (carry) z++[0] = carry;
        b = a;
        if (z - b > need) z = b + need;
        exponent2 += sh;
    }

    // compute decimal exponent
    int exponent;
    if (a < z) {
        for (int i = 10, exponent = (int)(9 * (r - a)); *a >= i; i *= 10, exponent++);
    }

    // pick best formatting
    if (formatting == ADAPTIVE) {
        if (!precision) precision++;
        if (precision > exponent && exponent >= -4) {
            formatting = FLOAT;
            precision -= (isz)exponent + 1;
        
        } else {
            formatting = EXPONENTIAL;
            precision--;
        }
    }

    // round algorithm 
    int j = (int)(precision - (isz)(formatting == FLOAT ? 0 : exponent));
    if (j < 9 * (z - r - 1)) {
        uint x;
        // avoid C's broken division of negative numbers
        uint* d = r + 1 + ((j + 9 * math::DOUBLE_MAX_EXP) / 9 - math::DOUBLE_MAX_EXP);
        j += 9 * math::DOUBLE_MAX_EXP;
        j %= 9;
        int i;
        for (i = 10, j++; j < 9; i *= 10, j++);
        x = *d % i;

        // are there any significant digits past j?
        if (x || (d + 1) != z) {
            double round = 2 / math::DOUBLE_EPSILON;
            double small;

            if (((*d / i) & 1) || (i == 1000000000 && d > a && (d[-1] & 1))) {
                round += 2;
            }

            switch {
                case x < i / 2:
                    small = 0x0.8p0;
                case x == i / 2 && d + 1 == z:
                    small = 0x1.0p0;
                default:
                    small = 0x1.8p0;
            }

            if (negative) {
                round *= -1;
                small *= -1;
            }
            *d -= x;

            // decide whether to round by probing round+small
            if (round + small != round) {
                *d = *d + i;

                while (*d > 999999999) {
                    *d-- = 0;
                    if (d < a) *--a = 0;
                    (*d)++;
                }

                for (i = 10, exponent = (int)(9 * (r - a)); *a >= i; i *= 10, exponent++);
            }
        }

        if (z > d + 1) z = d + 1;
    }

    // remove trailing zeros
    for (; z>a && !z[-1]; z--);

    // Count trailing zeros in last place
    if (z > a && z[-1]) {
        for (int i = 10, j = 0; z[-1] % i == 0; i *= 10, j++);
    } else {
        j = 9;
    }

    if (formatting == FLOAT) {
        precision = math::min(precision, math::max((isz)0, 9 * (z - r - 1) - j));
    } else {
        precision = math::min(precision, math::max((isz)0, 9 * (z - r - 1) + exponent - j));
    }
    
    if (precision > int.max - 1 - (isz)(precision ? 1 : 0)) return INTERNAL_BUFFER_EXCEEDED?;
    int l = (int)(1 + precision + (isz)(precision ? 1 : 0));
    char* estr @noinit;

    if (formatting == FLOAT) {
        if (exponent > int.max - l) return INTERNAL_BUFFER_EXCEEDED?;
        if (exponent > 0) l += exponent;
    } else {
        estr = fmt_u((ulong)(exponent < 0 ? -exponent : exponent), ebufPtr);
        while (ebufPtr - estr < 2) (--estr)[0] = '0';

        if (exponent < 0) *--estr = '-';
        *--estr = 'e';
        
        if (ebufPtr - estr > (isz)int.max - l) return INTERNAL_BUFFER_EXCEEDED?;
        l += (int)(ebufPtr - estr);
    }

    if (l > int.max - (negative ? 1 : 0)) return INTERNAL_BUFFER_EXCEEDED?;
    usz len = 0;
    
    if (negative) buf[len++] = '-';

    if (formatting == FLOAT) {
        if (a > r) a = r;
        uint*d = a;
        for (; d <= r; d++) {
            char* s = fmt_u(*d, mbufPtr + 9);
            switch {
                case d != a:
                    while (s > mbufPtr) *--s = '0';
                case s == mbufPtr + 9:
                    *--s = '0';
            }

            usz tlen = mbufPtr + 9 - s;
            buf[len:tlen] = s[:tlen];
            len += tlen;
        }

        if (precision) buf[len++] = '.';

        for (; d < z && precision > 0; d++, precision -= 9) {
            char* s = fmt_u(*d, mbufPtr + 9);
            while (s > mbufPtr) *--s = '0';
            
            usz tlen = math::min((isz)9, precision);
            buf[len:tlen] = s[:tlen];
            len += tlen;
        }

    } else {
        if (z <= a) z = a + 1;
        for (uint* d = a; d < z && precision >= 0; d++) {
            char* s = fmt_u(*d, mbufPtr + 9);
            
            if (s == mbufPtr + 9) *--s = '0';
            if (d != a) {
                while (s > mbufPtr) *--s = '0';
            } else {
                buf[len++] = s++[0];
                if (precision > 0) buf[len++] = '.';
            }

            usz dlen = math::min(mbufPtr + 9 - s, precision);
            buf[len:dlen] = s[:dlen];
            len += dlen;
            
            precision -= mbufPtr + 9 - s;
        }

        usz elen = ebufPtr - estr;
        buf[len:elen] = estr[:elen];
        len += elen;
    }

    return len;
}

macro any? @get_arg(#args, #i) {
    if (#i >= #args.len) return MISSING_ARGUMENT?;
    return #args[#i++]; 
}

fn String? Formatter.format(Formatter* self, String format, args...) {    
    usz len = 0;
    usz va_i = 0;

    if (format.len == 0) return "";

    for (usz i = 0; i < format.len; i++) {
        char c = format[i];
        self.base = 10;
        
        if (c != '%') {
            self.buffer[len++] = c;
            continue;
        } 

        // previous character is %
        c = format[++i];
        if (c == '%') {
            self.buffer[len++] = c;
            continue;
        }

        switch (c) {
            case 'o':
                self.base = 8;
                nextcase 'd';
            case 'b':
                self.base = 2;
                nextcase 'd';
            case 'p':
            case 'x': 
                self.base = 16;
                nextcase 'd';
            case 'd':
                len += format_any_to_decimal(@get_arg(args, va_i), self.buffer[len..], base: self.base)!;
            case 'f':
                len += format_any_to_float(@get_arg(args, va_i), self.buffer[len..])!;
            case 'c':
                char arg = *(char*)@get_arg(args, va_i)!;
                if (len + 1 > INTERNAL_BUFFER_SIZE) return INTERNAL_BUFFER_EXCEEDED?;
                self.buffer[len++:1] = arg;
            case 's':
                String arg = *(String*)@get_arg(args, va_i)!;
                if (len + arg.len > INTERNAL_BUFFER_SIZE) return INTERNAL_BUFFER_EXCEEDED?;
                self.buffer[len:arg.len] = arg[..];
                len += arg.len;
            default:
                if (len + 2 > INTERNAL_BUFFER_SIZE) return INTERNAL_BUFFER_EXCEEDED?;
                self.buffer[len:2] = ((char[2]){'%', c})[..];
                len += 2;

        }
    }
    
    return (String)self.buffer[..len-1];
}
