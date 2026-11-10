Scriptname MantellaKillEvents Hidden
{Signs Mantella up for powerofthree's Papyrus Extender's 'any actor was killed' event.}

; powerofthree's Papyrus Extender is an OPTIONAL requirement. This script holds every mention of it, so no script that
; players always load refers to its types: a script that referred to a missing one could fail to load as a whole.
; Nothing here runs unless the extender is installed, so a game without it logs no errors and behaves as it did before.

; True when powerofthree's Papyrus Extender (po3_PapyrusExtender.dll) is loaded.
; 'po3_PapyrusExtender' is the name in the DLL's SKSE version data; the display name is checked too in case SKSE answers to that one
bool Function IsInstalled() global
    return SKSE.GetPluginVersion("po3_PapyrusExtender") >= 0 || SKSE.GetPluginVersion("powerofthree's Papyrus Extender") >= 0
EndFunction

; Asks the extender to send OnActorKilled to this alias for every actor that dies in the game.
; Registering again is safe: the extender keeps the registrations in a set, so a repeat is not a second event
Function Register(ReferenceAlias akAlias) global
    If (akAlias && IsInstalled())
        PO3_Events_Alias.RegisterForActorKilled(akAlias)
    EndIf
EndFunction
