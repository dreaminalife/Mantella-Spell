Scriptname MantellaActionTest Hidden
{In-game test of the NPC actions. Started from the console by the batch file that tests/ingame/actions/actions_ingame.py in the Mantella
repository writes (bat mta). That script also points MantellaSoftware at a stand-in AI service on this PC, which answers each of the player's
lines with the action its "ACTIONTEST_..." cue asks for, so each action happens on cue. This script says the player's lines, then checks what
really happened in the game: the NPC follows or stops following, waits, a menu opens, the NPC appears next to you or walks over,
fights, runs away or stops. Each check is noted
"Action test: PASS <id> ..." or "Action test: FAIL <id> ...", on screen and in Papyrus.0.log, which the Python script reads.
With Advanced Actions on (bat mtaa, RunAdvanced), the stand-in picks each action with its details instead, as a real model would}

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
    bool essentialWas = KeepAlive(npc)
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
            float[] stood = HoldStill(conversation, npc)
            SayCue(conversation, "teleport", "Get over here, now.")
            Check(Teleports(npc, player, stood), "teleport-on", "Teleport: the NPC appears next to you at once")
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

    if npc.IsDead()
        Note(npc.GetDisplayName() + " died during the test")
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
    npc.GetActorBase().SetEssential(essentialWas)
    repository.microphoneEnabled = micWas
    Done()
EndFunction

