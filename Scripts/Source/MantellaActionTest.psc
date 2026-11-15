Scriptname MantellaActionTest Hidden
{In-game test of the NPC actions. Started from the console by the batch file that tests/ingame/actions/actions_ingame.py in the Mantella
repository writes (bat mta). That script also points MantellaSoftware at a stand-in AI service on this PC, which answers each of the player's
lines with the action its "ACTIONTEST_..." cue asks for, so each action happens on cue. This script says the player's lines, then checks what
really happened in the game: the NPC follows or stops following, waits, a menu opens, the NPC appears next to you or walks over,
fights, runs away or stops. Each check is noted
"Action test: PASS <id> ..." or "Action test: FAIL <id> ...", on screen and in Papyrus.0.log, which the Python script reads}

float Function TIMEOUT() global ; Seconds to wait for an action to show in the game. The NPC's line is voiced first
    return 30.0
EndFunction

float Function SETTLE() global ; Seconds to wait after the NPC's line before checking that nothing happened. The action starts with the line
    return 1.5
EndFunction

Function Run(MantellaRepository repository, MantellaConversation conversation, MantellaListenerScript listener) global
    if conversation.IsRunning()
        Stop("end the conversation first")
        return
    endIf
    Note("starting")
    Utility.Wait(3.0) ; The place has just loaded
    Actor npc = FindNpc(repository, conversation)
    if !npc
        Note("FAIL setup: nobody to test with. It needs an NPC within 20 m who isn't a guard, a child or a follower")
        Done()
        return
    endIf
    Actor player = Game.GetPlayer()
    ; What the test changes, put back at the end
    bool micWas = repository.microphoneEnabled
    bool aggroWas = player.IsInFaction(repository.giafac_AllowAnger)
    bool followWas = player.IsInFaction(repository.giafac_AllowFollower)
    bool inventoryWas = player.IsInFaction(repository.fac_AllowInventory)
    float waitingWas = npc.GetActorValue("WaitingForPlayer")
    repository.microphoneEnabled = false ; The test types the player's lines
    ; The actions that make an NPC walk somewhere (MoveTo, Flee, Loot) put them in this faction while they do, at a rank for each
    Faction actionFaction = Game.GetFormFromFile(0x223451, "Mantella.esp") as Faction ; MantellaFunctionSourceFaction
    ObjectReference start = player.PlaceAtMe(Game.GetFormFromFile(0x00003B, "Skyrim.esm")) ; An XMarker where you start, to come back to

    if Start(conversation, npc)
        ; 1. With the menu's NPC Actions switches off (the default), the actions do nothing
        SetSwitches(repository, false, false, false)
        SayCue(conversation, "follow", "Come with me.")
        MantellaTalkTest.WaitForTurn(conversation)
        Utility.Wait(SETTLE())
        Check(!IsFollowing(repository, npc), "follow-off", "with Allow Follow off, the NPC doesn't follow you")

        SayCue(conversation, "inventory", "What are you carrying?")
        Check(!MenuOpensByTurn(conversation, "ContainerMenu"), "inventory-off", "with Allow Inventory off, no menu opens")
        MantellaTalkTest.WaitForTurn(conversation)

        SayCue(conversation, "offended", "You look ridiculous.")
        MantellaTalkTest.WaitForTurn(conversation)
        Utility.Wait(SETTLE())
        Check(!npc.IsInCombat(), "offended-off", "with Allow Aggro off, the NPC doesn't attack you")
        StopFighting(npc)

        ; 2. With them on, each action happens
        SetSwitches(repository, true, true, true)
        SayCue(conversation, "follow", "Come with me.")
        Check(BecomesFollower(repository, npc), "follow-on", "Follow: the NPC follows you")
        MantellaTalkTest.WaitForTurn(conversation)

        SayCue(conversation, "unfollow", "You can stop following me now.")
        Check(StopsFollowing(repository, npc), "unfollow-on", "Unfollow: the NPC stops following you")
        MantellaTalkTest.WaitForTurn(conversation)

        SayCue(conversation, "wait", "Wait here for me.")
        Check(StartsWaiting(npc), "wait-on", "Wait: the NPC waits where they are")
        MantellaTalkTest.WaitForTurn(conversation)
        npc.SetActorValue("WaitingForPlayer", waitingWas)
        npc.EvaluatePackage()

        SayCue(conversation, "inventory", "What are you carrying?")
        Check(MenuOpens("ContainerMenu", TIMEOUT()), "inventory-on", "Inventory: the give and take menu opens")
        MantellaTalkTest.WaitForTurn(conversation)

        ; Typing just an action's name makes the NPC do it, without asking the AI
        Say(conversation, "Inventory")
        Check(MenuOpens("ContainerMenu", TIMEOUT()), "inventory-typed", "typing Inventory opens the menu")
        MantellaTalkTest.WaitForTurn(conversation)

        SayCue(conversation, "barter", "What do you have for sale?")
        Check(MenuOpens("BarterMenu", TIMEOUT()), "barter-on", "Barter: the NPC's shop opens")
        MantellaTalkTest.WaitForTurn(conversation)

        ; Loot is switched off for one-on-one conversations in Mantella's settings (as by default), so saying it does nothing
        SayCue(conversation, "loot", "Anything worth taking around here?")
        MantellaTalkTest.WaitForTurn(conversation)
        Utility.Wait(SETTLE())
        Check(npc.GetFactionRank(actionFaction) != LOOTING(), "loot-switched-off", "with Loot switched off in Mantella's settings, the NPC doesn't start looting")
        StopAction(npc, actionFaction)

        ; Teleport and MoveTo: you go and stand by someone across the room from the NPC, who then comes to you
        Actor across = MoveAcrossFrom(repository, conversation, npc)
        if across
            SayCue(conversation, "teleport", "Get over here, now.")
            Check(Teleports(npc, player), "teleport-on", "Teleport: the NPC appears next to you at once")
            MantellaTalkTest.WaitForTurn(conversation)
        else
            Note("FAIL teleport-on nobody " + Meters(FAR()) + " or more from " + npc.GetDisplayName() + " to go and stand by, so the test couldn't check Teleport")
        endIf

        KeepTalking(conversation, npc)
        across = MoveAcrossFrom(repository, conversation, npc)
        if across
            SayCue(conversation, "moveto", "Come over here.")
            Check(WalksOver(npc, player, actionFaction), "moveto-on", "MoveTo: the NPC walks over to you")
            MantellaTalkTest.WaitForTurn(conversation)
        else
            Note("FAIL moveto-on nobody " + Meters(FAR()) + " or more from " + npc.GetDisplayName() + " to go and stand by, so the test couldn't check MoveTo")
        endIf

        ; Brawl, then Flee, which ends the fistfight
        KeepTalking(conversation, npc)
        SayCue(conversation, "brawl", "Fancy a fistfight?")
        Check(BecomesHostile(npc, player), "brawl-on", "Brawl: the NPC starts a fistfight with you")
        MantellaTalkTest.WaitForTurn(conversation)

        KeepTalking(conversation, npc) ; A fight may end the conversation
        float fleeingFrom = npc.GetDistance(player)
        SayCue(conversation, "flee", "Had enough?")
        Check(BecomesRank(npc, actionFaction, FLEEING()), "flee-on", "Flee: the NPC runs away from you")
        MantellaTalkTest.WaitForTurn(conversation)
        Utility.Wait(SETTLE())
        Note("while fleeing, " + npc.GetDisplayName() + " went from " + Meters(fleeingFrom) + " to " + Meters(npc.GetDistance(player)) + " away from you")
        StopAction(npc, actionFaction)
        StopFighting(npc)

        KeepTalking(conversation, npc)
        SayCue(conversation, "offended", "You look ridiculous.")
        Check(BecomesHostile(npc, player), "offended-on", "Offended: the NPC attacks you")
        MantellaTalkTest.WaitForTurn(conversation)

        KeepTalking(conversation, npc) ; A fight may end the conversation. Forgiving needs one
        SayCue(conversation, "forgiven", "I'm sorry, I didn't mean it.")
        Check(StopsFighting(npc), "forgiven-on", "Forgiven: the NPC stops fighting")
        MantellaTalkTest.WaitForTurn(conversation)
        MantellaEventTest.EndConversation(conversation)
    else
        Note("FAIL setup: the conversation with " + npc.GetDisplayName() + " didn't start. Is Mantella running with the test's settings?")
    endIf

    ; Put back what the test changed
    StopAction(npc, actionFaction)
    StopFighting(npc)
    player.MoveTo(start)
    start.Delete()
    if IsFollowing(repository, npc)
        MantellaFollowerUtils.DismissFollower(npc, repository.gia_FollowerQst, repository.giafac_Following)
    endIf
    SetSwitches(repository, aggroWas, followWas, inventoryWas)
    npc.SetActorValue("WaitingForPlayer", waitingWas)
    npc.EvaluatePackage()
    repository.microphoneEnabled = micWas
    Done()
