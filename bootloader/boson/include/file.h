#pragma once

#include "efi/file_protocol.h"
#include "int.h"
#include "lepton/core/class.h"
#include "memory_consumer.h"
#include <lepton/core.h>

#define _FILE_METHODS(T, S, M) \
    METHOD(T, S, M, void, from, EfiFileProtocol* proto) \
    METHOD(T, S, M, File, open, File* dest, const WChar16* filename, UInt64 modes) \
    METHOD(T, S, M, Size, get_size) \
    METHOD(T, S, M, UPtr, read)
    
#define FILE_METHODS(T, S, M) \
    MEMORYCONSUMER_METHODS(T, S, M) \
    _FILE_METHODS(T, S, M)

CLASSDEF(File, MemoryConsumer, FILE_METHODS)
    EfiFileProtocol* fileProtocol;
    BigSize _infoSize;
    EfiFileInfo* _fileInfo;
    UPtr _fileBuffer;
ENDCLASSDEF(File)
