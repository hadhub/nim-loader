# ============================================
# config.nims - 4 Modes de compilation
# Nécessite nim.cfg pour définir l'OS cible
# ============================================

# --- MODE 1: DEBUG (par défaut) ---
# Développement normal avec toutes les infos

when not defined(st1) and not defined(st2) and not defined(st3):
  switch("opt", "speed")
  
  # Infos de debug complètes
  switch("debugger", "native")
  switch("stackTrace", "on")
  switch("lineTrace", "on")
  switch("boundChecks", "on")
  switch("overflowChecks", "on")
  
  # Warnings/hints
  switch("warnings", "on")
  switch("hints", "on")
  warning("UnusedImport", false)
  hint("Processing", false)
  hint("CC", false)
  
  switch("out", "build/payload_debug.exe")
  echo "🐛 Mode: DEBUG (développement normal)"


# --- MODE 2: st1 (Léger) ---
# Optimisations de base, garde les checks de sécurité

when defined(st1):
  # Optimisation taille
  switch("opt", "size")
  switch("define", "release")
  
  # Garde les checks importants
  switch("boundChecks", "on")
  switch("overflowChecks", "on")
  
  # Retire les infos de debug
  switch("stackTrace", "off")
  switch("lineTrace", "off")
  
  # Réduction basique
  switch("passL", "-s")  # Strip symbols
  
  # Hints/warnings minimaux
  switch("warnings", "on")
  warning("UnusedImport", false)
  switch("hints", "off")
  
  switch("out", "build/payload_st1.exe")
  echo "🟡 Mode: st1 (léger - optimisé avec checks)"


# --- MODE 3: st2 (Moyen) ---
# Retire les checks, réduit la signature, taille minimale

when defined(st2):
  # Optimisation taille + danger
  switch("opt", "size")
  switch("define", "danger")   # Retire TOUS les checks
  switch("define", "release")
  
  # Garde assert pour compatibilité winim
  switch("assertions", "on")
  
  # Retire les métadonnées
  switch("define", "nimTypeNames:off")
  
  # Options C pour réduire la taille
  switch("passC", "-fno-asynchronous-unwind-tables")
  switch("passC", "-fno-ident")
  switch("passC", "-ffunction-sections")
  switch("passC", "-fdata-sections")
  switch("passC", "-fno-stack-protector")
  switch("passC", "-fomit-frame-pointer")
  
  # Linkage optimisé
  switch("passL", "-s")
  switch("passL", "-Wl,--gc-sections")
  switch("passL", "-Wl,--strip-all")
  switch("passL", "-static-libgcc")
  
  # Silence
  switch("warnings", "off")
  switch("hints", "off")
  switch("verbosity", "0")
  
  switch("out", "build/payload_st2.exe")
  echo "🟠 Mode: st2 (moyen - sans checks, taille réduite)"


# --- MODE 4: st3 (Maximal) ---
# Anti-détection maximale, signature minimale, obfuscation

when defined(st3):
  # Optimisation taille maximale
  switch("opt", "size")
  switch("define", "release")
  
  # IMPORTANT: Ne pas utiliser -d:danger car incompatible avec winim
  # À la place, désactiver les checks individuellement
  switch("boundChecks", "off")
  switch("overflowChecks", "off")
  switch("nilChecks", "off")
  switch("rangeChecks", "off")
  switch("floatChecks", "off")
  switch("nanChecks", "off")
  switch("infChecks", "off")
  
  # Garde assert pour winim mais le rend no-op
  switch("assertions", "off")
  switch("define", "nimAssertOff")
  
  # Retire les métadonnées
  switch("define", "nimTypeNames:off")
  
  # Options C agressives pour réduire signature
  switch("passC", "-fno-asynchronous-unwind-tables")
  switch("passC", "-fno-ident")              # Pas d'info compilateur
  switch("passC", "-ffunction-sections")
  switch("passC", "-fdata-sections")
  switch("passC", "-fno-stack-protector")
  switch("passC", "-fomit-frame-pointer")
  switch("passC", "-fmerge-all-constants")   # Merge constantes
  switch("passC", "-fvisibility=hidden")     # Cache symboles
  switch("passC", "-fno-exceptions")
  switch("passC", "-fno-rtti")               # Pas de RTTI
  switch("passC", "-fno-threadsafe-statics")
  switch("passC", "-Os")                     # Optimisation taille supplémentaire
  
  # Linkage agressif
  switch("passL", "-s")
  switch("passL", "-Wl,--gc-sections")
  switch("passL", "-Wl,--strip-all")
  switch("passL", "-Wl,--as-needed")
  switch("passL", "-Wl,--no-undefined")
  switch("passL", "-static-libgcc")
  switch("passL", "-static-libstdc++")
  
  # Suppression des sections inutiles
  switch("passL", "-Wl,--discard-all")
  switch("passL", "-Wl,--build-id=none")     # Pas de build ID
  
  # Options Nim avancées
  switch("define", "noSignalHandler")        # Pas de handler de signaux
  
  # Silence absolu
  switch("warnings", "off")
  switch("hints", "off")
  switch("verbosity", "0")
  
  switch("out", "build/payload_st3.exe")
  echo "🔴 Mode: st3 (maximal - anti-détection, signature minimale)"
