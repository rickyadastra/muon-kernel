module string::formatting;

import lang;

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
*>
fn ulong? any_to_decimal(any arg, bool* negative) {
    ulong value = 0;
    *negative = false;

    switch (arg.type.kindof) {
        case TypeKind.FUNC.ordinal:
        case TypeKind.POINTER.ordinal:
            return (ulong)(uptr)*(void**)arg.ptr;
        case TypeKind.DISTINCT.ordinal:
        case TypeKind.CONST_ENUM.ordinal: 
            return any_to_decimal(arg.as_inner(), negative)!;
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

    return value;
}

<*
    @param [in] arg
    @param [inout] buf
    @require base > 1, base <= 16
*>
fn usz? format_any_to_decimal(any arg, char[] buf, usz base = 10) {
    bool negative = false;
    char[INTERNAL_FORMAT_BUFFER_SIZE] fmtBuf @noinit;
    ulong value = any_to_decimal(arg, &negative)!;
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

        if (value == 0) break;
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

macro any? @get_arg(#args, #i) {
    if (#i >= #args.len) return MISSING_ARGUMENT?;
    return #args[#i++]; 
}

fn String? Formatter.format(Formatter* self, String format, args...) {    
    usz len = 0;
    usz va_i = 0;

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
