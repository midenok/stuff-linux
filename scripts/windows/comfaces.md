# Description

comfaces.pl script helps to import COM interfaces from Microsoft SDK header files to IDA PRO. Script was tested DirectX 7.0 SDK. There is no guarantee that it will work with another SDK header files.

Script takes .h headers from SDK as input and produces .h header for IDA PRO. It can create enums or structs depending on what is more convenient to use in IDA PRO.

# Usage

`comfaces.pl [COMMAND] [OPTION]... DIR|FILE...`
  - `DIR` directory containing SDK header files
  - `FILE` SDK header file

For `COMMAND` and `OPTION` descriptions see below `comfaces.pl --help`

# Source

https://github.com/midenok/linux/blob/master/scripts/windows/comfaces.pl

# Usage examples

##### comfaces.pl --ls IDirectPlay*
```
IDirectPlay (25)  [dplay.h]
IDirectPlay2 (32)  [dplay.h]
IDirectPlay3 (47)  [dplay.h]
IDirectPlay4 (53)  [dplay.h]
IDirectPlayLobby (14)  [dplobby.h]
IDirectPlayLobby2 (15)  [dplobby.h]
IDirectPlayLobby3 (19)  [dplobby.h]
```

##### comfaces.pl --match IDirectInput2?
```
struct IDirectInput2A_
{
  /*** IUnknown methods ***/
  DWORD QueryInterface; // (THIS_ REFIID riid, LPVOID * ppvObj)
  DWORD AddRef; // (ULONG)(THIS)
  DWORD Release; // (ULONG)(THIS)
  /*** IDirectInputA methods ***/
  DWORD CreateDevice; // (THIS_ REFGUID,LPDIRECTINPUTDEVICEA *,LPUNKNOWN)
  DWORD EnumDevices; // (THIS_ DWORD,LPDIENUMDEVICESCALLBACKA,LPVOID,DWORD)
  DWORD GetDeviceStatus; // (THIS_ REFGUID)
  DWORD RunControlPanel; // (THIS_ HWND,DWORD)
  DWORD Initialize; // (THIS_ HINSTANCE,DWORD)
  /*** IDirectInput2A methods ***/
  DWORD FindDevice; // (THIS_ REFGUID,LPCSTR,LPGUID)
};

struct IDirectInput2W_
{
  /*** IUnknown methods ***/
  DWORD QueryInterface; // (THIS_ REFIID riid, LPVOID * ppvObj)
  DWORD AddRef; // (ULONG)(THIS)
  DWORD Release; // (ULONG)(THIS)
  /*** IDirectInputW methods ***/
  DWORD CreateDevice; // (THIS_ REFGUID,LPDIRECTINPUTDEVICEW *,LPUNKNOWN)
  DWORD EnumDevices; // (THIS_ DWORD,LPDIENUMDEVICESCALLBACKW,LPVOID,DWORD)
  DWORD GetDeviceStatus; // (THIS_ REFGUID)
  DWORD RunControlPanel; // (THIS_ HWND,DWORD)
  DWORD Initialize; // (THIS_ HINSTANCE,DWORD)
  /*** IDirectInput2W methods ***/
  DWORD FindDevice; // (THIS_ REFGUID,LPCWSTR,LPGUID)
};
```

##### comfaces.pl --match IDirectInput2W -s
```
DECLARE_INTERFACE_(IDirectInput2W, IDirectInputW) {
    /*** IUnknown methods ***/
    STDMETHOD(QueryInterface)(THIS_ REFIID riid, LPVOID * ppvObj) PURE;
    STDMETHOD_(ULONG,AddRef)(THIS) PURE;
    STDMETHOD_(ULONG,Release)(THIS) PURE;
    /*** IDirectInputW methods ***/
    STDMETHOD(CreateDevice)(THIS_ REFGUID,LPDIRECTINPUTDEVICEW *,LPUNKNOWN) PURE;
    STDMETHOD(EnumDevices)(THIS_ DWORD,LPDIENUMDEVICESCALLBACKW,LPVOID,DWORD) PURE;
    STDMETHOD(GetDeviceStatus)(THIS_ REFGUID) PURE;
    STDMETHOD(RunControlPanel)(THIS_ HWND,DWORD) PURE;
    STDMETHOD(Initialize)(THIS_ HINSTANCE,DWORD) PURE;
    /*** IDirectInput2W methods ***/
    STDMETHOD(FindDevice)(THIS_ REFGUID,LPCWSTR,LPGUID) PURE;
};
```

