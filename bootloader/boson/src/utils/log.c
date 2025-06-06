#include <utils/log.h>
#include <string.h>
#include <wchar.h>
#include <null.h>

WChar16 buffer[256];
EfiSimpleTextOutputProtocol* efiOut;
EfiSimpleTextInputProtocol* efiIn;
EfiRuntimeServices* runtimeServices;
EfiBootServices* bootServices;

EfiInputKey efi_pause() {
    EfiInputKey key;
    while (efiIn->ReadKeyStroke(efiIn, &key) == EFI_NOT_READY) {}
    return key;
}

EfiStatus efi_log_full(WChar16* msg, Bool showTimestamp) {
    EfiStatus status;
    
    if (showTimestamp) {
        EfiTime time; 
        EfiStatus timeStatus = runtimeServices->GetTime(&time, null);
        if (EFI_ERROR(timeStatus)) return timeStatus;

        format_datetime(time, buffer, 64);

        status = efiOut->OutputString(efiOut, buffer);
        if (EFI_ERROR(status)) return status;
    }

    status = efiOut->OutputString(efiOut, msg);
    if (EFI_ERROR(status)) return status;
    status = efiOut->OutputString(efiOut, L"\r\n");
    return status;
}


EfiStatus efi_announce(WChar16* msg) {
    return efi_log_full(msg, false);
}

EfiStatus efi_log(WChar16* msg) {
    return efi_log_full(msg, true);
}

EfiStatus efi_logf(const char* s, ...) {
    if (!s) return 0;

    VAList args;
    VASTART(args, s);
    WChar16 tbuf[128];
    vstrf(s, tbuf, args);

    return efi_log_full(tbuf, true);
}
