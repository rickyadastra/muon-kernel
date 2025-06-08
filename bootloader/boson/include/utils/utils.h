#pragma once

#include <size.h>
#include <efi/efi.h>
#include <efi/runtime_services.h>
#include <efi/boot_services.h>

EfiStatus efi_log_full(WChar16* msg, Bool showTimestamp);
EfiStatus efi_announce(WChar16* msg);
EfiStatus efi_log(WChar16* msg);
EfiStatus efi_logf(const char* s, ...);
EfiInputKey efi_pause();
EfiStatus efi_alloc(Size size, void** buffer);
EfiStatus efi_free(void* buffer);

extern EfiSimpleTextOutputProtocol* efiOut;
extern EfiSimpleTextInputProtocol* efiIn;
extern EfiRuntimeServices* runtimeServices;
extern EfiBootServices* bootServices;