##### comfaces.pl --match IDirectInput2W --produce=enum
```
enum IDirectInput2W_
{
  /*** IUnknown methods ***/
  IDirectInput2W__QueryInterface = 0x0, // (THIS_ REFIID riid, LPVOID * ppvObj)
  IDirectInput2W__AddRef = 0x4, // (ULONG)(THIS)
  IDirectInput2W__Release = 0x8, // (ULONG)(THIS)
  /*** IDirectInputW methods ***/
  IDirectInput2W__CreateDevice = 0xC, // (THIS_ REFGUID,LPDIRECTINPUTDEVICEW *,LPUNKNOWN)
  IDirectInput2W__EnumDevices = 0x10, // (THIS_ DWORD,LPDIENUMDEVICESCALLBACKW,LPVOID,DWORD)
  IDirectInput2W__GetDeviceStatus = 0x14, // (THIS_ REFGUID)
  IDirectInput2W__RunControlPanel = 0x18, // (THIS_ HWND,DWORD)
  IDirectInput2W__Initialize = 0x1C, // (THIS_ HINSTANCE,DWORD)
  /*** IDirectInput2W methods ***/
  IDirectInput2W__FindDevice = 0x20, // (THIS_ REFGUID,LPCWSTR,LPGUID)
};
```

##### comfaces.pl --help
```
Usage:
    comfaces.pl [COMMAND] [OPTION]... DIR|FILE...

Commands:
    (default command)
        Produce IDA-compatible structures from DECLARE_INTERFACE_
        directives.

    --check
        Apply --parse-errors=show and do not show anything except errors.

    --list-class, --lsc NAME
        Show methods by class name.

    --list-classes, --ls [MASK]
        Show all classes along with method counts and file origins.

    --source, -s
        Dump sources of parsed classes.

Options:
    --context[-lines], -C NUM
        Show NUM count of lines before the line that caused any error,
        including that line. 0 turns off context printing. Default: 3

    --duplicates, --dups fail | force | skip | overwrite
        Duplicates are classes with same name.

         'fail' will fail on any duplicate class;
         'force' will handle duplicates like normal classes;
         'skip' will skip any duplicates except the first;
         'overwrite' will skip duplicates except the last.
        Default: fail

    --filemask MASKLIST
        MASKLIST is comma-separated list of file masks. When opening DIR use
        these masks to find files. Default: *.h,*.hpp

    --ignore-case, -i
        Ignore case in MASK or REGEX.

    --match-classes, --match, -m MASK
        Skip classes that do not match filemask MASK.

    --match-regex, --regex REGEX
        Skip classes that do not match regular expression REGEX.

    --parse-errors, -e fail | show | skip
         'fail' will show parsing error and will stop processing;
         'show' will show parsing error and will continue processing;
         'skip' will ignore any parsing errors.
        Default: fail

    --postfix, -o STR
        Add STR at the end of structure names in generated output.
        Default: _

    --prefix, -r STR
        Add STR at the beginning of structure names in generated output.
        Default: (none)

    --infix, -x STR
        Add STR between structure name and enum member name (used only with
        --produce=enum). Default: __

    --produce-mode, -p struct | enum
        Produce structures or enums. Default: struct

    --nosort
        Don't sort structures alphabetically.
```