; With Advanced Actions on (bat mtaa): the stand-in picks each action with its details (tool calling), as a real model would. "@" passes
; the details the stand-in fills in: a name, or two separated by +, with _ for a space
Function RunAdvanced(MantellaRepository repository, MantellaConversation conversation, MantellaListenerScript listener) global
    if conversation.IsRunning()
        Stop("end the conversation first")
        return
    endIf
    Note("starting")
    Note("with Advanced Actions on")
    Utility.Wait(3.0) ; The place has just loaded
    Actor npc = FindNpc(repository, conversation)
    if !npc
        Note("FAIL setup: nobody to test with. It needs an NPC within 20 m who isn't a guard, a child or a follower")
        Done()
        return
    endIf
    Actor player = Game.GetPlayer()
    string playerName = AsDetail(player.GetDisplayName())
    ; What the test changes, put back at the end
    bool micWas = repository.microphoneEnabled
    bool aggroWas = player.IsInFaction(repository.giafac_AllowAnger)
    bool followWas = player.IsInFaction(repository.giafac_AllowFollower)
    bool inventoryWas = player.IsInFaction(repository.fac_AllowInventory)
    float waitingWas = npc.GetActorValue("WaitingForPlayer")
    bool essentialWas = KeepAlive(npc)
    Faction crimeFaction = npc.GetCrimeFaction()
    int bountyWas = 0
    if crimeFaction
        bountyWas = crimeFaction.GetCrimeGold()
    endIf
    float healRateWas = player.GetBaseActorValue("HealRate")
    Spell healingHands = Game.GetFormFromFile(0x04D3F2, "Skyrim.esm") as Spell ; CastSpell's spell, taught to the NPC for the test
    bool knewHealingHands = healingHands && npc.HasSpell(healingHands)
    Actor placedGuard = None ; For ReportCrime: the guard placed next to you, taken away again
    repository.microphoneEnabled = false ; The test types the player's lines
    Faction actionFaction = Game.GetFormFromFile(0x223451, "Mantella.esp") as Faction ; MantellaFunctionSourceFaction
    ObjectReference start = player.PlaceAtMe(Game.GetFormFromFile(0x00003B, "Skyrim.esm"))

    if Start(conversation, npc)
        SetSwitches(repository, true, true, true)

        SayCue(conversation, "tfollow", "Come with me.")
        Check(BecomesFollower(repository, npc), "follow-tool", "Follow: the NPC follows you")
        MantellaTalkTest.WaitForTurn(conversation)

        SayCue(conversation, "tunfollow", "You can stop following me now.")
        Check(StopsFollowing(repository, npc), "unfollow-tool", "Unfollow: the NPC stops following you")
        MantellaTalkTest.WaitForTurn(conversation)

        SayCue(conversation, "twait", "Wait here for me.")
        Check(StartsWaiting(npc), "wait-tool", "Wait: the NPC waits where they are")
        MantellaTalkTest.WaitForTurn(conversation)
        npc.SetActorValue("WaitingForPlayer", waitingWas)
        npc.EvaluatePackage()

        ; Inventory answers back: once the menu is closed, the NPC goes on with the game's answer (checked by actions_ingame.py)
        SayCue(conversation, "tinventory", "What are you carrying?")
        Check(MenuOpens("ContainerMenu", TIMEOUT()), "inventory-tool", "Inventory: the give and take menu opens")
        MantellaTalkTest.WaitForTurn(conversation)

        SayCue(conversation, "tbarter", "What do you have for sale?")
        Check(MenuOpens("BarterMenu", TIMEOUT()), "barter-tool", "Barter: the NPC's shop opens")
        MantellaTalkTest.WaitForTurn(conversation)

        ; CheckDirections answers back: the NPC goes on with the way to Riverwood (checked by actions_ingame.py)
        SayCue(conversation, "tdirections", "How do I get to Riverwood?")
        MantellaTalkTest.WaitForTurn(conversation)

        ; MoveTo and Flee aimed at someone else than you: someone across the room, whom the NPC walks over to, then runs from. They can
        ; only be aimed at the people nearest to you that the game tells Mantella about with each line, so you go and stand by them first
        KeepTalking(conversation, npc)
        Actor other = MoveAcrossFrom(repository, conversation, npc)
        if other
            other.SetDontMove(true)
            SayCue(conversation, "tmoveto@" + AsDetail(other.GetDisplayName()), "Go and stand by " + other.GetDisplayName() + ".")
            Check(WalksOver(npc, other, actionFaction), "moveto-npc", "MoveTo: the NPC walks over to " + other.GetDisplayName())
            MantellaTalkTest.WaitForTurn(conversation)
            StopAction(npc, actionFaction)

            SayCue(conversation, "tflee@" + AsDetail(other.GetDisplayName()), "Get away from " + other.GetDisplayName() + "!")
            Check(BecomesRank(npc, actionFaction, FLEEING()), "flee-npc", "Flee: the NPC runs away from " + other.GetDisplayName())
            MantellaTalkTest.WaitForTurn(conversation)
            StopAction(npc, actionFaction)
            other.SetDontMove(false)
        else
            Note("FAIL moveto-npc nobody " + Meters(FAR()) + " or more from " + npc.GetDisplayName() + " to go and stand by")
            Note("FAIL flee-npc nobody " + Meters(FAR()) + " or more from " + npc.GetDisplayName() + " to go and stand by")
        endIf

        KeepTalking(conversation, npc)
        Actor across = MoveAcrossFrom(repository, conversation, npc)
        if across
            float[] stood = HoldStill(conversation, npc)
            SayCue(conversation, "tteleport@" + playerName, "Get over here, now.")
            Check(Teleports(npc, player, stood), "teleport-tool", "Teleport: the NPC appears next to you at once")
            MantellaTalkTest.WaitForTurn(conversation)
        else
            Note("FAIL teleport-tool nobody " + Meters(FAR()) + " or more from " + npc.GetDisplayName() + " to go and stand by")
        endIf

        ; TravelTo, leaving now, then called back
        KeepTalking(conversation, npc)
        SayCue(conversation, "ttravel", "Go to Riverwood, now.")
        Check(BecomesRank(npc, actionFaction, TRAVELING()), "travelto-tool", "TravelTo: the NPC sets off for Riverwood")
        MantellaTalkTest.WaitForTurn(conversation)
        SayCue(conversation, "tcancel", "Actually, stay.")
        Check(LeavesRank(npc, actionFaction, TRAVELING()), "canceltravel-tool", "CancelTravel: the NPC no longer travels")
        MantellaTalkTest.WaitForTurn(conversation)
        StopAction(npc, actionFaction)

        SayCue(conversation, "tleadto@" + playerName, "Take me to Riverwood.")
        Check(BecomesRank(npc, actionFaction, LEADING()), "leadto-tool", "LeadTo: the NPC leads you to Riverwood")
        MantellaTalkTest.WaitForTurn(conversation)
        StopAction(npc, actionFaction)

        SayCue(conversation, "tloot", "Anything worth taking around here?")
        Check(BecomesRank(npc, actionFaction, LOOTING()), "loot-tool", "Loot: the NPC starts looting")
        MantellaTalkTest.WaitForTurn(conversation)
        StopAction(npc, actionFaction)

        SayCue(conversation, "tcollect", "Could you gather some ingredients?")
        Check(BecomesRank(npc, actionFaction, COLLECTING()), "collectingredients-tool", "CollectIngredients: the NPC starts collecting ingredients")
        MantellaTalkTest.WaitForTurn(conversation)
        StopAction(npc, actionFaction)

        ; CastSpell: Healing Hands on you. Most NPCs know no spell, so the NPC is taught it for the test. You lose some health first, and
        ; your health doesn't come back by itself meanwhile, so only the spell can heal you
        if healingHands
            npc.AddSpell(healingHands, false)
            npc.RestoreActorValue("Magicka", 1000.0)
            player.SetActorValue("HealRate", 0.0)
            float hurt = 30.0
            if player.GetActorValue("Health") < hurt * 2.0
                hurt = player.GetActorValue("Health") / 2.0
            endIf
            player.DamageActorValue("Health", hurt)
            ; The NPC's model only casts spells it is told the NPC knows. Other mods' hidden abilities mustn't push it off that list
            bool listed = conversation.EquipmentDescriber.GetSpellListFromActor(npc).Find(healingHands.GetName()) >= 0
            Check(listed, "castspell-known", "CastSpell: Mantella is told the NPC knows " + healingHands.GetName())
            KeepTalking(conversation, npc)
            SayCue(conversation, "tcastspell@" + playerName + "+" + AsDetail(healingHands.GetName()), "Could you cast " + healingHands.GetName() + " on me?")
            Check(Heals(player), "castspell-tool", "CastSpell: the NPC casts " + healingHands.GetName() + " on you and you are healed")
            MantellaTalkTest.WaitForTurn(conversation)
            StopAction(npc, actionFaction)
            player.SetActorValue("HealRate", healRateWas)
            player.RestoreActorValue("Health", hurt)
        else
            Note("SKIP castspell-known Healing Hands isn't in Skyrim.esm")
            Note("SKIP castspell-tool Healing Hands isn't in Skyrim.esm")
        endIf

        KeepTalking(conversation, npc)
        SayCue(conversation, "tbrawl", "Fancy a fistfight?")
        Check(BecomesHostile(npc, player), "brawl-tool", "Brawl: the NPC starts a fistfight with you")
        MantellaTalkTest.WaitForTurn(conversation)
        KeepTalking(conversation, npc)
        SayCue(conversation, "tstanddown", "Alright, enough.")
        Check(StopsFighting(npc), "standdown-tool", "StandDown: the NPC stops fighting")
        MantellaTalkTest.WaitForTurn(conversation)
        StopFighting(npc)

        KeepTalking(conversation, npc)
        SayCue(conversation, "tattack@" + playerName, "You look ridiculous.")
        Check(BecomesHostile(npc, player), "attack-tool", "Attack: the NPC attacks you")
        MantellaTalkTest.WaitForTurn(conversation)
        KeepTalking(conversation, npc)
        SayCue(conversation, "tstanddown", "I'm sorry, I didn't mean it.")
        StopsFighting(npc)
        MantellaTalkTest.WaitForTurn(conversation)
        StopFighting(npc)

        ; ShareConversation: Ysolda remembers this conversation once it ends (checked by actions_ingame.py)
        KeepTalking(conversation, npc)
        SayCue(conversation, "tshare", "Tell Ysolda about this.")
        MantellaTalkTest.WaitForTurn(conversation)

        ; ReportCrime calls a guard nearby into the conversation, puts a bounty on you and answers back. AbsolveCrime takes the bounty
        ; off again. The inn has no guard, so a guard of the NPC's hold is placed next to you
        KeepTalking(conversation, npc)
        placedGuard = PlaceGuard(player, crimeFaction)
        SayCue(conversation, "treport", "Report me to the guards, I dare you.")
        if placedGuard
            Check(BountyRises(crimeFaction, bountyWas), "reportcrime-tool", "ReportCrime: " + placedGuard.GetDisplayName() + " joins and puts a bounty on you")
        else
            Note("SKIP reportcrime-tool no guard of " + npc.GetDisplayName() + "'s hold could be placed next to you")
        endIf
        MantellaTalkTest.WaitForTurn(conversation)
        Actor guard = conversation.GetFirstGuardActor()
        if !placedGuard
            Note("SKIP absolvecrime-tool no guard in the conversation to take the bounty off")
        elseIf !guard
            Note("FAIL absolvecrime-tool " + placedGuard.GetDisplayName() + " wasn't added to the conversation")
        elseIf crimeFaction.GetCrimeGold() <= bountyWas
            Note("SKIP absolvecrime-tool the bounty was already gone before AbsolveCrime (paid to the guard?)")
        else
            int bountyBefore = crimeFaction.GetCrimeGold()
            SayCue(conversation, "tabsolve", "Can we forget about that?")
            Check(BountyFalls(crimeFaction, bountyBefore), "absolvecrime-tool", "AbsolveCrime: the bounty is taken off again")
            MantellaTalkTest.WaitForTurn(conversation)
        endIf

        ; AddToConversation: someone nearby whom Mantella knows about is called over. The nearest to you of them, held still, so they
        ; are still among the people nearest to you that the game sends again with the line
        Actor joiner = FindJoiner(conversation, npc)
        if joiner
            joiner.SetDontMove(true)
            SayCue(conversation, "tadd@" + AsDetail(joiner.GetDisplayName()), "Ask " + joiner.GetDisplayName() + " to join us.")
            Check(JoinsConversation(conversation, joiner), "addtoconversation-tool", "AddToConversation: " + joiner.GetDisplayName() + " joins the conversation")
            joiner.SetDontMove(false)
            MantellaTalkTest.WaitForTurn(conversation)
        else
            Note("FAIL addtoconversation-tool nobody nearby who isn't in the conversation to call over")
        endIf
        Note("Emote isn't checked: a script can't see an animation play")
        MantellaEventTest.EndConversation(conversation)
    else
        Note("FAIL setup: the conversation with " + npc.GetDisplayName() + " didn't start. Is Mantella running with the test's settings?")
    endIf

    if npc.IsDead()
        Note(npc.GetDisplayName() + " died during the test")
    endIf
    ; Put back what the test changed
    StopAction(npc, actionFaction)
    StopFighting(npc)
    player.MoveTo(start)
    start.Delete()
    if IsFollowing(repository, npc)
        MantellaFollowerUtils.DismissFollower(npc, repository.gia_FollowerQst, repository.giafac_Following)
    endIf
    if crimeFaction && crimeFaction.GetCrimeGold() != bountyWas
        crimeFaction.ModCrimeGold(bountyWas - crimeFaction.GetCrimeGold())
        Note("your bounty is back to " + bountyWas)
    endIf
    if placedGuard
        placedGuard.Disable()
        placedGuard.Delete()
    endIf
    if healingHands && !knewHealingHands
        npc.RemoveSpell(healingHands)
    endIf
    player.SetActorValue("HealRate", healRateWas)
    SetSwitches(repository, aggroWas, followWas, inventoryWas)
    npc.SetActorValue("WaitingForPlayer", waitingWas)
    npc.EvaluatePackage()
    npc.GetActorBase().SetEssential(essentialWas)
    repository.microphoneEnabled = micWas
    Done()
