#pragma once

#include "efi/file_protocol.h"
#include "lepton/core/class.h"
#include <lepton/core.h>

#define _FILE_METHODS(T, S, M) \
    METHOD(T, S, M, void, from, EfiFileProtocol* proto) \
    METHOD(T, S, M, File, open, File* dest, const WChar16* filename, UInt64 modes) \
    METHOD(T, S, M, Size, get_size)
    
#define FILE_METHODS(T, S, M) \
    OBJECT_METHODS(T, S, M) \
    _FILE_METHODS(T, S, M)

CLASSDEF(File, Object, FILE_METHODS)
    
    EfiFileProtocol* fileProtocol;
    BigSize _infoSize;
    EfiFileInfo* _fileInfo;
ENDCLASSDEF(File)
