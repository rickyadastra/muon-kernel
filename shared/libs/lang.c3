module lang;

alias CInt = int;

enum TypeKind : char {
	VOID,
	BOOL,
	SIGNED_INT,
	UNSIGNED_INT,
	FLOAT,
	TYPEID,
	FAULT,
	ANY,
	ENUM,
	CONST_ENUM,
	STRUCT,
	UNION,
	BITSTRUCT,
	FUNC,
	OPTIONAL,
	ARRAY,
	SLICE,
	VECTOR,
	DISTINCT,
	POINTER,
	INTERFACE,
}

faultdef TYPE_MISMATCH @builtin;

macro any.as_inner(&self) {
	return $$any_make(self.ptr, self.type.inner);
}

macro anycast(any v, $Type) @builtin {
	if (v.type != $Type.typeid) return TYPE_MISMATCH?;
	return ($Type*)v.ptr;
}

fn void* memcpy(void* dest, void* src, usz n) @extern("memcpy") @nostrip {
	for (usz i = 0; i < n; i++) ((char*)dest)[i] = ((char*)src)[i];
	return dest;
}

fn void* memmove(void* dest, void* src, usz n) @extern("memmove") @nostrip {
	return memcpy(dest, src, n) @inline;
}

fn void* memset(void* dest, CInt value, usz n) @extern("memset") @nostrip {
	for (usz i = 0; i < n; i++) ((char*)dest)[i] = (char)value;
	return dest;
}

<*
 @param expr : "the expression to cast"
 @param $Type : "the type to cast to"

 @require $sizeof(expr) == $Type.sizeof : "Cannot bitcast between types of different size."
 @ensure $typeof(return) == $Type*
*>
macro bitcast(expr, $Type) @builtin {
	$if $Type.alignof <= $alignof(expr):
		return *($Type*)&expr;
	$else
		$Type x @noinit;
		$$memcpy(&x, &expr, $sizeof(expr), false, $Type.alignof, $alignof(expr));
		return x;
	$endif
}

extern char[] __init_array_start;
extern char[] __init_array_end;

alias DynamicRegisterFn = fn void();

fn void init_runtime() {
    usz count = ((ulong)&__init_array_end - (ulong)&__init_array_start) / DynamicRegisterFn.sizeof;
    DynamicRegisterFn[] initArray = ((DynamicRegisterFn*)&__init_array_start)[:count];

    foreach (DynamicRegisterFn func : initArray) {
        func();
    }
}
