<*
    @require SIZE > 1
*>
module std::io::ringbuffer{SIZE};

import std::math;
import std::io::stream;

macro void @inc_modulo(#v, #amount = 1) @local => #v = (#v + #amount) % SIZE;

struct RingBuffer (IOStream) {
    char[SIZE] buffer;
    usz head;
    usz tail;
    usz count;
}

<*
    @ensure self.count >= 0, self.count <= SIZE
*>
fn void? RingBuffer.put(&self, char c) @dynamic {
    if (self.is_full()) return stream::FULL?;

    self.buffer[self.head] = c;

    @inc_modulo(self.head);
    self.count++;
}

<*
    @ensure self.count >= 0, self.count <= SIZE
*>
fn usz? RingBuffer.write(&self, char[] data) @dynamic {
    if (self.is_full()) return stream::FULL?;

    usz actualLen = math::min(data.len, (usz)SIZE - self.count);
    self.buffer[self.head:actualLen] = data[:actualLen];

    @inc_modulo(self.head, actualLen);
    self.count += actualLen;

    return actualLen;
}

<*
    @ensure self.count >= 0, self.count <= SIZE
*>
fn char? RingBuffer.get(&self) @dynamic {
    if (self.is_empty()) return stream::EMPTY?;

    self.count--;
    @inc_modulo(self.tail);

    return self.buffer[self.tail];
}

<*
    @ensure self.count >= 0, self.count <= SIZE
*>
fn char[]? RingBuffer.read(&self, usz len) @dynamic {
    if (self.is_empty()) return stream::EMPTY?;

    usz actualLen = math::min(len, self.count);
    self.count -= actualLen;
    @inc_modulo(self.tail, actualLen);

    return self.buffer[self.tail:actualLen];
}

fn char? RingBuffer.peek(&self) {
    if (self.is_empty()) return stream::EMPTY?;
    return self.buffer[self.tail];
}

fn bool RingBuffer.is_empty(&self) {
    return self.count == 0;
}

fn bool RingBuffer.is_full(&self) {
    return self.count == SIZE;
}

fn usz RingBuffer.available(&self) @dynamic {
    return (usz)SIZE - self.count;
}

fn usz RingBuffer.flush(&self) @dynamic {
    self.tail = self.head;

    usz dataLen = self.count;
    self.count = 0;

    return dataLen;
}