EndFunction

; Other mods' actions (bat mtao, or bat mtaoa with Advanced Actions on): those of Actions For Mantella - Expanded Sex Actions. That mod's
; own script does them, so this checks what the game shows: the NPC's clothes come off and go back on (Undress, Redress), and OStim starts
; a scene (SexWithPlayer, GroupSexWithPlayer, SexWithNPC), seen by OStim's "ostim_thread_start", which MantellaListenerScript counts while
; this runs. Without Advanced Actions, the NPC starts its line with the action's name, and you also type just the name (Undress, Redress).
; A scene with you is ended with OStim's End key; the one between two NPCs ends by itself
Function RunOtherMods(MantellaRepository repository, MantellaConversation conversation, MantellaListenerScript listener, bool advanced) global
    if conversation.IsRunning()
        Stop("end the conversation first")
        return
    endIf
    Note("starting")
    string how = "line"
    string t = "" ; The stand-in picks the action as a model would for a cue starting with t
    if advanced
        how = "tool"
        t = "t"
        Note("other mods' actions, with Advanced Actions on")
    else
        Note("other mods' actions")
    endIf
    Utility.Wait(3.0) ; The place has just loaded
    Actor npc = FindNpc(repository, conversation)
    if !npc
        Note("FAIL setup: nobody to test with. It needs an NPC within 20 m who isn't a guard, a child or a follower")
        Done()
        return
    endIf
    Actor player = Game.GetPlayer()
    bool micWas = repository.microphoneEnabled
    bool followWas = player.IsInFaction(repository.giafac_AllowFollower)
    repository.microphoneEnabled = false ; The test types the player's lines
    SetFaction(repository.giafac_AllowFollower, true) ; The menu's Allow Follow, for Follow
    ; OStim's settings for the test, put back at the end: no menu to pick furniture or to add people nearby (nobody would answer it), the
    ; scene where everyone stands (no walking to a bed first), and scenes between NPCs of 15 seconds instead of 5 minutes, so the next can start
    float selectFurnitureWas = SetOStimSetting(0x000DA7, 0.0) ; OStimSelectFurniture
    float addActorsWas = SetOStimSetting(0x000E45, 0.0) ; OStimAddActorsAtStart
    float useFurnitureWas = SetOStimSetting(0x000DA6, 0.0) ; OStimUseFurniture
    float npcSceneLengthWas = SetOStimSetting(0x000E2F, 15000.0) ; OStimNPCSceneDuration, in milliseconds
    listener.WatchOStimScenes(true)

    if Start(conversation, npc)
        if !WearsClothes(npc)
            Note("SKIP undress-" + how + " " + npc.GetDisplayName() + " wears nothing on the body to take off")
            Note("SKIP redress-" + how + " " + npc.GetDisplayName() + " wears nothing on the body to take off")
            if !advanced
                Note("SKIP undress-typed " + npc.GetDisplayName() + " wears nothing on the body to take off")
                Note("SKIP redress-typed " + npc.GetDisplayName() + " wears nothing on the body to take off")
            endIf
        else
            UndressAndRedress(conversation, npc, "ACTIONTEST_" + t + "undress Take your clothes off.", "ACTIONTEST_" + t + "redress Get dressed again.", how, "")
            if !advanced
                UndressAndRedress(conversation, npc, "Undress", "Redress", "typed", "typing ")
            endIf
        endIf

        ; The mod also does something on Mantella's own Unfollow (sent with its details, so with Advanced Actions on): it stops Mantella's
        ; follower quest. The NPC must stop following, and be able to follow you again after
        SayCue(conversation, t + "follow", "Come with me.")
        Check(BecomesFollower(repository, npc), "follow-" + how, "Follow: the NPC follows you")
        MantellaTalkTest.WaitForTurn(conversation)
        SayCue(conversation, t + "unfollow", "You can stop following me now.")
        Check(StopsFollowing(repository, npc), "unfollow-" + how, "Unfollow: the NPC stops following you")
        MantellaTalkTest.WaitForTurn(conversation)
        SayCue(conversation, t + "follow", "Actually, come with me after all.")
        Check(BecomesFollower(repository, npc), "follow-again-" + how, "Follow after Unfollow: the NPC follows you again")
        MantellaTalkTest.WaitForTurn(conversation)
        SayCue(conversation, t + "unfollow", "No, stay here.")
        Check(StopsFollowing(repository, npc), "unfollow-again-" + how, "Unfollow again: the NPC stops following you again")
        MantellaTalkTest.WaitForTurn(conversation)

        SceneWithPlayer(conversation, listener, npc, None, "ACTIONTEST_" + t + "sexplayer Let's go to bed together.", "sexwithplayer-" + how, "SexWithPlayer: OStim starts a scene with you")
        if !advanced
            SceneWithPlayer(conversation, listener, npc, None, "SexWithPlayer", "sexwithplayer-typed", "typing SexWithPlayer: OStim starts a scene with you")
        endIf
        MantellaEventTest.EndConversation(conversation)

        ; The scenes for several NPCs need a group conversation with someone else nearby
        Actor other = FindSecondNpc(repository, conversation, npc)
        if !other
            NoteGroupFailed(how, advanced, "nobody else nearby for a group conversation")
        elseIf StartGroup(conversation, npc, other)
            ; Each line names only the NPC, who then answers first. Should the other one answer too, the same action is already done
            ; (both are in the scene, so OStim starts no second one), or a second scene with you starts, which is ended too
            string both = npc.GetDisplayName() + " and " + other.GetDisplayName()
            string groupCue = "ACTIONTEST_" + t + "groupsex@" + AsDetail(npc.GetDisplayName()) + "+" + AsDetail(other.GetDisplayName())
            SceneWithPlayer(conversation, listener, npc, other, groupCue + " " + npc.GetDisplayName() + ", let's all go to bed together.", "groupsexwithplayer-" + how, "GroupSexWithPlayer: OStim starts a scene with you, " + both)
            if !advanced
                ; Typed: the NPC who joined last does it, with everyone in the conversation
                SceneWithPlayer(conversation, listener, npc, other, "GroupSexWithPlayer", "groupsexwithplayer-typed", "typing GroupSexWithPlayer: OStim starts a scene with you, " + both)
                ; Typed: the NPC who joined last does it, with the only other NPC
                SceneOfNpcs(conversation, listener, npc, other, "SexWithNPC", "sexwithnpc-typed", "typing SexWithNPC: OStim starts a scene with " + both)
            endIf
            ; Who it is with: the only other NPC in the conversation for the line, the one named after the cue for the model
            SceneOfNpcs(conversation, listener, npc, other, "ACTIONTEST_" + t + "sexnpc@" + AsDetail(other.GetDisplayName()) + " " + npc.GetDisplayName() + ", why don't you take your friend here to bed?", "sexwithnpc-" + how, "SexWithNPC: OStim starts a scene with " + both)
            MantellaEventTest.EndConversation(conversation)
        else
            NoteGroupFailed(how, advanced, "the group conversation with " + npc.GetDisplayName() + " and " + other.GetDisplayName() + " didn't start")
        endIf
    else
        Note("FAIL setup: the conversation with " + npc.GetDisplayName() + " didn't start. Is Mantella running with the test's settings?")
    endIf

    ; Put back what the test changed
    listener.WatchOStimScenes(false)
    PutOStimSettingBack(0x000DA7, selectFurnitureWas)
    PutOStimSettingBack(0x000E45, addActorsWas)
    PutOStimSettingBack(0x000DA6, useFurnitureWas)
    PutOStimSettingBack(0x000E2F, npcSceneLengthWas)
    if IsFollowing(repository, npc)
        MantellaFollowerUtils.DismissFollower(npc, repository.gia_FollowerQst, repository.giafac_Following)
    endIf
    SetFaction(repository.giafac_AllowFollower, followWas)
    repository.microphoneEnabled = micWas
    Done()
