Scriptname MantellaHeardLinesTest Hidden
{In-game test of Vanilla Dialogues (the MantellaHeardLines plugin). Plays one of Skyrim's own scenes (Vignar Gray-Mane and Olfrid
Battle-Born arguing) in the Bannered Mare under different settings, with people placed near and far, and hands the caught lines to
MantellaSoftware with the same requests the add-on always sends. Started from the console by the batch files that
tests/ingame/heard_lines/heard_lines_ingame.py in the Mantella repository writes. That script then checks what the game sent (Mantella's
log) and what Mantella kept (each NPC's heard_lines.json). See FEATURES_README.md there, Vanilla Dialogues, "For developers".
Run 1: the scene under each setting. Run 2, after loading a save made while lines were waiting: those lines, then the player's own
dialogue-menu talk. Run 3, after loading the save made before the test: an older save. The test doesn't put anything back: loading the
save from before it (run 3) does}

; The Skyrim.esm forms the test uses. heard_lines_ingame.py checks the results by the same ids
int Function FEUD_SCENE() global ; WhiterunFeudScene1: Vignar and Olfrid argue, 4 lines. Its quest, DialogueWhiterun, always runs
    return 0x000E3DE3
EndFunction
int Function VIGNAR() global ; Speaks in the scene
    return 0x0001A6A1
EndFunction
int Function OLFRID() global ; Speaks in the scene
    return 0x0001A687
EndFunction
int Function HULDA() global ; Near the speakers: hears everything. Also the NPC the lines are handed over with
    return 0x0001A66E
EndFunction
int Function MIKAEL() global ; In the kitchen, far away: hears nothing, except during his conversation with the player (part 4)
    return 0x0001A671
EndFunction
int Function BRENUIN() global ; Near the speakers but disabled: hears nothing
    return 0x0002C90F
EndFunction
int Function CHICKEN() global ; EncChicken: placed near the speakers and killed, so it hears nothing
    return 0x000A91A0
EndFunction
int Function NEAR_SPOT() global ; Where NPCs sweep the open floor north of the hearth (7 m from its fire), where the speakers and the near people stand
    return 0x000DDDCB
EndFunction
int Function FAR_SPOT() global ; A chair in the kitchen, about 21 m from the near spot
    return 0x00061700
EndFunction
float Function HEARING_METERS() global ; Hearing Distance during the test: the near people stand within 2 m, the far ones over 20 m away
    return 5.0
EndFunction
float Function TIMEOUT() global ; Seconds to wait for a scene or a reply
    return 120.0
EndFunction
float Function PLAYER_TIMEOUT() global ; Seconds to wait for what the player does
    return 300.0
EndFunction

Function Run(int testRun, MantellaRepository repository, MantellaConversation conversation) global
    if testRun == 1
        repository.heardLinesTestOnLoad = 0 ; bat mhl set it for its save (mhl_before) only. A save made later must not go on with the test
    endIf
    if !repository.IsHeardLinesInstalled()
        Stop("the MantellaHeardLines plugin isn't loaded")
        return
    endIf
    if conversation.IsRunning()
        Stop("end the conversation first")
        return
    endIf
    if testRun == 1
        RunScenes(repository, conversation)
    elseIf testRun == 2
        RunAfterWaitingSave(repository, conversation)
    else
        RunAfterOlderSave(conversation)
    endIf
EndFunction

