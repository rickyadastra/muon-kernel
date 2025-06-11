#include <int.h>
#include <wchar.h>
#include <bool.h>
#include <efi/status.h>

#pragma once

typedef void* EfiPVoid;
typedef void* EfiHandle;

#ifdef __i386__
#define MESSAGE L"i386\r\n"
typedef uint32_t UINTN;
#endif
#ifdef __amd64__
#define MESSAGE L"x86_64\r\n"
typedef UInt64 UINTN;
#endif

typedef UINTN EfiStatus;

#define EFIERR(a) (a | ~(((EfiStatus)-1) >> 1))
#define EFI_ERROR(a) (a & ~(((EfiStatus)-1) >> 1))

#define EFI_NOT_READY EFIERR(EFI_NOT_READY)

typedef struct {
	UInt64 Signature;
	UInt32 Revision;
	UInt32 HeaderSize;
	UInt32 CRC32;
	UInt32 Reserved;
} EfiTableHeader;

typedef struct {
	UInt32 MaxMode;
	UInt32 Mode;
	UInt32 Attribute;
	UInt32 CursorColumn;
	UInt32 CursorRow;
	UInt8  CursorVisible;
} SimpleTextOutputMode;

typedef EfiStatus (*EfiTextClearScreen)(void *This);
typedef EfiStatus (*EfiTextEnableCursor)(void *This, UInt8 Visible);
typedef EfiStatus (*EfiTextSetAttribute)(void *This, UINTN Attribute);
typedef EfiStatus (*EfiTextString)(void *This, const WChar16 *String);
typedef EfiStatus (*EfiTextSetMode) (void* This, UINTN ModeNumber);

typedef EfiStatus (*EfiTextQueryMode)(
	void  *This,
	UINTN ModeNumber,
	UINTN *Columns,
	UINTN *Rows);

typedef EfiStatus (*EfiTextSetCursorPosition)(
	void  *This,
	UINTN Column,
	UINTN Row);

typedef struct {
	EfiPVoid                    Reset;
	EfiTextString              OutputString;
	EfiPVoid                    TestString;
	EfiTextQueryMode          QueryMode;
	EfiTextSetMode                    SetMode;
	EfiTextSetAttribute       SetAttribute;
	EfiTextClearScreen        ClearScreen;
	EfiTextSetCursorPosition SetCursorPosition;
	EfiTextEnableCursor       EnableCursor;
	SimpleTextOutputMode      *Mode;
} EfiSimpleTextOutputProtocol;

typedef struct {
	WChar16 ScanCode;
	WChar16 UnicodeChar;
} EfiInputKey;

typedef EfiStatus (*EfiInputReset)(void *This, Bool ExtendedVerification);
typedef EfiStatus (*EfiInputReadKey)(void *This, EfiInputKey *Key);

typedef struct {
	EfiInputReset    Reset;
	EfiInputReadKey ReadKeyStroke;
	EfiPVoid          WaitForKey;
} EfiSimpleTextInputProtocol;

typedef struct {
	EfiTableHeader Hdr;
	EfiPVoid FirmwareVendor;
	UInt32 FirmwareRevision;
	EfiPVoid ConsoleInHandle;
	EfiSimpleTextInputProtocol  *ConIn;
	EfiPVoid ConsoleOutHandle;
	EfiSimpleTextOutputProtocol *ConOut;
	EfiPVoid StandardErrorHandle;
	EfiSimpleTextOutputProtocol *StdErr;
	void* RuntimeServices;
	void* BootServices;
	UINTN NumberOfTableEntries;
	void* ConfigurationTable;
} EfiSystemTable;

typedef struct {
	UInt32 TimeLow;
	UInt16 TimeMid;
	UInt16 TimeHighAndVersion;
	UInt8 Data[8];
} __attribute__((packed)) EfiGUID;
