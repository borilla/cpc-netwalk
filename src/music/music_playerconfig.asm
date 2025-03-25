; Configuration that can be used by the Arkos Tracker 3 players.

; It indicates what parts of code are useful to the song/sound effects, to save both memory and CPU.
; The players may or may not take advantage of these flags, it is up to them.

; You can either:
; - Ignore this file. The player will use its default build (no optimizations).
; - Include this to the source that also includes the player (BEFORE the player is included) (recommended solution).
; - Include or copy/paste this at the beginning of the player code (not recommended, the player should not be modified).

; This file was generated for a specific song. Do NOT use it for any other.
; Do NOT try to modify these flags, this can lead to a crash!

; If you use one player but several songs, don't worry, these declarations will stack up.
; Just make sure to include them, in any order, BEFORE the player.

    PLY_CFG_ConfigurationIsPresent = 1
    PLY_CFG_UseInstrumentLoopTo = 1
    PLY_CFG_UseEffects = 1
    PLY_CFG_NoSoftNoHard = 1
    PLY_CFG_SoftOnly = 1
    PLY_CFG_SoftOnly_Noise = 1
    PLY_CFG_SoftOnly_ForcedSoftwarePeriod = 1
    PLY_CFG_UseEffect_SetVolume = 1
    PLY_CFG_UseEffect_VolumeOut = 1
    PLY_CFG_UseEffect_ArpeggioTable = 1
    PLY_CFG_UseEffect_PitchTable = 1
    PLY_CFG_UseEffect_Reset = 1
