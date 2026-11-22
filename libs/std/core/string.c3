module std::core::string;

typedef String @constinit @weak = inline char[];
typedef ZString @constinit = inline char*;

<*
 View a ZString as a String, without copying.
 @param [&own] self
 @return "A String view of the same memory, not including the zero terminator"
*>
fn String ZString.str_view(self) {
	return (String)(self[:self.len()]);
}

<*
 @param [&in] self
 @return "The number of bytes before the zero terminator"
 @pure
*>
fn sz ZString.len(self) {
	sz len;
	for (char* ptr = (char*)self; *ptr; ptr++) len++;
	return len;
}