EndFunction

; Stays on screen until closed, so the end isn't missed
Function Done() global
    Stop("done. Now press Enter in the window of actions_ingame.py")
EndFunction

; A last note that stays on screen until closed
Function Stop(string text) global
    Note(text)
    Debug.MessageBox("Action test: " + text)
EndFunction

; Hulda, who keeps the Bannered Mare and has a shop, if she can talk. Otherwise the nearest NPC who can talk and is safe to test with:
; not a guard (a fight would bring the town down), not a child, not a follower
Actor Function FindNpc(MantellaRepository repository, MantellaConversation conversation) global
    Actor[] people = MantellaShout.FindNearbyWith(repository, conversation, 20.0, false, false, 10)
    Actor hulda = Game.GetFormFromFile(0x01A66E, "Skyrim.esm") as Actor
    int i = 0
    while i < people.Length
        if people[i] && people[i] == hulda && !IsFollowing(repository, hulda)
            return hulda
        endIf
        i += 1
    endWhile
    i = 0
    while i < people.Length
        Actor npc = people[i]
        if npc && !npc.IsGuard() && !npc.IsChild() && !IsFollowing(repository, npc)
            return npc
        endIf
        i += 1
    endWhile
    return None
EndFunction

bool Function Start(MantellaConversation conversation, Actor npc) global
    Actor[] actors = new Actor[2]
    actors[0] = Game.GetPlayer()
    actors[1] = npc
    if !MantellaEventTest.StartConversation(conversation, actors, false)
        return false
    endIf
    MantellaTalkTest.WaitForTurn(conversation)
    return conversation.IsRunning()
