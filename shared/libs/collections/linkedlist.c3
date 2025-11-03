module std::collections;

faultdef OUT_OF_BOUNDS;

module std::collections::linkedlist{Type};

const IS_EQUATABLE = Type.is_eq;

import mem::allocator;
import std::collections::iterator;

struct Node {
    Node* prev;
    Node* next;
    Type data;
}

struct LinkedList {
    Allocator allocator;
    usz size;
    Node* _head;
    Node* _tail;
}

struct LinkedListMutableIterator (MutableIterator{Type}) @local {
    Allocator allocator;
    LinkedList* list;
    Node* _cur;
    Node* _next;
}

<*
    @param[&in] alloc
*>
fn LinkedList init(Allocator alloc) {
    return {
        .size = 0,
        .allocator = alloc,
        ._head = null,
        ._tail = null,
    };
}

macro Node* LinkedList.alloc_node(&self) @private {
    return allocator::alloc(self.allocator, Node);
} 

macro void LinkedList.free_node(&self, Node* node) @private {
    allocator::free(self.allocator, (void*)node);
}

fn void LinkedList.add(&self, Type data) {
    Node* node = self.alloc_node();
    node.data = data;

    if (self.is_empty()) {  // set head and tail
        self._head = node;
        self._tail = node;
    } else {                // add to tail and update pointers
        node.prev = self._tail;
        self._tail.next = node;
        self._tail = node;
    }

    self.size++;
}

fn void? LinkedList.insert_at(&self, usz index, Type data) {
    if (index > self.size) return collections::OUT_OF_BOUNDS?;

    Node* cur = self._head;
    for (usz i=0; i < index; i++) cur = cur.next;

    Node* node = self.alloc_node();
    node.data = data;

    if (cur == null) { // end of list
        node.prev = self._tail;
        self._tail.next = node;

        self._tail = node;

    } else if (cur.prev == null) { // node is head of list
        node.next = cur;
        cur.prev = node;

        self._head = node;

    } else { // node in the middle
        node.prev = cur.prev;
        node.next = cur;

        cur.prev.next = node;
        cur.prev = node;
    }

    self.size++;
}

macro LinkedList.remove_node(&self, Node* cur) @local {
    if (cur.next == null) { // end of list
        if (cur.prev != null) {
            cur.prev.next = null;
        } else {
            self._head = null;
        }
        self._tail = cur.prev;

    } else if (cur.prev == null) { // node is head of list
        if (cur.next != null) {
            cur.next.prev = null;
        } else {
            self._tail = null;
        }
        self._head = cur.next;

    } else { // node in the middle
        cur.prev.next = cur.next;
        cur.next.prev = cur.prev;
    }
}

fn Type? LinkedList.remove_at(&self, usz index) {
    if (index >= self.size) return collections::OUT_OF_BOUNDS?;

    Node* cur = self._head;
    for (usz i=0; i < index; i++) cur = cur.next;

    self.remove_node(cur);

    Type data = cur.data;
    self.free_node(cur);
    self.size--;

    return data;
}

fn bool LinkedList.remove(&self, Type el) @if(IS_EQUATABLE) {
    MutableIterator{Type} it = self.mutable_iterator();
    defer it.destroy();

    while (it.has_next()) {
        Type e = it.next()!!;
        if (e == el) {
            it.remove();
            return true;
        } 
    }

    return false;
}

fn void LinkedList.remove_all(&self, Type el) @if(IS_EQUATABLE) {
    MutableIterator{Type} it = self.mutable_iterator();
    defer it.destroy();

    while (it.has_next()) {
        Type e = it.next()!!;
        if (e == el) it.remove();
    }
}

fn Type? LinkedList.get(&self, usz index) {
    if (index >= self.size) return collections::OUT_OF_BOUNDS?;

    Node* cur = self._head;
    for (usz i=0; i < index; i++) cur = cur.next;

    return cur.data;
}

fn bool LinkedList.is_empty(&self) => self._head == null;

fn Type? LinkedList.first(&self) {
    if (self.is_empty()) return collections::OUT_OF_BOUNDS?;
    return self._head.data;
}

fn Type? LinkedList.last(&self) {
    if (self.is_empty()) return collections::OUT_OF_BOUNDS?;
    return self._tail.data;
}

fn Iterator{Type} LinkedList.iterator(&self) {
    return (Iterator{Type})self.mutable_iterator();
}

fn MutableIterator{Type} LinkedList.mutable_iterator(&self) {
    LinkedListMutableIterator* it = allocator::alloc(self.allocator, LinkedListMutableIterator);
    it.list = self;
    it._cur = null;
    it._next = self._head;
    it.allocator = self.allocator;

    return it;
}

fn void LinkedListMutableIterator.destroy(&self) @dynamic {
    allocator::free(self.allocator, (void*)self);
}
 
fn bool LinkedListMutableIterator.has_next(&self) @dynamic {
    return self._next != null;
}

fn Type? LinkedListMutableIterator.next(&self) @dynamic {
    if (self._next == null) return collections::ITERATOR_ILLEGAL_STATE?;
    
    self._cur = self._next;
    self._next = self._next.next;

    return self._cur.data;
}

fn bool LinkedListMutableIterator.remove(&self) @dynamic {
    Node* cur = self._cur;
    if (cur == null) return false;

    self.list.remove_node(cur);
    self.list.free_node(cur);
    self.list.size--;
    return true;
}

fn void LinkedListMutableIterator.insert(&self, Type data) @dynamic {
    Node* node = self.list.alloc_node();
    node.data = data;
    node.next = self._next;

    if (self._cur == null) {
        if (self._next != null) { // cursor at the start, list at least one elem
            self._next.prev = node;
        } else { // cursor at the start, list empty
            self.list._tail = node;
        }

        self.list._head = node;

    } else {
        node.prev = self._cur;
        self._cur.next = node;

        if (self._next != null) { // cursor inside the list, not the end
            self._next.prev = node;
        } else { // cursor inside the list, end of the list
            self.list._tail = node;
        }
    }

    self._next = node;
    self.list.size++;
}

fn void? LinkedListMutableIterator.set(&self, Type newValue) @dynamic {
    if (self._cur == null) return collections::ITERATOR_ILLEGAL_STATE?;
    
    self._cur.data = newValue;
}

