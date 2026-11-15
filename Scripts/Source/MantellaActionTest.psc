Scriptname MantellaActionTest Hidden
{In-game test of the NPC actions. Started from the console by the batch file that tests/ingame/actions/actions_ingame.py in the Mantella
repository writes (bat mta). That script also points MantellaSoftware at a stand-in AI service on this PC, which answers each of the player's
lines with the action its "ACTIONTEST_..." cue asks for, so each action happens on cue. This script says the player's lines, then checks what
really happened in the game: the NPC follows, a menu opens, the NPC fights or stops. Each check is noted "Action test: PASS <id> ..." or
"Action test: FAIL <id> ...", on screen and in Papyrus.0.log, which the Python script reads}

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
    repository.microphoneEnabled = false ; The test types the player's lines

    if Start(conversation, npc)
        ; 1. With the menu's NPC Actions switches off (the default), the actions do nothing
        SetSwitches(repository, false, false, false)
        SayCue(conversation, "follow", "Come with me.")
        MantellaTalkTest.WaitForTurn(conversation)
        Utility.Wait(SETTLE())
        Check(!IsFollowing(repository, npc), "follow-off", "with Allow Follow off, the NPC doesn't follow you")

        SayCue(conversation, "inventory", "What are you carrying?")
        Check(!MenuOpensByTurn(conversation), "inventory-off", "with Allow Inventory off, no menu opens")
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
        MantellaFollowerUtils.DismissFollower(npc, repository.gia_FollowerQst, repository.giafac_Following)

        SayCue(conversation, "inventory", "What are you carrying?")
        Check(MenuOpens(TIMEOUT()), "inventory-on", "Inventory: the give and take menu opens")
        MantellaTalkTest.WaitForTurn(conversation)

        ; Typing just an action's name makes the NPC do it, without asking the AI
        Say(conversation, "Inventory")
        Check(MenuOpens(TIMEOUT()), "inventory-typed", "typing Inventory opens the menu")
        MantellaTalkTest.WaitForTurn(conversation)

        SayCue(conversation, "offended", "You look ridiculous.")
        Check(BecomesHostile(npc, player), "offended-on", "Offended: the NPC attacks you")
        MantellaTalkTest.WaitForTurn(conversation)

        if !conversation.IsRunning() ; A fight may end the conversation. Forgiving needs one
            Start(conversation, npc)
        endIf
        SayCue(conversation, "forgiven", "I'm sorry, I didn't mean it.")
        Check(StopsFighting(npc), "forgiven-on", "Forgiven: the NPC stops fighting")
        MantellaTalkTest.WaitForTurn(conversation)
        MantellaEventTest.EndConversation(conversation)
    else
        Note("FAIL setup: the conversation with " + npc.GetDisplayName() + " didn't start. Is Mantella running with the test's settings?")
    endIf

    ; Put back what the test changed
    StopFighting(npc)
    if IsFollowing(repository, npc)
        MantellaFollowerUtils.DismissFollower(npc, repository.gia_FollowerQst, repository.giafac_Following)
    endIf
    SetSwitches(repository, aggroWas, followWas, inventoryWas)
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

; The nearest NPC who can talk and is safe to test with: not a guard (a fight would bring the town down), not a child, not a follower
Actor Function FindNpc(MantellaRepository repository, MantellaConversation conversation) global
    Actor[] people = MantellaShout.FindNearbyWith(repository, conversation, 20.0, false, false, 10)
    int i = 0
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

; Whether the give and take menu opens while the NPC answers, or just after. Waits in menu time, so an open menu doesn't stop the wait
bool Function MenuOpensByTurn(MantellaConversation conversation) global
    float waited = 0.0
    while conversation.IsRunning() && !conversation.IsPlayersTurn() && !UI.IsMenuOpen("ContainerMenu") && waited < TIMEOUT()
        Utility.WaitMenuMode(0.25)
        waited += 0.25
    endWhile
    return MenuOpens(SETTLE())
EndFunction

; Whether the give and take menu opens within the time. Closes it again. Waits in menu time, as the open menu pauses the game
bool Function MenuOpens(float seconds) global
    float waited = 0.0
    while !UI.IsMenuOpen("ContainerMenu") && waited < seconds
        Utility.WaitMenuMode(0.25)
        waited += 0.25
    endWhile
    if !UI.IsMenuOpen("ContainerMenu")
        return false
    endIf
    Utility.WaitMenuMode(1.0)
    Input.TapKey(Input.GetMappedKey("Tween Menu")) ; Tab closes it
    waited = 0.0
    while UI.IsMenuOpen("ContainerMenu") && waited < 3.0
        Utility.WaitMenuMode(0.25)
        waited += 0.25
    endWhile
    if UI.IsMenuOpen("ContainerMenu")
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