EndFunction

; The menu's Allow Aggro, Allow Follow and Allow Inventory: each puts the player in a faction the action scripts check
Function SetSwitches(MantellaRepository repository, bool aggro, bool follow, bool inventory) global
    SetFaction(repository.giafac_AllowAnger, aggro)
    SetFaction(repository.giafac_AllowFollower, follow)
    SetFaction(repository.fac_AllowInventory, inventory)
EndFunction

Function SetFaction(Faction switchFaction, bool isOn) global
    Actor player = Game.GetPlayer()
    if isOn
        player.AddToFaction(switchFaction)
    else
        player.RemoveFromFaction(switchFaction)
    endIf
EndFunction

; A line with the cue the stand-in AI service answers with that action, said once it is the player's turn
Function SayCue(MantellaConversation conversation, string cue, string line) global
    MantellaTalkTest.WaitForTurn(conversation)
    Say(conversation, "ACTIONTEST_" + cue + " " + line)
EndFunction

Function Say(MantellaConversation conversation, string line) global
    MantellaTalkTest.WaitForTurn(conversation)
    if !conversation.IsRunning() || !conversation.IsPlayersTurn()
        Note("not the player's turn, so not said: " + line)
        return
    endIf
    Note("saying: " + line)
    conversation.SayAsPlayer(line)
