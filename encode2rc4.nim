import RC4
import os

echo "[*] Usage : program <key> <input_file> <output_file>"

var
    encode          : string
    key             : string = paramStr(1)
    data            : string = paramStr(2)
    outputfile      : string = paramStr(3)
    content         : string
    enc_shellcode   = newseq[byte]()

func toByteSeq*(str: string): seq[byte] {.inline.} =
    @(str.toOpenArrayByte(0, str.high))

proc encodeToRC4() : void =
        echo "[+] Reading input file"
        content = readFile(data)
        echo "[+] To RC4"
        echo "[*] Key : ", key
        echo "[*] Output file : ", outputfile
        encode  = toRC4(key,content)
        enc_shellcode = toByteSeq(encode)
        writeFile(outputfile, enc_shellcode)
        echo "[+] Shellcode size : ", enc_shellcode.len


when isMainModule:
    encodeToRC4()