EndFunction

; Says the line (a cue, or just an action's name), checks that OStim starts a scene with you, and ends it with OStim's End key. Once the
; NPCs are done answering, ends one more that started after the first ended (the other NPC did the same)
Function SceneWithPlayer(MantellaConversation conversation, MantellaListenerScript listener, Actor npc, Actor other, string line, string id, string text) global
    KeepTalkingWith(conversation, npc, other)
    int started = listener.OStimScenesStarted
    int ended = listener.OStimScenesEnded
    Say(conversation, line)
    Check(SceneStarts(listener, started), id, text)
    EndPlayerScene(listener, ended)
    KeepTalkingWith(conversation, npc, other)
    MantellaTalkTest.WaitForTurn(conversation)
    EndPlayerScene(listener, listener.OStimScenesEnded)
EndFunction

; Says the line, checks that OStim starts a scene between the two NPCs, and waits for it to end (shortened for the test)
Function SceneOfNpcs(MantellaConversation conversation, MantellaListenerScript listener, Actor npc, Actor other, string line, string id, string text) global
    KeepTalkingWith(conversation, npc, other)
    int started = listener.OStimScenesStarted
    int ended = listener.OStimScenesEnded
    Say(conversation, line)
    bool ok = SceneStarts(listener, started)
    Check(ok, id, text)
    MantellaTalkTest.WaitForTurn(conversation)
    if ok && !SceneEnds(listener, ended, 60.0)
        Note("the scene between the NPCs didn't end within a minute")
    endIf
EndFunction

; Undress, then Redress. Redress can only be checked once the clothes came off: otherwise it would pass without doing anything
Function UndressAndRedress(MantellaConversation conversation, Actor npc, string undressLine, string redressLine, string how, string typing) global
    Say(conversation, undressLine)
    bool undressed = ClothesBecome(npc, false)
    Check(undressed, "undress-" + how, typing + "Undress: the NPC takes their clothes off")
    MantellaTalkTest.WaitForTurn(conversation)
    if !undressed
        Note("SKIP redress-" + how + " the clothes never came off, so putting them back on can't be checked")
        return
    endIf
    Say(conversation, redressLine)
    Check(ClothesBecome(npc, true), "redress-" + how, typing + "Redress: the NPC puts their clothes back on")
    MantellaTalkTest.WaitForTurn(conversation)
EndFunction

; A scene can end the conversation: it starts again, with both NPCs when other is given
Function KeepTalkingWith(MantellaConversation conversation, Actor npc, Actor other) global
    if conversation.IsRunning()
        return
    endIf
    if other
        StartGroup(conversation, npc, other)
    else
        Start(conversation, npc)
    endIf
EndFunction

; Sets one of OStim's settings (a global of OStim.esp) and returns what it was, or -1 without OStim
float Function SetOStimSetting(int formId, float value) global
    GlobalVariable setting = Game.GetFormFromFile(formId, "OStim.esp") as GlobalVariable
    if !setting
        return -1.0
    endIf
    float was = setting.GetValue()
    setting.SetValue(value)
    return was
EndFunction

Function PutOStimSettingBack(int formId, float was) global
    GlobalVariable setting = Game.GetFormFromFile(formId, "OStim.esp") as GlobalVariable
    if setting && was >= 0.0
        setting.SetValue(was)
    endIf
EndFunction

Function NoteGroupFailed(string how, bool advanced, string reason) global
    Note("FAIL groupsexwithplayer-" + how + " " + reason)
    Note("FAIL sexwithnpc-" + how + " " + reason)
    if !advanced
        Note("FAIL groupsexwithplayer-typed " + reason)
        Note("FAIL sexwithnpc-typed " + reason)
    endIf
EndFunction

; Whether a scene ends after the endedBefore ones within the seconds
bool Function SceneEnds(MantellaListenerScript listener, int endedBefore, float seconds) global
    float waited = 0.0
    while listener.OStimScenesEnded <= endedBefore && waited < seconds
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return listener.OStimScenesEnded > endedBefore
EndFunction

; Whether something is worn on the body slot (32): clothes or armor
bool Function WearsClothes(Actor npc) global
    return npc.GetWornForm(0x00000004) != None
EndFunction

bool Function ClothesBecome(Actor npc, bool worn) global
    float waited = 0.0
    while WearsClothes(npc) != worn && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return WearsClothes(npc) == worn
EndFunction

; Whether OStim starts a scene after the startedBefore ones
bool Function SceneStarts(MantellaListenerScript listener, int startedBefore) global
    float waited = 0.0
    while listener.OStimScenesStarted <= startedBefore && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return listener.OStimScenesStarted > startedBefore
EndFunction

; Presses OStim's End key (its setting OStimKeyEnd) until a scene ends after the endedBefore ones. Nothing to end if none started
Function EndPlayerScene(MantellaListenerScript listener, int endedBefore) global
    if listener.OStimScenesStarted <= listener.OStimScenesEnded
        return
    endIf
    GlobalVariable endKey = Game.GetFormFromFile(0x000E2D, "OStim.esp") as GlobalVariable ; OStimKeyEnd
    float waited = 0.0
    while listener.OStimScenesEnded <= endedBefore && waited < TIMEOUT()
        if endKey && endKey.GetValueInt() > 0
            Input.TapKey(endKey.GetValueInt())
        endIf
        Utility.Wait(2.0)
        waited += 2.0
    endWhile
    if listener.OStimScenesEnded <= endedBefore
        Note("the scene with you didn't end: end it yourself")
    endIf
EndFunction

; Someone else nearby for the group conversation: not a guard, a child or a follower
Actor Function FindSecondNpc(MantellaRepository repository, MantellaConversation conversation, Actor npc) global
    Actor[] people = MantellaShout.FindNearbyWith(repository, conversation, 20.0, false, false, 10)
    int i = 0
    while i < people.Length
        Actor person = people[i]
        if person && person != npc && !person.IsGuard() && !person.IsChild() && !IsFollowing(repository, person)
            return person
        endIf
        i += 1
    endWhile
    return None
EndFunction

bool Function StartGroup(MantellaConversation conversation, Actor npc, Actor other) global
    Actor[] actors = new Actor[3]
    actors[0] = Game.GetPlayer()
    actors[1] = npc
    actors[2] = other
    if !MantellaEventTest.StartConversation(conversation, actors, true)
        return false
    endIf
    MantellaTalkTest.WaitForTurn(conversation)
    return conversation.IsRunning()
EndFunction

; A name or spell as a detail in a cue: one word, with _ for a space
string Function AsDetail(string text) global
    string result = ""
    int i = 0
    while i < StringUtil.GetLength(text)
        string letter = StringUtil.GetNthChar(text, i)
        if letter == " "
            result += "_"
        else
            result += letter
        endIf
        i += 1
    endWhile
    return result
EndFunction

; Someone among the people nearby that Mantella is told about, who isn't in the conversation: AddToConversation can only call them over
Actor Function FindJoiner(MantellaConversation conversation, Actor npc) global
    Actor[] nearby = conversation.GetCachedNearbyActors()
    int i = 0
    while nearby && i < nearby.Length
        Actor person = nearby[i]
        if person && person != npc && person != Game.GetPlayer() && !conversation.Participants.HasForm(person) && !person.IsGuard()
            return person
        endIf
        i += 1
    endWhile
    return None
EndFunction

bool Function JoinsConversation(MantellaConversation conversation, Actor person) global
    float waited = 0.0
    while !conversation.Participants.HasForm(person) && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return conversation.Participants.HasForm(person)
EndFunction

; CastSpell: your health goes up. It doesn't come back by itself during the test, so only the spell does that
bool Function Heals(Actor player) global
    float health = player.GetActorValue("Health")
    float waited = 0.0
    while waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
        if player.GetActorValue("Health") > health + 1.0
            return true
        endIf
    endWhile
    Note("your health didn't go up")
    return false
EndFunction

; A guard of the NPC's hold (only Whiterun's for now: the test runs in the Bannered Mare), placed next to you so they are the nearest of
; the people nearby the game tells Mantella about, which ReportCrime picks its guard from. None if the NPC isn't of Whiterun's hold
Actor Function PlaceGuard(Actor player, Faction crimeFaction) global
    ActorBase guardBase = Game.GetFormFromFile(0x099CE5, "Skyrim.esm") as ActorBase ; GuardWhiterunCityGeneric
    if !guardBase || !crimeFaction
        return None
    endIf
    Actor guard = player.PlaceActorAtMe(guardBase)
    Utility.Wait(2.0) ; The guard is set up and stands
    if !guard.IsGuard() || guard.GetCrimeFaction() != crimeFaction
        guard.Disable()
        guard.Delete()
        return None
    endIf
    Note(guard.GetDisplayName() + " now stands next to you")
    return guard