EndFunction

bool Function IsFollowing(MantellaRepository repository, Actor npc) global
    return npc.GetFactionRank(repository.giafac_Following) >= 1
EndFunction

bool Function BecomesFollower(MantellaRepository repository, Actor npc) global
    float waited = 0.0
    while !IsFollowing(repository, npc) && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return IsFollowing(repository, npc)
EndFunction

bool Function StopsFollowing(MantellaRepository repository, Actor npc) global
    float waited = 0.0
    while IsFollowing(repository, npc) && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return !IsFollowing(repository, npc)
EndFunction

bool Function StartsWaiting(Actor npc) global
    float waited = 0.0
    while npc.GetActorValue("WaitingForPlayer") < 1 && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return npc.GetActorValue("WaitingForPlayer") >= 1
EndFunction

bool Function BecomesHostile(Actor npc, Actor player) global
    float waited = 0.0
    while !(npc.IsInCombat() && npc.GetCombatTarget() == player) && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return npc.IsInCombat() && npc.GetCombatTarget() == player
EndFunction

bool Function StopsFighting(Actor npc) global
    float waited = 0.0
    while npc.IsInCombat() && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return !npc.IsInCombat()
EndFunction

Function StopFighting(Actor npc) global
    if npc.IsInCombat()
        npc.StopCombat()
    endIf
EndFunction

; The ranks in MantellaFunctionSourceFaction: what an action has the NPC doing
int Function MOVING() global ; MoveTo
    return 1
EndFunction

int Function LOOTING() global
    return 3
EndFunction

int Function FLEEING() global
    return 4
EndFunction

float Function FAR() global ; How far from the NPC you go and stand for Teleport and MoveTo, in game units: about 6 m
    return 420.0
EndFunction

float Function NEXT_TO() global ; Near enough to count as next to you, in game units: about 4.5 m. MoveTo stops within 3.6 m
    return 320.0
EndFunction

string Function Meters(float units) global
    return ((units / MantellaShout.METER_UNITS()) as int) + " m"
EndFunction

; Starts the conversation again if it ended. A fight can end it
Function KeepTalking(MantellaConversation conversation, Actor npc) global
    if !conversation.IsRunning()
        Start(conversation, npc)
    endIf
EndFunction

; Takes you to someone nearby who stands FAR() or more from the NPC: the nearest of them the NPC can see, so the NPC has a short, clear
; way over. Returns them, or None if nobody is far enough
Actor Function MoveAcrossFrom(MantellaRepository repository, MantellaConversation conversation, Actor npc) global
    Actor[] people = MantellaShout.FindNearbyWith(repository, conversation, 20.0, false, false, 10)
    Actor seen = None
    Actor unseen = None
    int i = 0
    while i < people.Length
        Actor person = people[i]
        if person && person != npc && npc.GetDistance(person) >= FAR()
            if npc.HasLOS(person)
                if !seen || npc.GetDistance(person) < npc.GetDistance(seen)
                    seen = person
                endIf
            elseIf !unseen || npc.GetDistance(person) < npc.GetDistance(unseen)
                unseen = person
            endIf
        endIf
        i += 1
    endWhile
    Actor across = seen
    if !across
        across = unseen
    endIf
    if across
        Actor player = Game.GetPlayer()
        player.MoveTo(across)
        Utility.Wait(1.0) ; The place settles around you
        Note("you now stand by " + across.GetDisplayName() + ", " + Meters(npc.GetDistance(player)) + " from " + npc.GetDisplayName())
    endIf
    return across
EndFunction