; Run 1: the scene under each setting, each time handed over with its own request
Function RunScenes(MantellaRepository repository, MantellaConversation conversation) global
    Note("starting")
    Utility.Wait(3.0) ; The place has just loaded
    ; Every line the test catches is then clearly later than the save bat mhl made before it. Run 3 loads that save, and the first
    ; request after it must tell a time before all of them, also after the few seconds run 3 takes
    PassAnHour()
    Scene feud = Game.GetFormFromFile(FEUD_SCENE(), "Skyrim.esm") as Scene
    Actor vignar = GetActor(VIGNAR())
    Actor olfrid = GetActor(OLFRID())
    Actor hulda = GetActor(HULDA())
    Actor mikael = GetActor(MIKAEL())
    Actor brenuin = GetActor(BRENUIN())
    ObjectReference nearSpot = Game.GetFormFromFile(NEAR_SPOT(), "Skyrim.esm") as ObjectReference
    ObjectReference farSpot = Game.GetFormFromFile(FAR_SPOT(), "Skyrim.esm") as ObjectReference
    string missing = Missing(vignar, "Vignar Gray-Mane") + Missing(olfrid, "Olfrid Battle-Born") + Missing(hulda, "Hulda") + Missing(mikael, "Mikael")
    if !feud || !nearSpot || !farSpot
        missing += "the scene or the Bannered Mare (is Skyrim.esm changed?), "
    endIf
    if missing != ""
        Stop("can't run, missing: " + missing)
        return
    endIf
    bool useBrenuin = Missing(brenuin, "Brenuin") == ""
    if !useBrenuin
        Note("Brenuin isn't alive in this save, so the disabled person is left out")
    endIf
    ; Nothing else sends requests meanwhile, so each request the test sends carries one part's lines
    repository.radiantEnabled = false
    repository.npcInitiativeEnabled = false
    repository.npcEventEnabled = false
    SetHearing(repository, true, 200)

    Actor player = Game.GetPlayer()
    PlaceTogether(vignar, olfrid, hulda, nearSpot)
    Place(mikael, farSpot, 0.0, 0.0)
    Actor chicken = player.PlaceActorAtMe(Game.GetFormFromFile(CHICKEN(), "Skyrim.esm") as ActorBase)
    if chicken
        chicken.MoveTo(nearSpot, -40.0, -70.0, 0.0)
        chicken.Kill()
    endIf
    if useBrenuin
        Place(brenuin, nearSpot, -40.0, 70.0)
        brenuin.Disable()
    endIf
    Utility.Wait(3.0)
    HandOver(conversation, hulda, "lines from before the test")

    ; 1. Everyone near hears it, and the player was there. Not Mikael (far), Brenuin (disabled) or the chicken (dead)
    PlayScene(feud, "1, everyone near")
    HandOver(conversation, hulda, "part 1")
    if chicken
        chicken.Delete()
    endIf
    if useBrenuin
        brenuin.Enable()
        brenuin.SetDontMove(false)
        brenuin.MoveToMyEditorLocation()
    endIf

    ; 2. Nearby NPCs Overhear off, and the player far away: only the two speakers keep it, and the player wasn't there
    SetHearing(repository, false, 200)
    PlaceTogether(vignar, olfrid, hulda, nearSpot) ; People wander off after a while although told to stay, so before each scene they are placed again
    player.MoveTo(farSpot, 100.0, 0.0, 0.0)
    PlayScene(feud, "2, Nearby NPCs Overhear off, player away")
    player.MoveTo(nearSpot, PLAYER_X(), 0.0, 0.0)
    Utility.Wait(2.0)
    HandOver(conversation, hulda, "part 2")

    ; 3. Vanilla Dialogues off, the way the wheel and the MCM turn it off: nothing is caught
    SetHearing(repository, true, 200)
    repository.SetVanillaDialogues(false)
    PlayScene(feud, "3, Vanilla Dialogues off")
    HandOver(conversation, hulda, "part 3")
    repository.SetVanillaDialogues(true)

    ; 4. During the player's conversation with Mikael: the scene goes into the conversation, and he keeps it when it ends.
    ; His own Mantella lines are never caught
    Place(mikael, nearSpot, -40.0, -70.0) ; Where the chicken lay
    Actor[] actors = new Actor[2]
    actors[0] = player
    actors[1] = mikael
    if MantellaEventTest.StartConversation(conversation, actors, false)
        MantellaTalkTest.WaitForTurn(conversation)
        PlaceTogether(vignar, olfrid, hulda, nearSpot)
        Place(mikael, nearSpot, -40.0, -70.0)
        PlayScene(feud, "4, during a conversation")
        MantellaTalkTest.Say(conversation, "Mikael, did you hear what those two were arguing about just now?")
        MantellaTalkTest.WaitForTurn(conversation)
    else
        Note("the conversation with Mikael didn't start")
    endIf
    MantellaEventTest.EndConversation(conversation)
    Place(mikael, farSpot, 0.0, 0.0)

    ; 5. Lines still waiting when the game is saved stay in the save. At most 2 may wait, so the first 2 of the 4 are dropped
    SetHearing(repository, true, 2)
    PlaceTogether(vignar, olfrid, hulda, nearSpot)
    PlayScene(feud, "5, left waiting for the save")
    ; Off before the save, so after loading it nothing new is caught before run 2 hands the 2 waiting lines over: with at most 2 waiting,
    ; any new line would push one of them out
    repository.SetVanillaDialogues(false)
    repository.heardLinesTestOnLoad = 2 ; Loading the save bat mhl2 makes goes on with run 2
    Stop("run 1 done. Now type in the console: bat mhl2 (saves and loads the game). If the game doesn't load, load the save mhl_waiting")