EndFunction

bool Function BountyRises(Faction crimeFaction, int bountyWas) global
    float waited = 0.0
    while crimeFaction.GetCrimeGold() <= bountyWas && waited < TIMEOUT()
        Utility.Wait(0.25)
        waited += 0.25
    endWhile
    return crimeFaction.GetCrimeGold() > bountyWas
EndFunction

bool Function BountyFalls(Faction crimeFaction, int bountyBefore) global
    float waited = 0.0
    while crimeFaction.GetCrimeGold() >= bountyBefore && waited < TIMEOUT()
        Utility.Wait(0.25)
        waited += 0.25
    endWhile
    return crimeFaction.GetCrimeGold() < bountyBefore
EndFunction

bool Function LeavesRank(Actor npc, Faction actionFaction, int rank) global
    float waited = 0.0
    while npc.GetFactionRank(actionFaction) == rank && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    return npc.GetFactionRank(actionFaction) != rank
EndFunction

int Function TRAVELING() global ; TravelTo
    return 2
EndFunction

int Function LEADING() global ; LeadTo
    return 5
EndFunction

int Function CASTING() global ; CastSpell on someone else
    return 6
EndFunction

int Function COLLECTING() global ; CollectIngredients
    return 7
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

; Teleport: the NPC ends up next to you, from where they stood 3 m or more away. They are held still from before the line until the check
; ends, so they can't walk over (or back again): only Teleport moves them. Where they stood is taken before the line, because the game
; can teleport them before the line is even sent
float[] Function HoldStill(MantellaConversation conversation, Actor npc) global
    MantellaTalkTest.WaitForTurn(conversation)
    float[] stood = new float[2]
    stood[0] = npc.GetPositionX()
    stood[1] = npc.GetPositionY()
    npc.SetDontMove(true)
    return stood
EndFunction

bool Function Teleports(Actor npc, Actor player, float[] stood) global
    float x = stood[0]
    float y = stood[1]
    bool teleported = false
    float moved = 0.0
    float waited = 0.0
    while !teleported && waited < TIMEOUT()
        Utility.Wait(0.25)
        waited += 0.25
        moved = Math.Sqrt((npc.GetPositionX() - x) * (npc.GetPositionX() - x) + (npc.GetPositionY() - y) * (npc.GetPositionY() - y))
        teleported = npc.GetDistance(player) < NEXT_TO() && moved > 210.0
    endWhile
    npc.SetDontMove(false)
    if !teleported
        Note(npc.GetDisplayName() + " didn't appear next to you: " + Meters(npc.GetDistance(player)) + " away, " + Meters(moved) + " from where they stood")
    endIf
    return teleported
EndFunction

; The NPC is made essential for the test (knocked down instead of killed), as others nearby may join the fights: followers, guards,
; other mods' NPCs. Returns whether they were essential already, to put back at the end
bool Function KeepAlive(Actor npc) global
    ActorBase base = npc.GetActorBase()
    bool essentialWas = base.IsEssential()
    base.SetEssential(true)
    return essentialWas
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
