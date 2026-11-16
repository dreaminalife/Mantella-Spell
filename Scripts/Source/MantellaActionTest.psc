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