EndFunction

; Run 2, after loading the save made in bat mhl2: the waiting lines, then dialogue-menu talk the player does
Function RunAfterWaitingSave(MantellaRepository repository, MantellaConversation conversation) global
    Note("run 2 starting")
    Utility.Wait(5.0) ; The save has just loaded
    Actor vignar = GetActor(VIGNAR())
    Actor olfrid = GetActor(OLFRID())
    Actor hulda = GetActor(HULDA())
    HandOver(conversation, hulda, "lines kept in the save")
    ; A save doesn't keep that people must stay put, so they may have walked off since the load
    ObjectReference nearSpot = Game.GetFormFromFile(NEAR_SPOT(), "Skyrim.esm") as ObjectReference
    if nearSpot
        PlaceTogether(vignar, olfrid, hulda, nearSpot)
    endIf
    SetHearing(repository, true, 200)

    ; 6. Menu talk: an answer is kept with the player's question. A line in Lines That Only Open a Menu, and Mantella's own line, are not
    Debug.MessageBox("Heard lines test: Hulda, Vignar and Olfrid stand next to you. Talk to Hulda the normal way. Ask her one question, such as about rumors. Then ask to rent a room. Then pick \"I want to speak with you. (Start Mantella conversation)\". The test ends that conversation itself")
    if WaitForConversation(conversation)
        MantellaEventTest.EndConversation(conversation)
    else
        Note("no Mantella conversation started, going on")
    endIf
    Debug.MessageBox("Heard lines test: now talk to Vignar Gray-Mane the normal way, and leave at once without picking anything. His greeting is never kept")
    if WaitForMenu(true) && WaitForMenu(false)
        Utility.Wait(3.0)
    else
        Note("Vignar's dialogue wasn't opened and closed, going on")
    endIf
    HandOver(conversation, hulda, "menu talk")
    Stop("run 2 done. Press Enter in the window of heard_lines_ingame.py. Once it has checked, type in the console: bat mhl3 (loads the save from before the test)")
EndFunction

; Run 3, after loading the save from before the test (bat mhl3): the next request tells Mantella an older save was loaded
Function RunAfterOlderSave(MantellaConversation conversation) global
    Note("run 3 starting")
    Utility.Wait(5.0) ; The save has just loaded
    Actor hulda = GetActor(HULDA())
    Game.GetPlayer().MoveTo(hulda)
    Utility.Wait(5.0)
    HandOver(conversation, hulda, "after loading the older save")
    Stop("done. Press Enter in the window of heard_lines_ingame.py. Then load your own save")
EndFunction

; Vanilla Dialogues, Nearby NPCs Overhear, the test's Hearing Distance and the most lines the plugin keeps waiting, sent to the plugin
Function SetHearing(MantellaRepository repository, bool nearbyOverhear, int mostWaiting) global
    repository.enableVanillaDialogueAwareness = true
    repository.vanillaDialogueNearbyOverhear = nearbyOverhear
    repository.vanillaDialogueHearingDistance = HEARING_METERS()
    repository.heardLinesMostWaiting = mostWaiting
    repository.SendHeardLinesSettings()
EndFunction

; A start request carries the waiting lines, as it always does. The conversation is ended at once
Function HandOver(MantellaConversation conversation, Actor npc, string label) global
    Note("handing the lines over: " + label)
    Actor[] actors = new Actor[2]
    actors[0] = Game.GetPlayer()
    actors[1] = npc
    MantellaEventTest.StartConversation(conversation, actors, false)
    MantellaEventTest.EndConversation(conversation)
    Utility.Wait(2.0)
