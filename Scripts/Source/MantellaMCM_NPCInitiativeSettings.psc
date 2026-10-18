Scriptname MantellaMCM_NPCInitiativeSettings  Hidden

function Render(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)
    LeftColumn(mcm, Repository)
    mcm.SetCursorPosition(1)
    RightColumn(mcm, Repository)
endfunction

function LeftColumn(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.AddHeaderOption("NPC Initiative")
    mcm.oid_npcInitiativeEnabled = mcm.AddToggleOption("Enabled", repository.npcInitiativeEnabled)
    mcm.oid_npcInitiativeOnLocationChange = mcm.AddToggleOption("Check on Location Change", repository.npcInitiativeOnLocationChange)
    mcm.oid_npcInitiativeIdleMinutes = mcm.AddSliderOption("Idle Check (minutes)", repository.npcInitiativeIdleMinutes)
    mcm.oid_npcInitiativeIncludeFollowers = mcm.AddToggleOption("Include Active Followers", repository.npcInitiativeIncludeFollowers)
    mcm.oid_npcInitiativeMaxFollowers = mcm.AddSliderOption("Max Active Followers per Check", repository.npcInitiativeMaxFollowers)
    mcm.oid_showNpcInitiativeMessages = mcm.AddToggleOption("Show Debug Messages", repository.showNpcInitiativeMessages)
endfunction

function RightColumn(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.AddHeaderOption("Checks")
    mcm.oid_npcInitiativeMinInterval = mcm.AddSliderOption("Min Time Between Checks (s)", repository.npcInitiativeMinInterval)
    mcm.oid_npcInitiativeSettleDelay = mcm.AddSliderOption("Wait After Location Change (s)", repository.npcInitiativeSettleDelay)
    mcm.oid_npcInitiativeMaxDistance = mcm.AddSliderOption("Max Distance (m)", repository.npcInitiativeMaxDistance)
    mcm.oid_npcInitiativeIgnoreLineOfSight = mcm.AddToggleOption("Ignore Line of Sight", repository.npcInitiativeIgnoreLineOfSight)
    mcm.oid_npcInitiativeMaxCandidates = mcm.AddSliderOption("Max NPCs per Check", repository.npcInitiativeMaxCandidates)

    mcm.AddHeaderOption("Hotkey")
    mcm.oid_keymapNpcInitiativeHotkey = mcm.AddKeyMapOption("Check Now", repository.MantellaNpcInitiativeHotkey)
    mcm.oid_npcInitiativeHotkeySkipsThreshold = mcm.AddToggleOption("Skip Threshold", repository.npcInitiativeHotkeySkipsThreshold)
endfunction

function SliderOptionOpen(MantellaMCM mcm, int optionID, MantellaRepository Repository) global
    if optionID == mcm.oid_npcInitiativeIdleMinutes
        mcm.SetSliderDialogStartValue(repository.npcInitiativeIdleMinutes)
        mcm.SetSliderDialogDefaultValue(10)
        mcm.SetSliderDialogRange(0, 120)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_npcInitiativeMinInterval
        mcm.SetSliderDialogStartValue(repository.npcInitiativeMinInterval)
        mcm.SetSliderDialogDefaultValue(60)
        mcm.SetSliderDialogRange(10, 600)
        mcm.SetSliderDialogInterval(5)
    elseIf optionID == mcm.oid_npcInitiativeSettleDelay
        mcm.SetSliderDialogStartValue(repository.npcInitiativeSettleDelay)
        mcm.SetSliderDialogDefaultValue(3)
        mcm.SetSliderDialogRange(0, 30)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_npcInitiativeMaxDistance
        mcm.SetSliderDialogStartValue(repository.npcInitiativeMaxDistance)
        mcm.SetSliderDialogDefaultValue(10)
        mcm.SetSliderDialogRange(1, 50)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_npcInitiativeMaxCandidates
        mcm.SetSliderDialogStartValue(repository.npcInitiativeMaxCandidates)
        mcm.SetSliderDialogDefaultValue(5)
        mcm.SetSliderDialogRange(1, 10)
        mcm.SetSliderDialogInterval(1)
    elseIf optionID == mcm.oid_npcInitiativeMaxFollowers
        mcm.SetSliderDialogStartValue(repository.npcInitiativeMaxFollowers)
        mcm.SetSliderDialogDefaultValue(2)
        mcm.SetSliderDialogRange(0, 10)
        mcm.SetSliderDialogInterval(1)
    endif
endfunction

function SliderOptionAccept(MantellaMCM mcm, int optionID, float value, MantellaRepository Repository) global
    mcm.SetSliderOptionValue(optionId, value)
    If optionId == mcm.oid_npcInitiativeIdleMinutes
        Repository.npcInitiativeIdleMinutes = value
    elseIf optionId == mcm.oid_npcInitiativeMinInterval
        Repository.npcInitiativeMinInterval = value
    elseIf optionId == mcm.oid_npcInitiativeSettleDelay
        Repository.npcInitiativeSettleDelay = value
    elseIf optionId == mcm.oid_npcInitiativeMaxDistance
        Repository.npcInitiativeMaxDistance = value
    elseIf optionId == mcm.oid_npcInitiativeMaxCandidates
        Repository.npcInitiativeMaxCandidates = value as int
    elseIf optionId == mcm.oid_npcInitiativeMaxFollowers
        Repository.npcInitiativeMaxFollowers = value as int
    EndIf
endfunction

function OptionUpdate(MantellaMCM mcm, int optionID, MantellaRepository Repository) global
    if optionID == mcm.oid_npcInitiativeEnabled
        Repository.npcInitiativeEnabled =! Repository.npcInitiativeEnabled
        mcm.SetToggleOptionValue(optionID, Repository.npcInitiativeEnabled)
    elseIf optionID == mcm.oid_npcInitiativeOnLocationChange
        Repository.npcInitiativeOnLocationChange =! Repository.npcInitiativeOnLocationChange
        mcm.SetToggleOptionValue(optionID, Repository.npcInitiativeOnLocationChange)
    elseIf optionID == mcm.oid_npcInitiativeIncludeFollowers
        Repository.npcInitiativeIncludeFollowers =! Repository.npcInitiativeIncludeFollowers
        mcm.SetToggleOptionValue(optionID, Repository.npcInitiativeIncludeFollowers)
    elseIf optionID == mcm.oid_showNpcInitiativeMessages
        Repository.showNpcInitiativeMessages =! Repository.showNpcInitiativeMessages
        mcm.SetToggleOptionValue(optionID, Repository.showNpcInitiativeMessages)
    elseIf optionID == mcm.oid_npcInitiativeHotkeySkipsThreshold
        Repository.npcInitiativeHotkeySkipsThreshold =! Repository.npcInitiativeHotkeySkipsThreshold
        mcm.SetToggleOptionValue(optionID, Repository.npcInitiativeHotkeySkipsThreshold)
    elseIf optionID == mcm.oid_npcInitiativeIgnoreLineOfSight
        Repository.npcInitiativeIgnoreLineOfSight =! Repository.npcInitiativeIgnoreLineOfSight
        mcm.SetToggleOptionValue(optionID, Repository.npcInitiativeIgnoreLineOfSight)
    endif
endfunction
