# Vanilla Dialogues: keep quest scenes, drop background chatter

## Goal

NPCs remember every scene that belongs to a quest or a scripted event. They don't remember town small talk, bard songs, preachers, or the same chatter over and over. When we can't tell whether a scene is story, we keep it. Some chatter getting in is fine.

## Status (2026-11-25)

Written, not built or tested: the plugin (`MantellaVanillaDialogue`, uncommitted), Mantella (changes 3–5, list files, settings help, FEATURES_README) and the tests. The DLL isn't compiled and no test has been run. Next: build the DLL, run the tests, then the in-game check.

## Where things stood before this plan

- The chatter check works like this:
  - NPCs drop small talk that starts when two NPCs meet, unless its quest is in the journal or runs only once.
  - Mantella's two hand-checked lists come on top: Quests That Are Background Chatter, and Quests That Aren't.
- It isn't in the game yet. The installed add-on (`MantellaHeardLines.dll`) is still the build that only logs. The quest details the check needs are uncommitted changes in the plugin. This plan builds on those changes.

## What we found

Every scene in Skyrim, Update, Dawnguard, Hearthfires and Dragonborn was sorted with today's rules and default settings. Remember Scenes When NPCs Meet is off by default.

| What happens today | Scenes |
|---|---|
| Kept: part of a quest in the journal | 804 |
| Kept: runs only once | 177 |
| Kept: on Quests That Aren't Background Chatter | 41 |
| Kept: other scenes that can play again | 171 |
| Dropped: on Quests That Are Background Chatter | 73 |
| Dropped: small talk when two NPCs meet | 864 |

The problems:

1. **Story scenes that get dropped.** About 35 small-talk scenes only play at certain steps of a quest, for example:
   - the Karthwasten miners and the Silver-Blood takeover
   - Enmon and Mena missing their daughter after The Heart of Dibella
   - the Soljund's Sinkhole miners after the draugr are cleared
   - the Crimson Nirnroot at Sarethi Farm
   - the Raven Rock investigation

   More follow a quest in ways a quest-stage check can't see:
   - The Thirsk Nords, before and after you retake the mead hall (14 scenes). A switch the Thirsk quest sets decides which set plays: "We need to be back up there" before, "What exactly happened at the barrow?" after.
   - Crescius after The Final Descent: "They laughed at me… But I proved them wrong." The check sits in the game's quest-starting system, not on the quest or the scene.
   - Drovas at Tel Mithryn: "I miss Varona." It only plays once Drovas has moved in.
   - Grosta and Gralnach at Heartwood Mill: the same scene with different lines before and after the quest about Gralnach's father ("He left us…" / "now that he's dead…").
   - Scenes at quest places that check no quest at all: the apprentices at Saarthal, Delphine and Esbern at Sky Haven Temple, the prisoners in Cidhna Mine, and the Severins at Raven Rock.
