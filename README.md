<p align="center">
Simple nim loader, made for CTF & labs
<strong>Disclamer : Use it at your own risk. I'm not responsible for your actions</strong>
</p>

## Install lib :
- ``nimble install winim``

## Compile :
- ``nim c -d:mingw -o:cool_name.exe main.nim``

### To do:
- [x] Load shellcode from http listener
- [ ] Load encrypt and decrypt shellcode before injecting it into memory
- [ ] Patch ETW
- [ ] Unhooking DLL
- [ ] Hell's Gate
### One day :
- [ ] Test direct syscalls (modifié)
- [ ] Ajout surcouche LLVM