; Teleport: from one look to the next, the NPC goes from across the room to next to you, faster than anyone can run
bool Function Teleports(Actor npc, Actor player) global
    float distance = npc.GetDistance(player)
    float time = Utility.GetCurrentRealTime()
    float waited = 0.0
    while waited < TIMEOUT()
        Utility.Wait(0.25)
        waited += 0.25
        float nowDistance = npc.GetDistance(player)
        float now = Utility.GetCurrentRealTime()
        float closer = distance - nowDistance
        if nowDistance < NEXT_TO() && closer > 250.0 && closer / (now - time) > 1500.0
            return true
        endIf
        distance = nowDistance
        time = now
    endWhile
    Note(npc.GetDisplayName() + " didn't appear next to you: " + Meters(npc.GetDistance(player)) + " away")
    return false
EndFunction

; MoveTo: the NPC gets MoveTo's rank in the action faction, which tells it from wandering over by chance, and comes next to you
bool Function WalksOver(Actor npc, Actor player, Faction actionFaction) global
    bool moving = false
    float waited = 0.0
    while waited < TIMEOUT() && !(moving && npc.GetDistance(player) < NEXT_TO())
        if npc.GetFactionRank(actionFaction) == MOVING()
            moving = true
        endIf
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    if !moving
        Note(npc.GetDisplayName() + " wasn't sent walking by MoveTo")
    elseIf npc.GetDistance(player) >= NEXT_TO()
        Note(npc.GetDisplayName() + " set off but is still " + Meters(npc.GetDistance(player)) + " away")
    endIf
    return moving && npc.GetDistance(player) < NEXT_TO()
EndFunction

bool Function BecomesRank(Actor npc, Faction actionFaction, int rank) global
    float waited = 0.0
    while npc.GetFactionRank(actionFaction) != rank && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return npc.GetFactionRank(actionFaction) == rank
EndFunction

; Ends what an action has the NPC doing (walking over, fleeing, looting), as StandDown does
Function StopAction(Actor npc, Faction actionFaction) global
    npc.RemoveFromFaction(actionFaction)
    npc.EvaluatePackage()
EndFunction

; Whether the menu (ContainerMenu: give and take, BarterMenu: the shop) opens while the NPC answers, or just after. Waits in menu time,
; so an open menu doesn't stop the wait
bool Function MenuOpensByTurn(MantellaConversation conversation, string menu) global
    float waited = 0.0
    while conversation.IsRunning() && !conversation.IsPlayersTurn() && !UI.IsMenuOpen(menu) && waited < TIMEOUT()
        Utility.WaitMenuMode(0.25)
        waited += 0.25
    endWhile
    return MenuOpens(menu, SETTLE())
EndFunction

; Whether the menu opens within the time. Closes it again. Waits in menu time, as the open menu pauses the game
bool Function MenuOpens(string menu, float seconds) global
    float waited = 0.0
    while !UI.IsMenuOpen(menu) && waited < seconds
        Utility.WaitMenuMode(0.25)
        waited += 0.25
    endWhile
    if !UI.IsMenuOpen(menu)
        return false
    endIf
    Utility.WaitMenuMode(1.0)
    Input.TapKey(Input.GetMappedKey("Tween Menu")) ; Tab closes it
    waited = 0.0
    while UI.IsMenuOpen(menu) && waited < 3.0
        Utility.WaitMenuMode(0.25)
        waited += 0.25
    endWhile
    if UI.IsMenuOpen(menu)
        Input.TapKey(1) ; Escape
    endIf
    return true
EndFunction

Function Check(bool ok, string id, string text) global
    if ok
        Note("PASS " + id + " " + text)
    else
        Note("FAIL " + id + " " + text)
    endIf
EndFunction

; On screen, and in the Papyrus log (Papyrus.0.log) when Papyrus logging is on
Function Note(string text) global
    Debug.Notification("Action test: " + text)
    Debug.Trace("Action test: " + text)
EndFunction
