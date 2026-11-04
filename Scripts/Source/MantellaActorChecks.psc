Scriptname MantellaActorChecks Hidden
{Checks on NPCs shared by NPC Initiative, NPC Events and the Conversation Wheel}

; Alive, awake, not hostile, not busy in a scene and free to talk
bool Function IsAvailableNpc(Actor npc) global
    Actor player = Game.GetPlayer()
    if !npc || npc == player || npc.IsDisabled() || npc.IsDead() || npc.IsUnconscious() || npc.IsBleedingOut()
        return false
    endIf
    if npc.IsHostileToActor(player) || npc.IsInCombat()
        return false
    endIf
    ; In a scene, e.g. a bard performing a song: their Mantella lines wait behind the scene's, so the conversation stalls
    if npc.GetCurrentScene()
        return false
    endIf
    return npc.GetSleepState() != 3 && !npc.IsInDialogueWithPlayer() ; 3 is asleep
EndFunction

; Following the player right now: a vanilla-style follower who is not told to wait, or one recruited with Mantella's follow action.
; Waiting, dismissed and potential followers are not active followers
bool Function IsActiveFollower(Actor npc, MantellaRepository repository) global
    if npc.IsPlayerTeammate() && npc.GetActorValue("WaitingForPlayer") == 0
        return true
    endIf
    return npc.GetFactionRank(repository.giafac_Following) >= 1 ; Mantella's follow action sets rank 1, ending it sets -2
EndFunction
