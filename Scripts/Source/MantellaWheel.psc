Scriptname MantellaWheel Hidden
{The Conversation Wheel: one hotkey opens a wheel with the Mantella options that make sense right now.
See docs/conversation_wheel.md in the Mantella repository}

; What a wheel option does
int Function ACTION_TALK_TO_COMPANIONS() global
    return 1
EndFunction
int Function ACTION_TALK_TO_TARGET() global ; Starts a conversation with the person you look at, or adds them to the running one
    return 2
EndFunction
int Function ACTION_REMOVE_TARGET() global
    return 3
EndFunction
int Function ACTION_TOGGLE_COMPANION() global
    return 4
EndFunction
int Function ACTION_START_NPC_EVENT() global
    return 5
EndFunction
int Function ACTION_INTERRUPT() global ; Also how a bystander steps into an NPC Event
    return 6
EndFunction
int Function ACTION_JOIN() global ; Joins a conversation between NPCs
    return 7
EndFunction
int Function ACTION_ADD_COMPANIONS() global
    return 8
EndFunction
int Function ACTION_END() global
    return 9
EndFunction
int Function ACTION_SHOUT() global ; Anyone nearby can answer or join in. See MantellaShout
    return 10
EndFunction
int Function ACTION_PRIVATE() global ; Shout off: nobody new joins. Everyone already in the conversation stays
    return 11
EndFunction
int Function ACTION_SAY_TO_ROOM() global ; Just saying something: said to whoever is around. See MantellaShout.SayToRoom
    return 12
EndFunction

string Function COMPANIONS_KEY() global ; StorageUtil form list on the player, saved with the game
    return "Mantella_Companions"
EndFunction

float Function COMPANION_RANGE() global ; 20 meters, in game units
    return 20.0 * 71.0210
EndFunction

int Function MAX_COMPANIONS() global ; The nearest ones are taken
    return 6
EndFunction

; The wheel's places in the order they are filled: the left and right side in turn, top to bottom (0-3 left, 4-7 right)
int Function SlotForOption(int optionNumber) global
    if optionNumber % 2 == 0
        return optionNumber / 2
    endIf
    return 4 + optionNumber / 2
EndFunction

; Opens the wheel and runs the clicked option. Called by MantellaRepository, which closes it when the hotkey is let go
Function Open(MantellaRepository repository) global
    MantellaConversation conversation = Quest.GetQuest("MantellaConversation") as MantellaConversation
    Actor player = Game.GetPlayer()
    Actor target = Game.GetCurrentCrosshairRef() as Actor
    if target && (target == player || target.IsDead() || target.IsDisabled())
        target = None
    endIf
    string name = ""
    if target
        name = target.GetDisplayName()
    endIf
    bool isRunning = conversation.IsRunning()
    bool isPlayerIn = isRunning && conversation.IsPlayerInConversation()

    ; Only quick checks here, so the wheel shows right away. Who the companions are is worked out after the choice
    UIMenuBase wheel = UIExtensions.GetMenu("UIWheelMenu", true)
    int[] actions = new int[8]
    int count = 0
    if !isRunning
        count = AddOption(wheel, actions, count, "Companions", "Talk to my companions", ACTION_TALK_TO_COMPANIONS())
        count = AddOption(wheel, actions, count, "Say", "Say something to anyone nearby", ACTION_SAY_TO_ROOM())
        if target
            count = AddOption(wheel, actions, count, "Talk", "Talk to " + name, ACTION_TALK_TO_TARGET())
            if IsOnCompanionsList(target)
                count = AddOption(wheel, actions, count, "Not companion", "Take " + name + " off my companions list", ACTION_TOGGLE_COMPANION())
            else
                count = AddOption(wheel, actions, count, "Companion", "Put " + name + " on my companions list", ACTION_TOGGLE_COMPANION())
            endIf
        endIf
        count = AddOption(wheel, actions, count, "Event", "Something happens: start an NPC Event nearby", ACTION_START_NPC_EVENT())
    else
        if isPlayerIn
            count = AddOption(wheel, actions, count, "Interrupt", "Stop the NPCs and take my turn", ACTION_INTERRUPT())
        elseIf conversation.IsNpcEvent()
            count = AddOption(wheel, actions, count, "Step in", "Step into the scene", ACTION_INTERRUPT())
        else
            count = AddOption(wheel, actions, count, "Join", "Join the conversation", ACTION_JOIN())
        endIf
        count = AddOption(wheel, actions, count, "End", "End the conversation", ACTION_END())
        if target
            if conversation.Participants.HasForm(target)
                count = AddOption(wheel, actions, count, "Remove", "Send " + name + " away", ACTION_REMOVE_TARGET())
            else
                count = AddOption(wheel, actions, count, "Add", "Bring " + name + " in", ACTION_TALK_TO_TARGET())
            endIf
        endIf
        if isPlayerIn
            count = AddOption(wheel, actions, count, "Companions", "Bring my companions in", ACTION_ADD_COMPANIONS())
            if !conversation.IsNpcEvent() ; NPC Events keep their own rules for drawing people in
                if conversation.IsShouting()
                    count = AddOption(wheel, actions, count, "Private", "Nobody new joins", ACTION_PRIVATE())
                else
                    count = AddOption(wheel, actions, count, "Shout", "Anyone nearby can answer or join in", ACTION_SHOUT())
                endIf
            endIf
        endIf
    endIf

    wheel.SetPropertyInt("lastIndex", 0) ; Opens pointing at the first option, as MantellaRepository expects

    int returned = wheel.OpenMenu(target)
    ; MantellaRepository knows what was picked. UIWheelMenu's own answer is only used if a choice made with Activate
    ; hasn't reached MantellaRepository yet. When the wheel was closed without a choice, that answer is an old choice
    int choice = repository.GetWheelChoice()
    if choice < 0 && !repository.WasWheelCancelled()
        choice = returned
    endIf
    repository.WheelFinished() ; The wheel can open again while the option runs
    if choice < 0 || choice > 7
        return
    endIf
    RunAction(actions[choice], repository, conversation, target)
