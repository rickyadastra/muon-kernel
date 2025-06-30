#include "efi/efi.h"
#include <exception/console_exception.h>
#include "int.h"
#include <console.h>
#include <wchar.h>
#include <efi/time.h>
#include <lepton/core.h>
#include <null.h>
#include <vargs.h>
#include <utils/string.h>
#include <utils/utils.h>

WChar16 wbuffer[256];

INHERITCLASS(Console, _CONSOLE_METHODS, OBJECT_METHODS)

void Console_set_efi_table(Console *self, EfiSystemTable *efiTable) {
    self->runtimeServices = efiTable->RuntimeServices;
    self->efiOut = efiTable->ConOut;
    self->efiIn = efiTable->ConIn;
}

void Console_set_mode_and_clear(Console* self, UInt64 mode) {
    EfiStatus s;
    s = self->efiOut->SetMode(self->efiOut, mode);
    
    if (EFI_ERROR(s)) {
        s = self->efiOut->SetMode(self->efiOut, 0);
        EFI_THROW(s, ConsoleException, "Cannot set default output mode")
    }

    s = self->efiOut->ClearScreen(self->efiOut);
    s = self->efiIn->Reset(self->efiIn, false);
}

void Console_output(Console *self, WChar16 *msg, unsigned char showTimestamp) {
    EfiStatus status;
    
    if (showTimestamp) {
        EfiTime time; 
        EfiStatus timeStatus = self->runtimeServices->GetTime(&time, null);
        EFI_THROW(timeStatus, ConsoleException, "Cannot get timestamp")

        format_datetime(time, wbuffer, 64);

        status = self->efiOut->OutputString(self->efiOut, wbuffer);
        EFI_THROW(status, ConsoleException, "Cannot output string")
    }

    status = self->efiOut->OutputString(self->efiOut, msg);
    EFI_THROW(status, ConsoleException, "Cannot output string")
    status = self->efiOut->OutputString(self->efiOut, L"\r\n");
    EFI_THROW(status, ConsoleException, "Cannot output string")
}

void Console_announce(Console *self, WChar16 *msg) {
    Console_output(self, msg, false);
}

void Console_log(Console *self, WChar16 *msg) {
    Console_output(self, msg, true);
}

void Console_logf(Console *self, const char *msg, ...) {
    if (!msg) return;

    VAList args;
    VASTART(args, msg);
    WChar16 tbuf[128];
    vstrf(msg, tbuf, args);

    Console_output(self, tbuf, true);
}

void Console_pause(Console *self) {
    EfiInputKey key;
    while (self->efiIn->ReadKeyStroke(self->efiIn, &key) == EFI_NOT_READY) {}
    return;
}

PACKAGECLASS(Console, Object, _CONSOLE_METHODS, OBJECT_METHODS)
