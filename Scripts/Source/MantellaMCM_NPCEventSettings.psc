Scriptname MantellaMCM_NPCEventSettings  Hidden
{The Events page (was NPC Events): NPC Event, Conversation Event, Nearby Event and Random Event. See docs/conversation_wheel.md in the Mantella repository}

function Render(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)
    LeftColumn(mcm, Repository)
    mcm.SetCursorPosition(1)
    RightColumn(mcm, Repository)
endfunction

function LeftColumn(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.AddHeaderOption("NPC Event")
    Explain(mcm, "NPCs near you start a scene by themselves,")
    Explain(mcm, "while you watch. You can step in.")
    mcm.oid_npcEventEnabled = mcm.AddToggleOption("Enabled", repository.npcEventEnabled)
    mcm.oid_npcEventFrequency = mcm.AddSliderOption("Frequency (minutes)", repository.npcEventFrequency)
    mcm.oid_keymapNpcEventHotkey = mcm.AddKeyMapOption("Check Now", repository.MantellaNpcEventHotkey, mcm.OPTION_FLAG_WITH_UNMAP)
    mcm.oid_npcEventAskForHint = mcm.AddToggleOption("Ask for a Hint", repository.npcEventAskForHint)
    mcm.oid_npcEventHearingDistance = mcm.AddSliderOption("Hearing Distance (m)", repository.npcEventHearingDistance)
    mcm.oid_npcEventRequireLineOfSight = mcm.AddToggleOption("Require Line of Sight", repository.npcEventRequireLineOfSight)
    mcm.oid_npcEventIncludeFollowers = mcm.AddToggleOption("Include Active Followers", repository.npcEventIncludeFollowers)
    mcm.oid_npcEventMaxCandidates = mcm.AddSliderOption("Most People Described", repository.npcEventMaxCandidates)
    mcm.oid_showNpcEventMessages = mcm.AddToggleOption("Show Debug Messages", repository.showNpcEventMessages)

    mcm.AddEmptyOption()
    mcm.AddHeaderOption("Conversation Event")
    Explain(mcm, "Something happens to the people in your")
    Explain(mcm, "conversation, or around them.")
    mcm.oid_conversationEventAskForHint = mcm.AddToggleOption("Ask for a Hint", repository.conversationEventAskForHint)
    mcm.oid_conversationEventSendHistory = mcm.AddToggleOption("Send the Conversation So Far", repository.conversationEventSendHistory)
    mcm.oid_conversationEventIncludePlayer = mcm.AddToggleOption("Include Me", repository.conversationEventIncludePlayer)
endfunction

function RightColumn(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.AddHeaderOption("Nearby Event")
    Explain(mcm, "Something happens among the people nearby")
    Explain(mcm, "who aren't in your conversation. Shout is")
    Explain(mcm, "switched on, so they can join in.")
    ExplainNearby(mcm)
    mcm.oid_nearbyEventAskForHint = mcm.AddToggleOption("Ask for a Hint", repository.nearbyEventAskForHint)
    mcm.oid_nearbyEventSendHistory = mcm.AddToggleOption("Send the Conversation So Far", repository.nearbyEventSendHistory)
    mcm.oid_nearbyEventIncludePlayer = mcm.AddToggleOption("Include Me", repository.nearbyEventIncludePlayer)
    mcm.oid_nearbyEventMaxDescribed = mcm.AddSliderOption("Most People Described", repository.nearbyEventMaxDescribed)
    mcm.oid_nearbyEventIncludeFollowers = mcm.AddToggleOption("Include Followers", repository.nearbyEventIncludeFollowers)

    mcm.AddEmptyOption()
    mcm.AddHeaderOption("Random Event")
    Explain(mcm, "Something happens that can involve anyone")
    Explain(mcm, "nearby, in your conversation or not. Shout")
    Explain(mcm, "is switched on, so they can join in.")
    ExplainNearby(mcm)
    mcm.oid_randomEventAskForHint = mcm.AddToggleOption("Ask for a Hint", repository.randomEventAskForHint)
    mcm.oid_randomEventSendHistory = mcm.AddToggleOption("Send the Conversation So Far", repository.randomEventSendHistory)
    mcm.oid_randomEventIncludePlayer = mcm.AddToggleOption("Include Me", repository.randomEventIncludePlayer)
    mcm.oid_randomEventMaxDescribed = mcm.AddSliderOption("Most People Described", repository.randomEventMaxDescribed)
    mcm.oid_randomEventIncludeFollowers = mcm.AddToggleOption("Include Followers", repository.randomEventIncludeFollowers)
endfunction

; A line of a section's short explanation
function Explain(MantellaMCM mcm, string text) global
    mcm.AddTextOption(text, "", mcm.OPTION_FLAG_DISABLED)
endfunction

; Nearby and Random Events find the people nearby with Shout's settings
function ExplainNearby(MantellaMCM mcm) global
    Explain(mcm, "Who counts as nearby: the Shout Mode page's")
    Explain(mcm, "Hearing Distance, Must Be in Sight and")
    Explain(mcm, "Most People Listed, shared with Shout.")
endfunction

function SliderOptionOpen(MantellaMCM mcm, int optionID, MantellaRepository Repository) global
    if optionID == mcm.oid_npcEventFrequency
        mcm.SetSliderDialogStartValue(repository.npcEventFrequency)
        mcm.SetSliderDialogDefaultValue(20)
        mcm.SetSliderDialogRange(1, 240)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_npcEventHearingDistance
        mcm.SetSliderDialogStartValue(repository.npcEventHearingDistance)
        mcm.SetSliderDialogDefaultValue(20)
        mcm.SetSliderDialogRange(5, 100)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_npcEventMaxCandidates
        mcm.SetSliderDialogStartValue(repository.npcEventMaxCandidates)
        mcm.SetSliderDialogDefaultValue(6)
        mcm.SetSliderDialogRange(2, 10)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_nearbyEventMaxDescribed
        mcm.SetSliderDialogStartValue(repository.nearbyEventMaxDescribed)
        mcm.SetSliderDialogDefaultValue(6)
        mcm.SetSliderDialogRange(0, 10)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_randomEventMaxDescribed
        mcm.SetSliderDialogStartValue(repository.randomEventMaxDescribed)
        mcm.SetSliderDialogDefaultValue(6)
        mcm.SetSliderDialogRange(0, 10)
        mcm.SetSliderDialogInterval(1)
    endif
endfunction

function SliderOptionAccept(MantellaMCM mcm, int optionID, float value, MantellaRepository Repository) global
    mcm.SetSliderOptionValue(optionId, value)
    If optionId == mcm.oid_npcEventFrequency
        Repository.npcEventFrequency = value
    elseIf optionId == mcm.oid_npcEventHearingDistance
        Repository.npcEventHearingDistance = value
    elseIf optionId == mcm.oid_npcEventMaxCandidates
        Repository.npcEventMaxCandidates = value as int
    elseIf optionId == mcm.oid_nearbyEventMaxDescribed
        Repository.nearbyEventMaxDescribed = value as int
    elseIf optionId == mcm.oid_randomEventMaxDescribed
        Repository.randomEventMaxDescribed = value as int
    EndIf
endfunction

function OptionUpdate(MantellaMCM mcm, int optionID, MantellaRepository Repository) global
    if optionID == mcm.oid_npcEventEnabled
        Repository.npcEventEnabled =! Repository.npcEventEnabled
        mcm.SetToggleOptionValue(optionID, Repository.npcEventEnabled)
    elseIf optionID == mcm.oid_npcEventRequireLineOfSight
        Repository.npcEventRequireLineOfSight =! Repository.npcEventRequireLineOfSight
        mcm.SetToggleOptionValue(optionID, Repository.npcEventRequireLineOfSight)
    elseIf optionID == mcm.oid_npcEventIncludeFollowers
        Repository.npcEventIncludeFollowers =! Repository.npcEventIncludeFollowers
        mcm.SetToggleOptionValue(optionID, Repository.npcEventIncludeFollowers)
    elseIf optionID == mcm.oid_showNpcEventMessages
        Repository.showNpcEventMessages =! Repository.showNpcEventMessages
        mcm.SetToggleOptionValue(optionID, Repository.showNpcEventMessages)
    elseIf optionID == mcm.oid_npcEventAskForHint
        Repository.npcEventAskForHint =! Repository.npcEventAskForHint
        mcm.SetToggleOptionValue(optionID, Repository.npcEventAskForHint)
    elseIf optionID == mcm.oid_conversationEventAskForHint
        Repository.conversationEventAskForHint =! Repository.conversationEventAskForHint
        mcm.SetToggleOptionValue(optionID, Repository.conversationEventAskForHint)
    elseIf optionID == mcm.oid_conversationEventSendHistory
        Repository.conversationEventSendHistory =! Repository.conversationEventSendHistory
        mcm.SetToggleOptionValue(optionID, Repository.conversationEventSendHistory)
    elseIf optionID == mcm.oid_conversationEventIncludePlayer
        Repository.conversationEventIncludePlayer =! Repository.conversationEventIncludePlayer
        mcm.SetToggleOptionValue(optionID, Repository.conversationEventIncludePlayer)
    elseIf optionID == mcm.oid_nearbyEventAskForHint
        Repository.nearbyEventAskForHint =! Repository.nearbyEventAskForHint
        mcm.SetToggleOptionValue(optionID, Repository.nearbyEventAskForHint)
    elseIf optionID == mcm.oid_nearbyEventSendHistory
        Repository.nearbyEventSendHistory =! Repository.nearbyEventSendHistory
        mcm.SetToggleOptionValue(optionID, Repository.nearbyEventSendHistory)
    elseIf optionID == mcm.oid_nearbyEventIncludePlayer
        Repository.nearbyEventIncludePlayer =! Repository.nearbyEventIncludePlayer
        mcm.SetToggleOptionValue(optionID, Repository.nearbyEventIncludePlayer)
    elseIf optionID == mcm.oid_nearbyEventIncludeFollowers
        Repository.nearbyEventIncludeFollowers =! Repository.nearbyEventIncludeFollowers
        mcm.SetToggleOptionValue(optionID, Repository.nearbyEventIncludeFollowers)
    elseIf optionID == mcm.oid_randomEventAskForHint
        Repository.randomEventAskForHint =! Repository.randomEventAskForHint
        mcm.SetToggleOptionValue(optionID, Repository.randomEventAskForHint)
    elseIf optionID == mcm.oid_randomEventSendHistory
        Repository.randomEventSendHistory =! Repository.randomEventSendHistory
        mcm.SetToggleOptionValue(optionID, Repository.randomEventSendHistory)
    elseIf optionID == mcm.oid_randomEventIncludePlayer
        Repository.randomEventIncludePlayer =! Repository.randomEventIncludePlayer
        mcm.SetToggleOptionValue(optionID, Repository.randomEventIncludePlayer)
    elseIf optionID == mcm.oid_randomEventIncludeFollowers
        Repository.randomEventIncludeFollowers =! Repository.randomEventIncludeFollowers
        mcm.SetToggleOptionValue(optionID, Repository.randomEventIncludeFollowers)
    endif
endfunction
