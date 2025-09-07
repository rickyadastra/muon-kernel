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

macro any.as_inner(&self) {
	return $$any_make(self.ptr, self.type.inner);
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