2. **Background barks get in.** An NPC who is inside a scene can say a greeting, an idle remark or a combat shout. That line is kept and labelled with the scene's quest, so during a civil war battle every shout gets in. Checking the quest alone isn't enough either: quests that run scenes also own over 5,000 greetings, idle remarks and combat lines of their own.
3. **Town quests mix story and chatter.** Whiterun's town quest holds the Jarl hearing about the dragon, but also Mikael's song and the Battle-Born and Gray-Mane feud. The lists can only name a whole quest, so the chatter stays to protect the story scene.
4. **Repeats during a conversation.** Repeats aren't dropped inside a live conversation, so a scene that loops while you talk goes in again.
5. **Fake journal categories and list gaps.**
   - `WIAddItem03` is noted as "reactions to you picking something up". It is really the hired thugs who come for you with a contract.
   - Two small-talk quests (`WITavernServerPatronSceneA` and `WICastMagic01ActorDialogueEvent`) count as "in the journal" only because Bethesda gave them the Miscellaneous category without any objectives, and `DarkBrotherhoodSanctuaryConvSystem` has the Dark Brotherhood category without any stages or objectives.
   - Several ambient chatter quests from Skyrim and the DLCs are missing from the list: Dawnguard follower commentary (`DLC1NPCCommentary01..03`), Solstheim instrumentals (`DLC2dunInstrumentalQST`), adopted kids calling each other names (`BYOHRelationshipAdoption`), brawl crowd cheers (`DGIntimidateQuest`), and Blades sparring (`MQSkyHavenSparring`). (`WIGamesHideAndSeek` has journal objectives and only runs when the player joins hide-and-seek with a child, so it stays out of the chatter list.)
   - The 10 Solitude palace scenes (taxes, Haafingar's defences, Tullius's appointment, Sybille's reagents, a parade) check `MS05` only to pause during the Burning of King Olaf. They are court small talk, not story.

## The plan

### 1. A line said during a scene must be one of that scene's dialogue actions

Today a line is kept whenever its speaker is in a scene. From now on, a non-`Scene` subtype line spoken during a scene is kept only when its topic is one of that scene's own dialogue actions. Greetings, idle remarks and combat shouts—even ones owned by the same quest—are dropped.

No scene line is lost by this. All 8,784 dialogue topics used by scenes (including the 5 in Dragonborn whose topic subtype isn't `Scene`) are dialogue actions on their scene.

*Example:* during the Battle of Whiterun or Helgen, a soldier shouts a combat taunt. Even if that taunt belongs to `MQ101` or the battle's quest, it isn't a dialogue action of the running scene, so it is dropped. Balgruuf's surrender is a scene dialogue action and is kept.

### 2. Fix "in the journal", and keep small talk that follows a quest's progress

First, a Miscellaneous quest only counts as in the journal when it has objectives, matching Skyrim's journal UI. That automatically drops fake-Miscellaneous small talk (`WITavernServerPatronSceneA`, `WICastMagic01ActorDialogueEvent`, and modded equivalents) without needing list entries. In Skyrim and the DLCs this changes nothing else that NPCs remember: it only decides whether small talk from two NPCs meeting counts as story.

Second, small talk from two NPCs meeting is kept when its quest or the scene itself checks the progress of a real journal quest. The whole scene is decided at once, so a conversation is never kept in pieces. This brings back 35 scenes, and works for quest mods with no list to keep up.

The lines' own conditions aren't read. In 7 scenes only some lines check a quest, so reading them would keep half a conversation. Six of those are chatter anyway (4 Solitude market scenes, Vivienne and Lisette, "Are we running low on mead?" in Winterhold) and stay dropped. The seventh, Heartwood Mill, goes on Quests That Aren't Background Chatter (change 4).

*Example:* after The Heart of Dibella, Enmon tells Mena "I still miss her". That scene only plays after a certain step of the quest, so it's kept. Two Riften merchants talking about the weather check no quest, so they're dropped.

The 10 Solitude palace scenes also check `MS05`, but only to pause during the Burning of King Olaf. They go on Quests That Are Background Chatter (change 4), which comes before this rule, so they stay dropped.

### 3. The lists can name one scene

An entry in Quests That Are Background Chatter, or Quests That Aren't, can be a whole quest as today, or one single scene. That lets us drop chatter from a town quest without losing its story scenes, and keep one story scene from a quest that is otherwise chatter.

A scene entry wins over a quest entry. So a scene on Quests That Are Background Chatter is dropped even when its whole quest is on Quests That Aren't, and the other way round. Between two entries of the same kind, the player's entries still come first, and Quests That Aren't still wins over Quests That Are.

First scene entries. Each is checked against the scene's actual words before it ships.

| Scene | List | What it is |
|---|---|---|
| Mikael's song in the Bannered Mare | Quests That Are | A bard performing |
| The Battle-Born and Gray-Mane feud (2 scenes) | Quests That Are | The same argument, again and again |
| Kleppr and Frabbi bickering in Markarth | Quests That Are | An innkeeper couple's spat |
| Drovas and Elynea at Tel Mithryn: "I miss Varona." | Quests That Aren't | Drovas missing Varona after she dies. The rest of the Tel Mithryn household talk stays dropped |

The Jarl's dragon news, Amren's sword, Calixto's tour, Grelod's speech and the first-arrival scenes stay. They are story, or we can't be sure they aren't.

To add their own scene entry, players need the scene's name as Mantella knows it. The Vanilla Dialogues log at Full shows it with every scene line, next to the quest, so they can copy it from there without a mod editor.

*Example:* `Mikael to Ysolda: "One more song, what say you?" in The Bannered Mare. … Quest DialogueWhiterun. Scene Skyrim.esm:092A31.`

### 4. List fixes

Quests That Are Background Chatter:
- **Add:**
  - `DarkBrotherhoodSanctuaryConvSystem`: repeating Dark Brotherhood Sanctuary small talk.
  - `BYOHRelationshipAdoption`: adopted kids calling each other names.
  - `DLC1NPCCommentary01`, `DLC1NPCCommentary02`, `DLC1NPCCommentary03`: Dawnguard follower commentary on caves and danger (matching `FollowerCommentary01..03`).
  - `DLC2dunInstrumentalQST`: Solstheim instrumental performances (matching `BardSongsInstrumental`).
  - `DGIntimidateQuest`: bystanders cheering during a brawl.
  - `MQSkyHavenSparring`: Blades sparring barks.
  - `DialogueSolitudePalaceScene1` to `DialogueSolitudePalaceScene10`, each by name (the chatter list never uses `*`): Solitude court small talk (taxes, defences, Tullius's appointment, Sybille's reagents, a parade).
- **Remove:** `WIAddItem03`, the hired thugs. It's a scripted encounter aimed at the player, not chatter. Its scene speaks no lines, so nothing changes in game; this only makes the list honest.
- **Fix the note** on `WICastMagic01`: it's a child asking you to make them invisible, not a mage waiting.
- **Leave off** `WIGamesHideAndSeek`: it has 2 journal objectives and only runs when you play hide-and-seek with a child.
- **Keep** the reactions to what the player did (your decision, 2026-11-25): relatives after a killing (`WIKill05`), witnesses of a dragon kill (`WIDragonKilled`), and a dead body found (`WIDeadBody01`).

Quests That Aren't Background Chatter, add:
- `DialogueSaarthal*`: the apprentices at Saarthal during Under Saarthal.
- `DialogueSkyHavenTemple*`: Delphine and Esbern at Sky Haven Temple.
- `DialogueCidhnaMine*`: the prisoners inside Cidhna Mine during No One Escapes Cidhna Mine.
- `DLC2RRSeverinManorScene*`: the Severins hinting at their plot in Raven Rock.
- `DLC2MH*`: the Thirsk Nords, before and after you retake the mead hall.
- `DLC2RRCresciusHouseScene*`: Crescius and Aphia after The Final Descent.
- `DialogueHeartwoodMillScene01`: Grosta and Gralnach talking about his father, before and after the quest.
- The "I miss Varona" scene entry from change 3.

Guild and faction home banter stays dropped unless change 2 keeps it. That covers Jorrvaskr, the College halls, Fort Dawnguard, Castle Volkihar and Tel Mithryn: everyday talk that doesn't follow a quest.

### 5. No repeats within a conversation

A line already given in a live conversation isn't given again, matched by the same speaker and the same words. It's still remembered once when the conversation ends, as today.

### Considered and left out

- **Dropping repeats across visits, and dropping chatter first when an NPC's memory is full.** Both needed a "less important" group: scenes that aren't in the journal, aren't Run Once and aren't on Quests That Aren't Background Chatter. Of the 190 scenes in that group, only about 15–20 are town small talk. The rest are quest moments: Wuunferth's arrest, Roggvir's execution, your own wedding, the Thieves Guild finding the vault empty, the Forsworn attack when you arrive in Markarth, the Civil War map-table scenes. These would have been forgotten first, or ignored on a later visit. And they would rarely help: NPCs already forget lines after 3 in-game days, keep at most 30, and skip a line from the same speaker with the same words while they still remember the first one. Dropping repeats across visits would also count "first time" once for everyone, so a follower who joined later would never hear a scene that played before.

### What stays as accepted noise

- Town scenes we couldn't be sure about, such as the kids fighting in Whiterun and the bullies in Windhelm. Each NPC keeps one copy at a time, and forgets it after 3 in-game days.
- Bandits talking in dungeons. Mostly the bandits themselves hear it.
- Asking a bard to play a song in the dialogue menu. You chose it, so it's remembered. The song itself is on `BardSongs` and dropped.

## Build order

1. Plugin (`MantellaVanillaDialogue`): changes 1 and 2, and the scene identity change 3 needs. Build `MantellaHeardLines.dll` (via GitHub Actions, or locally once VS 2022 + `xmake` are installed) and copy it into `Mantella-Spell\SKSE\Plugins\`.
2. Mantella: scene entries in the lists (3), list fixes (4), live-conversation repeat check (5).
3. Settings help text for scene entries. The wording is shown to you before it ships.
4. In-game check (below).

## Tests (written, not run unless asked)

- **Plugin unit tests:**
  - A non-`Scene` line spoken during a scene whose topic isn't one of the scene's dialogue actions is dropped (even if owned by the same quest). One whose topic is a dialogue action of the scene is kept, including the five Dragonborn scene lines.
  - Miscellaneous quests without objectives have `inJournal == false`.
  - The quest-progress mark keeps small talk, and also changes which waiting lines go first.
- **Python tests:**
  - A scene entry drops only that scene. `-entry` switches a shipped scene entry off. A player's entry wins.
  - A scene entry wins over a quest entry, both ways: a chatter scene inside a story quest is dropped, a story scene inside a chatter quest is kept.
  - The log line at Full shows the scene key for scene lines, and no scene for menu talk or lines outside a scene.
  - Small talk with the quest-progress mark is kept when the switch is off, unless it's on Quests That Are Background Chatter.
  - A repeat inside one conversation is given once and remembered once.
  - Every new and changed list entry is checked against the shipped files.
- **Guided in-game check:**
  - Bannered Mare: Mikael's song, the feud, and tavern server/patron small talk are dropped. The Jarl's dragon news is kept.
  - Karthwasten after The Heart of Dibella: Enmon and Mena's scene is kept.
  - Blue Palace: court small talk is dropped.
  - A civil war battle: no combat shouts.
  - Talk to someone in a tavern while a scene repeats: it's given once.
  - Everything is visible in the Vanilla Dialogues log topic at Full, including each scene line's scene key. Copying a key from the log into Quests That Are Background Chatter drops that scene.

## For developers

| Plain words | In code |
|---|---|
| Line belongs to the scene | New `LineFacts::topicInScene`, read in `GameLineReader::ReadFacts`: true when `speaker->GetCurrentScene()` has a `RE::BGSSceneAction` with `GetType() == RE::BGSSceneAction::Type::kDialogue` whose `static_cast<const RE::BGSSceneActionDialogue*>(action)->topic == info->parentTopic`. `IsWorthKeeping` (`src/logic/line_filter.cpp`) replaces `\|\| a_line.sceneId != 0` with `\|\| (a_line.sceneId != 0 && a_line.topicInScene)` |
| Quest in the journal | New plain `IsJournalQuest(type, hasObjectives)` in `src/logic/heard_line.h` (unit-tested), used by `QuestOf` (`src/game_line_reader.cpp`): `(type != kNone && type != kMiscellaneous) \|\| hasObjectives`, so Miscellaneous quests with 0 objectives (`WITavernServerPatronSceneA`, `WICastMagic01ActorDialogueEvent`) aren't misclassified as journal quests. It only feeds the small-talk test and `follows_quest`; nothing ranks lines by it |
| Follows a quest's progress | New `SceneQuest::followsQuest`, JSON `follows_quest`. True when any `TESConditionItem` on `quest->objConditions`, `quest->storyManagerConditions` or `scene->conditions` uses `FunctionID` `kGetStage` (58), `kGetStageDone` (59), `kGetQuestRunning` (56), or `kGetQuestCompleted` (543) with `data.functionData.params[0]` pointing to another `RE::TESQuest*` that satisfies `inJournal`. Not `info->objConditions` (would keep scenes in pieces) and not phase conditions or Story Manager node conditions (in the five masters, the nodes add only Crescius, which is listed, and one Riverwood shop chatter scene) |
| Small talk when NPCs meet | `SceneQuest.is_small_talk_when_npcs_meet` and C++ `LooksLikeChatter()` both add `and not follows_quest` |
| Scene identity | New `HeardLine::sceneKey` (JSON `"scene_key"`), built in `GameLineReader::ReadLine` when `scene != nullptr && !a_facts.menuTalk` from `scene->GetFile(0)->GetFilename()` and `fmt::format("{:06X}", scene->GetLocalFormID())` (`RE::TESForm::GetLocalFormID()` handles both standard `0xFFFFFF` and light `FE` `0xFFF` masks). Shipped lists use `<file>:<6-hex>` with a `#` comment naming the scene and its first words |
| Scene entries | An entry with a colon is a scene entry (`EditableList.scenes()` / `.quests()`), so a wildcard quest entry like `*` never decides at scene level; a `-` entry switches off both kinds. `heard_lines_receiver.__why_background_chatter` checks `line.scene_key` against scene entries first, then `quest.id` against quest entries, each in today's order (player's story, player's chatter, our story, our chatter); the first match decides. First shipped chatter scene entries: `Skyrim.esm:092A31` (`WhiterunMikaelSongScene`), `Skyrim.esm:0E3DE3` & `Skyrim.esm:0E3DE4` (`WhiterunFeudScene1/2`), `Skyrim.esm:035F13` (`KlepprFrabbiSceneFromHello`). First shipped story scene entry: `Dragonborn.esm:03A320` (`DLC2DrovasElyneaScene01`) |
| Scene key in the log | `GameHeardLinesReceiver.__describe` appends ` Scene {line.scene_key}.` after the quest when `line.scene_key` is set, the same way it appends ` Quest {line.quest.id}.` today |
| No repeats in a conversation | `Conversation.add_heard_dialogue` keeps `(speaker.ref_id, words, asked)` of every line already given in this conversation and skips repeats, before they reach the next message or `__heard_for_memory` |
| In-game test | `tests/ingame/heard_lines/heard_lines_ingame.py` plays the feud scene, which is now on Mantella's chatter list: setup puts `-Skyrim.esm:0E3DE3` in Quests That Are Background Chatter, and each line is checked for its scene key and quest |

Data used: a read-only parse of the five official master files, with the last loaded record winning. It covers 2,130 scenes and 8,784 scene topics: 8,779 are the scene kind, and 5 are the other kind (`DLC2RRArrivalScene`, `DLC2MQ04`, `DLC2MQ05`, `DLC2MQ06`, `DLC2TameDragon`). All 8,784 are `BGSSceneActionDialogue` actions on their scene. `WIAddItem03` was confirmed as the hired thugs from its aliases (`Owner`, `Thug1..3`, `Contract`) and `QF_WIAddItem03_00035B5A.psc`. `WICastMagic02`, `WICastMagic03`, `WICastMagic04` and `WIGamesHideAndSeek` have journal objectives, so the list uses exact names and leaves objective quests untouched. Story Manager nodes were parsed too: the Thirsk scenes sit under `DLC2ThirskRetreatScenes` / `DLC2ThirskReclaimedScenes` (a global the Thirsk quest sets), and Crescius under a node that checks `GetStageDone DLC2RR03`. Every dropped small-talk scene's conditions were checked, the opening lines of every non-town one were read, and all town lines were searched for quest words. The town gossip found (the Windhelm murders, "did you hear about Helgen?") plays at any point in the story.
