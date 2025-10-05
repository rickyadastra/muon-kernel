module std::collections;

faultdef OUT_OF_BOUNDS;

module std::collections::linkedlist{Type};

import mem::allocator;

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

fn Type? LinkedList.remove_at(&self, usz index) {
    if (index >= self.size) return collections::OUT_OF_BOUNDS?;

    Node* cur = self._head;
    for (usz i=0; i < index; i++) cur = cur.next;

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

    Type data = cur.data;
    self.free_node(cur);
    self.size--;

    return data;
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
