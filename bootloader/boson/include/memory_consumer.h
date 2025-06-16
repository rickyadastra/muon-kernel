#pragma once

#include "memory_manager.h"
#include <lepton/core.h>

#define _MEMORYCONSUMER_METHODS(T, S, M) \
    METHOD(T, S, M, void, set_memory_manager, MemoryManager* memoryManager)
    
#define MEMORYCONSUMER_METHODS(T, S, M) \
    OBJECT_METHODS(T, S, M) \
    _MEMORYCONSUMER_METHODS(T, S, M)

CLASSDEF(MemoryConsumer, Object, MEMORYCONSUMER_METHODS)
    MemoryManager* memoryManager;
ENDCLASSDEF(MemoryConsumer)
