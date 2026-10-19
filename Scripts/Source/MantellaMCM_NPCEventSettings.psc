Scriptname MantellaMCM_NPCEventSettings  Hidden

function Render(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)
    LeftColumn(mcm, Repository)
    mcm.SetCursorPosition(1)
    RightColumn(mcm, Repository)
endfunction

function LeftColumn(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.AddHeaderOption("NPC Events")
    mcm.oid_npcEventEnabled = mcm.AddToggleOption("Enabled", repository.npcEventEnabled)
    mcm.oid_npcEventFrequency = mcm.AddSliderOption("Frequency (minutes)", repository.npcEventFrequency)
    mcm.oid_showNpcEventMessages = mcm.AddToggleOption("Show Debug Messages", repository.showNpcEventMessages)
endfunction

function RightColumn(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.AddHeaderOption("Scene")
    mcm.oid_npcEventHearingDistance = mcm.AddSliderOption("Hearing Distance (m)", repository.npcEventHearingDistance)
    mcm.oid_npcEventRequireLineOfSight = mcm.AddToggleOption("Require Line of Sight", repository.npcEventRequireLineOfSight)
    mcm.oid_npcEventIncludeFollowers = mcm.AddToggleOption("Include Active Followers", repository.npcEventIncludeFollowers)
    mcm.oid_npcEventMaxCandidates = mcm.AddSliderOption("Max NPCs per Check", repository.npcEventMaxCandidates)

    mcm.AddHeaderOption("Hotkey")
    mcm.oid_keymapNpcEventHotkey = mcm.AddKeyMapOption("Check Now", repository.MantellaNpcEventHotkey)
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
    endif
endfunction
