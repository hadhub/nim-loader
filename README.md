<p align="center">
Simple nim loader, made for CTF & labs
<br>
<strong>Disclamer : Use it at your own risk. I'm not responsible for your actions</strong>
</p>

## Install lib :
- ``nimble install winim RC4``

## Compile :
- ``nim c -d:mingw --passL:-Wl,--dynamicbase --opt:size -o:cool_name.exe dropper.nim``

To generate a Nim executable with a relocation section you need to pass a few additional flags to the linker. (from OffensiveNim repo)

- ``nim c --passL:-Wl,--dynamicbase dropper.nim``




### To do:
- [x] Load shellcode from http listener
- [x] Load encrypt and decrypt shellcode before injecting it into memory
- [ ] Patch ETW
- [ ] Unhooking DLL
- [ ] Hell's Gate
### One day :
- [ ] syscalls
- [ ] Add LLVM

## Ressources 
- https://github.com/OHermesJunior/nimRC4
- https://github.com/byt3bl33d3r/OffensiveNim
- https://github.com/Alh4zr3d/ProcessInjectionPOCs

