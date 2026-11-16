Scriptname MantellaShout Hidden
{Shout: anyone near the player can answer them or join in. Switched on and off from the Conversation Wheel, set up on the Shout Mode page.
MantellaConversation keeps the state and sends who is nearby. See docs/conversation_wheel.md in the Mantella repository}

float Function METER_UNITS() global ; Game units in a meter
    return 71.0210
EndFunction

; Who can join by shouting: the nearest people who are free to talk and not in the conversation, at most Most People Listed, nearest first.
; While the player watches an NPC Event (it runs in Shout from the start), the NPC Event's rules decide (FindNearbyForNpcEvent).
; Otherwise the Shout Mode page's: Hearing Distance, Include Followers and Must Be in Sight
Actor[] Function FindNearby(MantellaRepository repository, MantellaConversation conversation) global
    if IsWatchingNpcEvent(conversation)
        return FindNearbyForNpcEvent(repository, conversation)
    endIf
    return FindNearbyWith(repository, conversation, repository.shoutHearingDistance, !repository.shoutExcludeFollowers, repository.shoutRequireLineOfSight, repository.shoutMaxListed)
EndFunction

; Who an NPC Event can be about, and who can join it while the player watches: within the NPC Event's Hearing Distance, followers only with
; its Include Active Followers, at most the Shout Mode page's Most People Listed. Line of sight is not needed
Actor[] Function FindNearbyForNpcEvent(MantellaRepository repository, MantellaConversation conversation) global
    return FindNearbyWith(repository, conversation, repository.npcEventHearingDistance, repository.npcEventIncludeFollowers, false, repository.shoutMaxListed)
EndFunction

; The player is watching an NPC Event, not in it
bool Function IsWatchingNpcEvent(MantellaConversation conversation) global
    return conversation.IsRunning() && conversation.IsNpcEvent() && !conversation.IsPlayerInConversation()
EndFunction

; The nearest people within distanceMeters of the player who are free to talk and not in the conversation, at most maxCount (1 to 30), nearest first.
; With requireLineOfSight, either the player sees them or they see the player
Actor[] Function FindNearbyWith(MantellaRepository repository, MantellaConversation conversation, float distanceMeters, bool includeFollowers, bool requireLineOfSight, int maxCount) global
    Actor player = Game.GetPlayer()
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
    Actor[] scanned = MiscUtil.ScanCellNPCs(player, distanceMeters * METER_UNITS())
    int i = 0
    while i < scanned.Length
        Actor npc = scanned[i]
        if npc.HasKeyword(actorTypeNPC) && WhyCantJoinWith(npc, repository, conversation, distanceMeters, includeFollowers, requireLineOfSight) == ""
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

; Why the NPC can't join, or "" if they can, by the same rules as FindNearby. Sent to MantellaSoftware, which logs it, when the person
; the Game Master picked can't be added
string Function WhyCantJoin(Actor npc, MantellaRepository repository, MantellaConversation conversation) global
    if IsWatchingNpcEvent(conversation)
        return WhyCantJoinWith(npc, repository, conversation, repository.npcEventHearingDistance, repository.npcEventIncludeFollowers, false)
    endIf
    return WhyCantJoinWith(npc, repository, conversation, repository.shoutHearingDistance, !repository.shoutExcludeFollowers, repository.shoutRequireLineOfSight)
EndFunction

; Free to talk, not in the conversation, within distanceMeters, a follower only with includeFollowers and, with requireLineOfSight, in sight.
; Stops at the first check that fails
string Function WhyCantJoinWith(Actor npc, MantellaRepository repository, MantellaConversation conversation, float distanceMeters, bool includeFollowers, bool requireLineOfSight) global
    string reason = MantellaActorChecks.UnavailableReason(npc)
    if reason != ""
        return reason
    elseIf conversation.Participants.HasForm(npc)
        return "already in the conversation"
    elseIf !includeFollowers && MantellaActorChecks.IsActiveFollower(npc, repository)
        return "a follower (Include Followers is off)"
    endIf
    Actor player = Game.GetPlayer()
    float distance = player.GetDistance(npc)
    if distance > distanceMeters * METER_UNITS()
        return "too far away (" + ((distance / METER_UNITS()) as int) + " m)"
    elseIf requireLineOfSight && !npc.HasLOS(player) && !player.HasLOS(npc)
        return "out of sight"
    endIf
    return ""
EndFunction

; Just saying something: with no conversation running, the player says something to whoever is around. It starts a conversation with only
; the player, already shouting. MantellaSoftware's Game Master lets someone nearby answer and join, or nobody does and it ends.
; Started from the Conversation Wheel (Say) or the talk hotkey. Typed text is asked for first, so cancelling the text box starts nothing.
; Finding who is nearby, and building the details of the nearest, takes a few seconds in a crowded place. With the text box it runs
; on another thread while the player types (MantellaConversation.StartRoomScan), so the box opens right away and little is left after Enter.
; Cancelling the box throws the scan away. Pressing again while one is getting ready does nothing: otherwise a second text box would open
; after Enter, and its scan would replace the first one, so the first line was lost.
; With the microphone the conversation starts without scanning, so it listens sooner. The scan runs while the player speaks and goes with
; their line (MantellaConversation.UseRoomMicScan). With nobody around, the player hears "Nobody answers" after speaking
Function SayToRoom(MantellaRepository repository, MantellaConversation conversation) global
    if conversation.IsRunning() || !conversation.BeginSayToRoom()
        return
    endIf
    SayToRoomOnce(repository, conversation)
    conversation.EndSayToRoom()
EndFunction

Function SayToRoomOnce(MantellaRepository repository, MantellaConversation conversation) global
    string line = ""
    Actor[] nearby
    if !repository.microphoneEnabled
        int scanId = conversation.StartRoomScan()
        UIExtensions.InitMenu("UITextEntryMenu")
        UIExtensions.OpenMenu("UITextEntryMenu")
        line = UIExtensions.GetMenuResultString("UITextEntryMenu")
        if line == "" || conversation.IsRunning() ; Cancelled, or something else started a conversation while the text box was open
            conversation.CancelRoomScan(scanId)
            return
        endIf
        if !conversation.FinishRoomScan(scanId)
            return ; Replaced by a newer Say
        endIf
        nearby = conversation.GetRoomScanResult()
        if !nearby || nearby.Length == 0
            Debug.Notification("Nobody is around to hear you")
            return
        endIf
    else
        Debug.Notification("Getting ready...")
    endIf
    if conversation.IsRunning()
        return ; Something else started a conversation during the scan
    endIf
    Actor[] actors = new Actor[1]
    actors[0] = Game.GetPlayer()
    conversation.Start()
    conversation.SetRoomStart(line, nearby)
    conversation.StartConversation(actors)
EndFunction
