Scriptname MantellaActorChecks Hidden
{Checks on NPCs shared by NPC Initiative, NPC Events and the Conversation Wheel}

; Alive, awake, not hostile, not busy in a scene and free to talk
bool Function IsAvailableNpc(Actor npc) global
    return UnavailableReason(npc) == ""
EndFunction

; Why the NPC can't talk right now, or "" if they are free to. The same checks as IsAvailableNpc, stopping at the first that fails
string Function UnavailableReason(Actor npc) global
    Actor player = Game.GetPlayer()
    if !npc
        return "gone"
    elseIf npc == player
        return "is the player"
    elseIf npc.IsDisabled()
        return "disabled"
    elseIf npc.IsDead()
        return "dead"
    elseIf npc.IsUnconscious()
        return "unconscious"
    elseIf npc.IsBleedingOut()
        return "bleeding out"
    elseIf npc.IsHostileToActor(player)
        return "hostile to the player"
    elseIf npc.IsInCombat()
        return "in combat"
    endIf
    ; In a scene, e.g. a bard performing a song: their Mantella lines wait behind the scene's, so the conversation stalls
    if npc.GetCurrentScene()
        return "in a scene"
    elseIf npc.GetSleepState() == 3 ; 3 is asleep
        return "asleep"
    elseIf npc.IsInDialogueWithPlayer()
        return "in game dialogue with the player"
    endIf
    return ""
EndFunction

; Following the player right now: a vanilla-style follower who is not told to wait, or one recruited with Mantella's follow action.
; Waiting, dismissed and potential followers are not active followers
bool Function IsActiveFollower(Actor npc, MantellaRepository repository) global
    if npc.IsPlayerTeammate() && npc.GetActorValue("WaitingForPlayer") == 0
        return true
    endIf
    return npc.GetFactionRank(repository.giafac_Following) >= 1 ; Mantella's follow action sets rank 1, ending it sets -2
EndFunction
