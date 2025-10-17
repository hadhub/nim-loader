<p align="center">
Simple nim loader, made for CTF & labs
<br>
<strong>Disclaimer: For educational purposes only. I am not responsible for your actions</strong>
</p>

## Install lib :
- ``nimble install winim RC4``

## Compile :
# WARNING
- Ne pas delete nim.cfg


## Mode DEBUG (développement)
nim c main.nim

## Mode STEALTH1 (léger - garde les checks)
nim c -d:stealth1 main.nim

## Mode STEALTH2 (moyen - sans checks, taille réduite)
nim c -d:stealth2 main.nim

## Mode STEALTH3 (maximal - anti-détection)
nim c -d:stealth3 main.nim

## Après compilation STEALTH3, appliquer:

## 1. Strip agressif (si pas déjà fait)
x86_64-w64-mingw32-strip --strip-all --strip-debug build/payload_stealth3.exe

## 2. Compression UPX maximale
upx --best --ultra-brute build/payload_stealth3.exe

## 3. OU UPX avec LZMA (meilleure compression)
upx --best --lzma build/payload_stealth3.exe

## 4. Pour modifier la signature PE (optionnel, nécessite des outils supplémentaires)
## Vous pouvez utiliser des outils comme:
## - pe-bear pour analyser la structure PE
## - python pefile pour modifier les headers

[Link to Nim Compiler User Guide](https://nim-lang.org/docs/nimc.html)

## Ressources 
- https://github.com/khchen/winim
- https://github.com/OHermesJunior/nimRC4
- https://github.com/byt3bl33d3r/OffensiveNim
- https://github.com/Alh4zr3d/ProcessInjectionPOCs

