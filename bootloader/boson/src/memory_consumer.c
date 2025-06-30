#include "memory_consumer.h"
#include "lepton/exception/null_exception.h"
#include "null.h"

INHERITCLASS(MemoryConsumer, _MEMORYCONSUMER_METHODS, OBJECT_METHODS)

void MemoryConsumer_set_memory_manager(MemoryConsumer *self, MemoryManager *memoryManager) {
    if (memoryManager == null) {
        THROW_EXCEPTION(NullException, "MemoryManager is null")
        return;
    }

    self->memoryManager = memoryManager;
}

PACKAGECLASS(MemoryConsumer, Object, _MEMORYCONSUMER_METHODS, OBJECT_METHODS)

