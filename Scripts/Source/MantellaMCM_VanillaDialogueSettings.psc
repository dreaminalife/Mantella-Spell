Scriptname MantellaMCM_VanillaDialogueSettings  Hidden
{The Vanilla Dialogues page. Vanilla Dialogues can also be turned on and off from the Conversation Wheel}

function Render(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)
    if !repository.IsHeardLinesInstalled()
        mcm.AddHeaderOption("Vanilla Dialogues")
        mcm.AddTextOption("Needs the MantellaHeardLines plugin.", "", mcm.OPTION_FLAG_DISABLED)
        return
    endIf
    LeftColumn(mcm, Repository)
    mcm.SetCursorPosition(1)
    RightColumn(mcm, Repository)
endfunction

function LeftColumn(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.AddHeaderOption("Vanilla Dialogues")
    mcm.oid_enableVanillaDialogueAwareness = mcm.AddToggleOption("Enabled", repository.enableVanillaDialogueAwareness)
    mcm.AddEmptyOption()
    ; Vanilla Dialogue Memory (Days), Most Vanilla Dialogue Lines per NPC and Lines That Only Open a Menu are in Mantella, as only Mantella uses them
    mcm.AddTextOption("More options: Mantella's settings,", "", mcm.OPTION_FLAG_DISABLED)
    mcm.AddTextOption("Other tab.", "", mcm.OPTION_FLAG_DISABLED)
endfunction

function RightColumn(MantellaMCM mcm, MantellaRepository Repository) global
    mcm.AddHeaderOption("Who Hears")
    mcm.oid_vanillaDialogueNearbyOverhear = mcm.AddToggleOption("Nearby NPCs Overhear", repository.vanillaDialogueNearbyOverhear)
    mcm.oid_vanillaDialogueHearingDistance = mcm.AddSliderOption("Hearing Distance (m)", repository.vanillaDialogueHearingDistance)
endfunction

function SliderOptionOpen(MantellaMCM mcm, int optionID, MantellaRepository Repository) global
    if optionID == mcm.oid_vanillaDialogueHearingDistance
        mcm.SetSliderDialogStartValue(repository.vanillaDialogueHearingDistance)
        mcm.SetSliderDialogDefaultValue(20)
        mcm.SetSliderDialogRange(5, 50)
        mcm.SetSliderDialogInterval(1)
    endif
endfunction

function SliderOptionAccept(MantellaMCM mcm, int optionID, float value, MantellaRepository Repository) global
    if optionId == mcm.oid_vanillaDialogueHearingDistance
        mcm.SetSliderOptionValue(optionId, value)
        Repository.vanillaDialogueHearingDistance = value
        Repository.SendHeardLinesSettings()
    endIf
endfunction

function OptionUpdate(MantellaMCM mcm, int optionID, MantellaRepository Repository) global
    if optionID == mcm.oid_enableVanillaDialogueAwareness
        Repository.SetVanillaDialogues(!Repository.enableVanillaDialogueAwareness)
        mcm.SetToggleOptionValue(optionID, Repository.enableVanillaDialogueAwareness)
    elseIf optionID == mcm.oid_vanillaDialogueNearbyOverhear
        Repository.vanillaDialogueNearbyOverhear =! Repository.vanillaDialogueNearbyOverhear
        mcm.SetToggleOptionValue(optionID, Repository.vanillaDialogueNearbyOverhear)
        Repository.SendHeardLinesSettings()
    endif
endfunction