EndFunction

; Puts the option in the next free place of the wheel. The label is shown on the wheel, the text below it when the option is
; pointed at. Labels longer than about 12 letters are cut off. Returns the new number of options
int Function AddOption(UIMenuBase wheel, int[] actions, int count, string label, string text, int actionId) global
    int slot = SlotForOption(count)
    wheel.SetPropertyIndexString("optionLabelText", slot, label)
    wheel.SetPropertyIndexString("optionText", slot, text)
    wheel.SetPropertyIndexBool("optionEnabled", slot, true)
    actions[slot] = actionId
    return count + 1
EndFunction

Function RunAction(int actionId, MantellaRepository repository, MantellaConversation conversation, Actor target) global
    Actor player = Game.GetPlayer()
    if actionId == ACTION_TALK_TO_COMPANIONS()
        StartWithCompanions(repository, conversation)
    elseIf actionId == ACTION_SAY_TO_ROOM()
        MantellaShout.SayToRoom(repository, conversation)
    elseIf actionId == ACTION_TALK_TO_TARGET()
        repository.MantellaSpell.Cast(player, target) ; Starts the conversation or adds them, like the Start / Add hotkey
    elseIf actionId == ACTION_REMOVE_TARGET()
        repository.MantellaRemoveNpcSpell.Cast(player, target)
    elseIf actionId == ACTION_TOGGLE_COMPANION()
        ToggleCompanion(target)
    elseIf actionId == ACTION_START_NPC_EVENT()
        player.SendModEvent("Mantella_NpcEventHotkey") ; The same as the NPC Event hotkey. The check lives in MantellaListenerScript
    elseIf actionId == ACTION_INTERRUPT()
        if conversation.IsRunning()
            conversation.RequestInterrupt()
        endIf
    elseIf actionId == ACTION_JOIN()
        if conversation.IsRunning() && !conversation.IsPlayerInConversation()
            Actor[] actors = new Actor[1]
            actors[0] = player
            Debug.Notification("Adding player to conversation...")
            conversation.AddActorsToConversation(actors)
        endIf
    elseIf actionId == ACTION_ADD_COMPANIONS()
        AddCompanions(repository, conversation)
    elseIf actionId == ACTION_END()
        repository.MantellaEndSpell.Cast(player)
    elseIf actionId == ACTION_SHOUT()
        if conversation.IsRunning() && conversation.IsPlayerInConversation()
            conversation.SetShout(true)
        endIf
    elseIf actionId == ACTION_PRIVATE()
        conversation.SetShout(false)
    endIf
EndFunction

