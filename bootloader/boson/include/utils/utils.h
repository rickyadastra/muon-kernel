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
EfiStatus efi_alloc_pages(Size size, UPtr* addr);
void efi_mem_copy(const char* from, char* to, Size size);
void efi_mem_set(char* to, Size size, char value);

extern EfiSimpleTextOutputProtocol* efiOut;
extern EfiSimpleTextInputProtocol* efiIn;
extern EfiRuntimeServices* runtimeServices;
extern EfiBootServices* bootServices;
