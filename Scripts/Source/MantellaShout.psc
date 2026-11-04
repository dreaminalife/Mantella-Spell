Scriptname MantellaShout Hidden
{Shout: anyone near the player can answer them or join in. Switched on and off from the Conversation Wheel, set up on the Shout Mode page.
MantellaConversation keeps the state and sends who is nearby. See docs/conversation_wheel.md in the Mantella repository}

float Function METER_UNITS() global ; Game units in a meter
    return 71.0210
EndFunction

; The nearest people within hearing distance who are free to talk and not in the conversation, at most Most People Listed, nearest first.
; Followers are included. With Must Be in Sight, either the player sees them or they see the player
Actor[] Function FindNearby(MantellaRepository repository, MantellaConversation conversation) global
    Actor player = Game.GetPlayer()
    int maxCount = repository.shoutMaxListed
    if maxCount < 1
        maxCount = 1
    elseIf maxCount > 30
        maxCount = 30
    endIf
    Actor[] found = new Actor[30]
    float[] distances = new float[30]
    int count = 0
    ; ScanCellNPCs' own keyword filter misses keywords that come from the race, like ActorTypeNPC, so it is checked here
    Keyword actorTypeNPC = Keyword.GetKeyword("ActorTypeNPC")
    Actor[] scanned = MiscUtil.ScanCellNPCs(player, repository.shoutHearingDistance * METER_UNITS())
    int i = 0
    while i < scanned.Length
        Actor npc = scanned[i]
        if npc.HasKeyword(actorTypeNPC) && CanJoin(npc, repository, conversation)
            count = MantellaWheel.InsertByDistance(found, distances, count, maxCount, npc, player.GetDistance(npc))
        endIf
        i += 1
    endWhile
    Actor[] result = PapyrusUtil.ActorArray(count)
    i = 0
    while i < count
        result[i] = found[i]
        i += 1
    endWhile
    return result
EndFunction

; Free to talk, not in the conversation, within hearing distance and, with Must Be in Sight, in sight
bool Function CanJoin(Actor npc, MantellaRepository repository, MantellaConversation conversation) global
    if !MantellaActorChecks.IsAvailableNpc(npc) || conversation.Participants.HasForm(npc)
        return false
    endIf
    Actor player = Game.GetPlayer()
    if player.GetDistance(npc) > repository.shoutHearingDistance * METER_UNITS()
        return false
    endIf
    return !repository.shoutRequireLineOfSight || npc.HasLOS(player) || player.HasLOS(npc)
EndFunction

; Just saying something: with no conversation running, the player says something to whoever is around. It starts a conversation with only
; the player, already shouting. MantellaSoftware's Game Master lets someone nearby answer and join, or nobody does and it ends.
; Started from the Conversation Wheel (Say) or the talk hotkey. Typed text is asked for first, so cancelling the text box starts nothing
Function SayToRoom(MantellaRepository repository, MantellaConversation conversation) global
    if conversation.IsRunning()
        return
    endIf
    if FindNearby(repository, conversation).Length == 0
        Debug.Notification("Nobody is around to hear you")
        return
    endIf
    string line = ""
    if !repository.microphoneEnabled
        UIExtensions.InitMenu("UITextEntryMenu")
        UIExtensions.OpenMenu("UITextEntryMenu")
        line = UIExtensions.GetMenuResultString("UITextEntryMenu")
        if line == ""
            return
        endIf
        if conversation.IsRunning()
            return ; Something else started a conversation while the text box was open
        endIf
    endIf
    Actor[] actors = new Actor[1]
    actors[0] = Game.GetPlayer()
    conversation.Start()
    conversation.SetRoomStart(line)
    conversation.StartConversation(actors)
EndFunction