EndFunction

; Plays the scene and waits until it ends, and then a moment longer: who heard the last line is worked out on the game's next frame
Function PlayScene(Scene feud, string label) global
    Note("scene " + label)
    feud.ForceStart()
    float waited = 0.0
    while !feud.IsPlaying() && waited < 10.0
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    if !feud.IsPlaying()
        Note("the scene didn't start (" + label + ")")
        return
    endIf
    waited = 0.0
    while feud.IsPlaying() && waited < TIMEOUT()
        Utility.Wait(0.5)
        waited += 0.5
    endWhile
    Utility.Wait(2.0)
EndFunction

; An hour of game time passes in a few seconds, the way the game's own clock runs, so the day and the hour stay in step
Function PassAnHour() global
    GlobalVariable timeScale = Game.GetFormFromFile(0x0000003A, "Skyrim.esm") as GlobalVariable ; TimeScale: game seconds per real second
    if !timeScale
        Note("can't move the clock on, so run 3 may fail")
        return
    endIf
    float normal = timeScale.GetValue()
    timeScale.SetValue(1200.0)
    Utility.Wait(3.0)
    timeScale.SetValue(normal)
EndFunction

; The player's place at the near spot: about 1 to 2 m from the speakers and Hulda
float Function PLAYER_X() global
    return -120.0
EndFunction

; The two speakers and Hulda together at the near spot, kept there, and the player a step away
Function PlaceTogether(Actor vignar, Actor olfrid, Actor hulda, ObjectReference nearSpot) global
    Place(vignar, nearSpot, 40.0, 40.0)
    Place(olfrid, nearSpot, 40.0, -40.0)
    Place(hulda, nearSpot, -40.0, 0.0)
    Game.GetPlayer().MoveTo(nearSpot, PLAYER_X(), 0.0, 0.0)
EndFunction

; Puts the person next to the spot and keeps them there
Function Place(Actor person, ObjectReference spot, float x, float y) global
    person.MoveTo(spot, x, y, 0.0)
    person.SetDontMove(true)
EndFunction

; Until a Mantella conversation started and MantellaSoftware said the start is done. False if none started in time. Not until the player's
; turn: started from the dialogue menu, the turn was once not seen at all, and the conversation then ran until the wait gave up
bool Function WaitForConversation(MantellaConversation conversation) global
    float waited = 0.0
    while !conversation.IsRunning() && waited < PLAYER_TIMEOUT()
        Utility.WaitMenuMode(0.5) ; Counts in the dialogue menu too
        waited += 0.5
    endWhile
    if !conversation.IsRunning()
        return false
    endIf
    waited = 0.0
    while conversation.IsRunning() && conversation.IsEnding() && waited < TIMEOUT() ; IsEnding stays true until the start is done
        Utility.WaitMenuMode(0.5)
        waited += 0.5
    endWhile
    Utility.WaitMenuMode(1.0) ; Its first request, which carries the lines caught meanwhile, has gone out
    return conversation.IsRunning()
EndFunction

; Until the dialogue menu is open, or closed. False if it didn't happen in time
bool Function WaitForMenu(bool open) global
    float waited = 0.0
    while UI.IsMenuOpen("Dialogue Menu") != open && waited < PLAYER_TIMEOUT()
        Utility.WaitMenuMode(0.5)
        waited += 0.5
    endWhile
    return UI.IsMenuOpen("Dialogue Menu") == open
EndFunction

Actor Function GetActor(int formId) global
    return Game.GetFormFromFile(formId, "Skyrim.esm") as Actor
EndFunction

; The name and a comma when the person isn't there to use: gone from the save, dead or disabled
string Function Missing(Actor person, string name) global
    if !person || person.IsDead() || person.IsDisabled()
        return name + ", "
    endIf
    return ""
EndFunction

; A last note that stays on screen until closed
Function Stop(string text) global
    Note(text)
    Debug.MessageBox("Heard lines test: " + text)
EndFunction

; On screen, and in the Papyrus log (Papyrus.0.log) when Papyrus logging is on
Function Note(string text) global
    Debug.Notification("Heard lines test: " + text)
    Debug.Trace("Heard lines test: " + text)
EndFunction
