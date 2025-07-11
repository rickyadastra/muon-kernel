#include "file.h"
#include "efi/efi.h"
#include "efi/file_protocol.h"
#include <exception/file_exception.h>
#include <lepton/exception/exception.h>
#include "memory_manager.h"
#include "utils/utils.h"
#include <boson/wchar.h>
#include <lepton/exception/null_exception.h>
#include <lepton.h>

INHERITCLASS(File, _FILE_METHODS, MEMORYCONSUMER_METHODS)

void File_from(File *self, EfiFileProtocol *proto) {
    if (proto == null) {
        THROW_EXCEPTION(NullException, "EfiFileProtocol is null")
        return;
    }

    self->fileProtocol = proto;
}

File File_open(File *self, File *dest, const WChar16 *filename, UInt64 modes) {
    EfiStatus s;
    
    EfiFileProtocol* proto;
    s = self->fileProtocol->Open(self->fileProtocol, &proto, (WChar16*)filename, modes, 0);
    if (EFI_ERROR(s)) {
        THROW_EXCEPTION(FileException, "Cannot open file")
        return (File){};
    }

    IFile.from(dest, proto);
    IFile.set_memory_manager(dest, self->memoryManager);
    return *dest;
}

void alloc_file_info(File* self) {
    EfiStatus s = self->fileProtocol->GetInfo(self->fileProtocol, &(EfiGUID)EFI_FILE_INFO_GUID, &self->_infoSize, null);
    if (s == EFIERR(EFI_BUFFER_TOO_SMALL)) {
        IMemoryManager.alloc(self->memoryManager, self->_infoSize, (UPtr*)&self->_fileInfo);
    } else {
        EFI_THROW(s, FileException, "Unknown error while allocating file info buffer");
    }

    s = self->fileProtocol->GetInfo(self->fileProtocol, &(EfiGUID)EFI_FILE_INFO_GUID, &self->_infoSize, self->_fileInfo);
    EFI_THROW(s, FileException, "Cannot read file info")
}

Size File_get_size(File *self) {
    if (self->_fileInfo == null) alloc_file_info(self);

    return self->_fileInfo->FileSize;
}

UPtr File_read(File *self) {
    if (self->_fileInfo == null) alloc_file_info(self);

    BigSize fileSize = IFile.get_size(self);
    IMemoryManager.alloc(self->memoryManager, fileSize, &self->_fileBuffer);
    
    EfiStatus s = self->fileProtocol->Read(self->fileProtocol, &fileSize, (void*)self->_fileBuffer);
    EFI_THROW(s, FileException, "Cannot read file content", (UPtr)null)

    return self->_fileBuffer;
}

PACKAGECLASS(File, MemoryConsumer, _FILE_METHODS, MEMORYCONSUMER_METHODS)