Function StartWithCompanions(MantellaRepository repository, MantellaConversation conversation) global
    if conversation.IsRunning()
        return ; Started while the wheel was open
    endIf
    Actor[] companions = FindNearbyCompanions(repository, conversation)
    if companions.Length == 0
        Debug.Notification("None of your companions are nearby")
        return
    endIf
    Actor[] actors = PapyrusUtil.ActorArray(companions.Length + 1)
    actors[0] = Game.GetPlayer()
    int i = 0
    while i < companions.Length
        actors[i + 1] = companions[i]
        i += 1
    endWhile
    Debug.Notification("Starting conversation with " + CompanionNames(companions) + "...")
    conversation.Start()
    conversation.SetGroupStart()
    conversation.StartConversation(actors)
EndFunction

Function AddCompanions(MantellaRepository repository, MantellaConversation conversation) global
    if !conversation.IsRunning()
        return
    endIf
    Actor[] companions = FindNearbyCompanions(repository, conversation)
    if companions.Length == 0
        Debug.Notification("No other companions are nearby")
        return
    endIf
    Debug.Notification("Adding " + CompanionNames(companions) + " to conversation...")
    conversation.AddActorsToConversation(companions)
EndFunction

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;         Companions          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bool Function IsOnCompanionsList(Actor npc) global
    return StorageUtil.FormListFind(Game.GetPlayer(), COMPANIONS_KEY(), npc) >= 0
EndFunction

Function ToggleCompanion(Actor npc) global
    if !npc
        return
    endIf
    if IsOnCompanionsList(npc)
        StorageUtil.FormListRemove(Game.GetPlayer(), COMPANIONS_KEY(), npc, true)
        Debug.Notification(npc.GetDisplayName() + " is no longer on your companions list")
    else
        StorageUtil.FormListAdd(Game.GetPlayer(), COMPANIONS_KEY(), npc, false)
        Debug.Notification(npc.GetDisplayName() + " is now on your companions list")
    endIf
EndFunction

; Your active followers and the people on your companions list who are nearby, free to talk and not in the conversation yet.
; The nearest ones first, at most MAX_COMPANIONS
Actor[] Function FindNearbyCompanions(MantellaRepository repository, MantellaConversation conversation) global
    Actor player = Game.GetPlayer()
    float range = COMPANION_RANGE()
    int maxCount = MAX_COMPANIONS()
    Actor[] found = new Actor[6] ; MAX_COMPANIONS
    float[] distances = new float[6]
    int count = 0
    Actor npc

    Actor[] scanned = MiscUtil.ScanCellNPCs(player, range)
    int i = 0
    while i < scanned.Length
        npc = scanned[i]
        if MantellaActorChecks.IsActiveFollower(npc, repository) && IsFreeCompanion(npc, conversation)
            count = InsertByDistance(found, distances, count, maxCount, npc, player.GetDistance(npc))
        endIf
        i += 1
    endWhile

    i = StorageUtil.FormListCount(player, COMPANIONS_KEY())
    while i > 0
        i -= 1
        npc = StorageUtil.FormListGet(player, COMPANIONS_KEY(), i) as Actor
        if npc && npc.Is3DLoaded() && found.Find(npc) < 0 && IsFreeCompanion(npc, conversation)
            float distance = player.GetDistance(npc)
            if distance <= range
                count = InsertByDistance(found, distances, count, maxCount, npc, distance)
            endIf
        endIf
    endWhile

    Actor[] result = PapyrusUtil.ActorArray(count)
    i = 0
    while i < count
        result[i] = found[i]
        i += 1
    endWhile
    return result
EndFunction

bool Function IsFreeCompanion(Actor npc, MantellaConversation conversation) global
    if !MantellaActorChecks.IsAvailableNpc(npc)
        return false
    endIf
    return !conversation.IsRunning() || !conversation.Participants.HasForm(npc)
EndFunction

; Keeps the nearest people in found, sorted by distance. Returns the new count
int Function InsertByDistance(Actor[] found, float[] distances, int count, int maxCount, Actor npc, float distance) global
    int pos = count
    while pos > 0 && distances[pos - 1] > distance
        pos -= 1
    endWhile
    if pos >= maxCount
        return count
    endIf
    int last = count
    if last >= maxCount
        last = maxCount - 1
    endIf
    while last > pos
        found[last] = found[last - 1]
        distances[last] = distances[last - 1]
        last -= 1
    endWhile
    found[pos] = npc
    distances[pos] = distance
    if count < maxCount
        count += 1
    endIf
    return count
EndFunction

string Function CompanionNames(Actor[] companions) global
    string names = ""
    int i = 0
    while i < companions.Length
        if i > 0
            names += ", "
        endIf
        names += companions[i].GetDisplayName()
        i += 1
    endWhile
    return names
EndFunction
