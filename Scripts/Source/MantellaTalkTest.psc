Scriptname MantellaTalkTest Hidden
{In-game test of the talk settings (Conversation page in MantellaSoftware): a group conversation, a Conversation Event, a Shout and a watched
NPC Event, with the player's lines said by the test itself. It runs twice, the second time with Director Mode on in MantellaSoftware. Started from the console by the batch file that tests/ingame/talk_settings/talk_settings_ingame.py in
the Mantella repository writes, after it put the test's talk settings in config.ini. That script then checks Mantella's log (its "Turn state"
lines). See docs/conversation_wheel.md there, "Automated tests"}

float Function TIMEOUT() global ; Seconds to wait for each step, or without a new NPC line while waiting for the player's turn
    return 120.0
EndFunction

Function Run(MantellaRepository repository, MantellaConversation conversation, MantellaListenerScript listener) global
    if conversation.IsRunning()
        Note("end the conversation first")
        return
    endIf
    Note("starting")
    Utility.Wait(3.0) ; The place has just loaded
    Actor[] people = MantellaShout.FindNearbyWith(repository, conversation, 20.0, false, false, 10)
    if people.Length < 3
        Note("it needs at least 3 people within 20 m, found " + people.Length)
        return
    endIf
    Actor player = Game.GetPlayer()

    ; 1. A group conversation with two NPCs, not shouting (the shared settings): the line is said to both, who answer each in turn.
    ; In the Director Mode run (MantellaSoftware's setting), the line is a direction, and Director Mode's own settings apply
    Actor[] actors = new Actor[3]
    actors[0] = player
    actors[1] = people[0]
    actors[2] = people[1]
    if MantellaEventTest.StartConversation(conversation, actors, true)
        WaitForTurn(conversation)
        Say(conversation, people[0].GetDisplayName() + " and " + people[1].GetDisplayName() + ", what do you both make of the weather today?")
        WaitForTurn(conversation)

        ; 2. A Conversation Event (its own settings and its own Max NPC Turns, also in Director Mode), picked as on the wheel
        MantellaEventTest.RunEvent(conversation, "conversation", false)
        WaitForTurn(conversation)

        ; 3. Shout (its own settings): the line is said to someone nearby, who joins and answers
        Note("Shout")
        conversation.SetShout(true)
        Say(conversation, people[2].GetDisplayName() + ", come over here. What do you think of these two?")
        WaitForTurn(conversation)
        MantellaEventTest.EndConversation(conversation)
    endIf

    ; 4. A watched NPC Event (its own settings): the player watches until the scene ends
    string reason = listener.TryNpcEventCheck(true)
    if reason != ""
        Note("NPC Event: " + reason)
    elseIf MantellaEventTest.WaitForNpcEvent(conversation)
        Note("watching the NPC Event until it ends")
        float waited = 0.0
        while conversation.IsRunning() && waited < TIMEOUT() * 3
            Utility.Wait(1.0)
            waited += 1.0
        endWhile
    else
        Note("no NPC Event this time. Run the test again for this part")
    endIf
    Note("done. Now run the check")
EndFunction

; Until it is the player's turn (in Director Mode: when the player can direct again). As long as NPC lines keep arriving, it keeps waiting:
; a slow model, or Director Mode, where the NPCs reply up to Max NPC Turns per Direction and the extra rounds. It gives up after TIMEOUT()
; seconds without a new line, so the test goes on if a reply never comes
Function WaitForTurn(MantellaConversation conversation) global
    int lines = conversation.NpcLinesReceived()
    float quiet = 0.0
    while conversation.IsRunning() && !conversation.IsPlayersTurn() && quiet < TIMEOUT()
        Utility.Wait(0.5)
        quiet += 0.5
        if conversation.NpcLinesReceived() != lines
            lines = conversation.NpcLinesReceived()
            quiet = 0.0
        endIf
    endWhile
    if quiet >= TIMEOUT()
        Note("no new line for " + (TIMEOUT() as int) + " seconds, going on")
    endIf
EndFunction

; Says the line as if typed in the text box, once it is the player's turn
Function Say(MantellaConversation conversation, string line) global
    if !conversation.IsRunning() || !conversation.IsPlayersTurn()
        Note("not the player's turn, so not said: " + line)
        return
    endIf
    Note("saying: " + line)
    conversation.SayAsPlayer(line)
    Utility.Wait(1.0)
EndFunction

; On screen, and in the Papyrus log (Papyrus.0.log) when Papyrus logging is on
Function Note(string text) global
    Debug.Notification("Talk test: " + text)
    Debug.Trace("Talk test: " + text)
EndFunction
