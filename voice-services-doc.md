# Voice services for Mantella: research and plan

Nov 14, 2026 · @Yuji

This doc answers two questions. Part 1: which voice services Mantella should support, on this PC and online, so every player gets the best voice their PC and budget allow. Part 2: how Mantella plugs services in, so it can support as many as possible and add the next good one cheaply. For both, we look at how SkyrimNet and CHIM already do it. The answer so far: three services first (one on this PC, two online), all of which copy voices from clips taken straight from the game while you play, the way SkyrimNet does it; one shared way of talking to all of them; no code for any service that follows a common request style such as OpenAI's; and ready-made setups for the ones we know.

## How voices work in Mantella today

Every voice service, on this PC or online, plugs in at the same point: Mantella sends it each line and gets a sound file back. The game add-on (Mantella-Spell) gets two new jobs: handing Mantella voice clips from the game (Step 3 of the plan), and telling Mantella when an NPC is a ghost, for voice effects (Step 5).

What happens when an NPC speaks:

1. Mantella picks the voice program. Normally the one chosen under TTS Service. An NPC can have its own in the character file's tts_service column (for example Serana on xVASynth, everyone else on Piper).
2. Mantella picks the voice. From the NPC's voice type in the game (for example Male Nord) or a voice named in the character file.
3. The voice program turns the line into a sound file.
4. Mantella makes the lip movement file from that sound, the same way for every voice program.
5. The game plays the line.

A new voice service only changes steps 1–3. Step 4 onward already works for any voice program.

The three services Mantella has today, with Pocket TTS for comparison:

| Voice program | Runs on | Voices | Setup |
| --- | --- | --- | --- |
| Piper | Processor | One trained file per Skyrim voice type, shipped with Mantella | None |
| XTTS | Graphics card (processor is slow) | Copied from Skyrim voice clips, shipped as a voice pack | Separate download |
| xVASynth | Graphics card or processor | Trained Skyrim voices | Separate download |
| Pocket TTS | Processor | Copied from a game clip per voice type, or per NPC when their voice differs | pocket-tts.exe; voice clips come from the game |

# Part 1: Which voice services to support

The aim is the best voice for each kind of player: a PC with no graphics memory to spare, a PC with some, and players happy to pay for an online service. Every service must copy voices from game clips; services that only have their own voices are out. Rankings change every few months, so the picks below are a starting point; Part 2 is what keeps Mantella current. What SkyrimNet and CHIM chose is compared under What we learned from SkyrimNet and CHIM.

## What a voice service has to do well in Mantella

The services below are judged on eight things. The first three decide whether a service is usable at all; the rest decide which one a player picks.

| What matters | Why it matters in Mantella | How we judge it |
| --- | --- | --- |
| Time to first sound | Mantella voices each sentence as soon as it is written, so a slow service means NPCs pause before every sentence. | Time from sending a sentence to the first sound, from the makers' figures and public tests. Aim for under half a second. |
| Runs next to Skyrim | A modded Skyrim already fills most of the graphics card's memory. A service that needs a big graphics card fights the game for it. | Runs on the processor, or fits in a few GB of graphics card memory. Online services need neither. |
| Sounds like Skyrim | Lydia should sound like a Skyrim housecarl, not a podcast host. | Must copy a voice from a short game clip. Services that only have their own voices are out. |
| Sounds natural | Flat or robotic lines break the scene. | Public blind listening rankings (Artificial Analysis). |
| Languages | Mantella players play in many languages. | Covers the language chosen in Mantella's Language setting. |
| Cost | Online services charge by the amount of text. | A 30-line conversation is about 3,000 characters: $0.24 at $80 per million characters, $0.05 at $15. |
| Privacy and offline play | Some players don't want their game sent online, or play without internet. | Runs on this PC or not. |
| How it plugs in | Decides the work for us. | Follows a common request style (no code), or needs its own file. |

Licences matter less than usual: personal play is allowed by almost every licence below. They matter only if a voice program is shipped inside Mantella; a non-commercial licence rules that out.

My view: the first three are pass or fail; the rest are trade-offs.

## The best voice services on this PC right now

For a PC that is also running Skyrim, the best fit is a small model that runs on the processor: Pocket TTS copies voices without touching the graphics card. With graphics card memory to spare, Qwen3-TTS and Chatterbox Turbo copy voices well. The top-ranked open models (Fish Audio Drama 3, Breeze TTS 2) need a large graphics card on their own, so they are better reached online.

| Service (maker, release) | Size and hardware | Copies voices from a clip? | Languages | Licence | How it plugs in |
| --- | --- | --- | --- | --- | --- |
| Pocket TTS (Kyutai, Jan 2026) | 100M; processor, about 2 cores | Yes, 5–10 s | English, French, German, Portuguese, Italian, Spanish, Dutch | Program MIT; model CC BY 4.0. Kyutai's own download of the voice-copying version needs the player's own Hugging Face sign-in (see Making Pocket TTS plug and play) | Kyutai's own program (own file; our pick, see Which program runs Pocket TTS), or llama.cpp and audio.cpp (OpenAI-style) |
| Qwen3-TTS (Alibaba, Jan 2026) | 0.6B (about 3 GB graphics memory) or 1.7B (about 6 GB) | Yes, 3 s | 10, including English, German, French, Spanish, Russian, Japanese, Chinese | Apache 2.0 per one roundup; to confirm | OpenAI-style (several community servers, vLLM-Omni) |
| Chatterbox Turbo (Resemble AI, Dec 2025) | 350M; graphics card | Yes, 5 s | English (Chatterbox Multilingual: 23) | MIT | Community servers, XTTS-style or OpenAI-style |
| XTTS v2 (Coqui; already in Mantella) | Graphics card preferred | Yes, about 6 s | 17 | Coqui Public Model Licence; no longer maintained | XTTS-style |
| Breeze TTS 2 (BreezeBlue, Aug 2026) | 3B; 12 GB graphics card (uses 7.7 GB) | Yes, plus voices designed from a description | English and Chinese on its model card | Research and non-commercial | Not checked |
| Fish Audio Drama 3 (Oct 2026) | 35B (3B active); 48 GB graphics card advised | Yes | Many | Fish Audio Community Licence | Better reached online |
| Voxtral TTS (Mistral, Mar 2026) | 4B; graphics card | Yes, about 3 s | 9 | CC BY-NC 4.0 | Better reached online |

Also ranked highly among open models but not checked in detail: Ming-3.0-tts (Ant Group), Higgs Audio V3 (Boson AI), Fish Audio S2 Pro, Step Audio EditX, NVIDIA Magpie-Multilingual. Check voice copying first for any of these. Speeds on this list come from the makers.

My view: Pocket TTS is the right first pick on this PC. Makers measure speed on an idle PC and a modded Skyrim keeps the processor busy, so a player whose processor can't keep up has llama.cpp on the graphics card as a ready-made setup (Part 2). Qwen3-TTS (3 GB of graphics memory at its smallest) and Chatterbox Turbo are not picked: they need graphics memory a modded Skyrim is already using. Breeze and Fish Audio Drama 3 are not options on a gaming PC today.

## The best online voice services right now

ElevenLabs v4 sounds best in blind listening tests, but several services come close for a fraction of the price. Every online service that copies voices needs its own file, because each one copies voices its own way.

*[Chart: Artificial Analysis Provider Voice Arena and its listed API prices, read 14 Nov 2026 · 12 services. Keep the chart from the original doc.]*

The chart ranks all 12; we only keep those that copy voices. September to November 2026 releases fill the top of the ranking, so it will keep moving; the approach matters more than today's winner.

| Service | Copies voices from a clip? | Languages | How it plugs in |
| --- | --- | --- | --- |
| ElevenLabs Eleven v4 and v4 Turbo | Yes, from about 10 s | 90+ | Own file |
| Cartesia Sonic 3.6 | Only on the Pro plan or higher, so it is out (see below) | 44 | Own file |
| Fish Audio Drama 3 | The free plan keeps no cloned voices of your own, so it is out (see below) | Many | Own file |
| HeyGen Voice Turbo | Yes, free while HeyGen calls it a preview (20 a day on a free account) | 39 | Own file |
| Qwen Audio 3.1 TTS Plus (Alibaba Cloud) | Yes, free | 16 | Own file |
| Boson AI Higgs TTS 3 | Yes, but only together with the words spoken in the clip | 102 | Own file |
| Inworld Realtime TTS-2 and TTS-2 Flash | Yes, from 5–15 s, on every plan including free | Not checked | Own file: its request style is its own, not OpenAI's |
| Mistral Voxtral TTS | Yes, from about 3 s | 9 | Own file for copying voices |
| MiniMax Speech 2.8 | Yes, from 10 s ($1.50 per voice) | Many | Own file; price per million characters differs between sources ($50 or $100) |

To make Lydia sound like Lydia online, Mantella has to upload her game clip to the service once and reuse the voice it makes, and every service does that differently. That is why each online service needs its own file.

Decided (2026-11-18): an online service is only added if it clones voices on its free plan, so a player can try it before paying. That keeps HeyGen, Qwen and Boson AI (Step 9) and leaves out:

- Cartesia: cloning needs its Pro plan ($5 a month).
- Fish Audio: its free plan keeps no cloned voices of your own, and its free model ends on Nov 30, 2026.
- Speechify: it only clones a voice after the person whose voice it is reads a sentence out loud, and it checks that this is the same voice. A game clip can't do that.

My view: ElevenLabs sounds best but costs the most, and it limits how many copied voices each plan keeps. Skyrim has dozens of voice types; when a plan's limit is reached, Mantella says so and the backup service speaks. Inworld's free voice copying makes it the better value of the two.

## Shortlist: what to support first

Three services cover every kind of player: one on this PC that leaves the graphics card to Skyrim, and two online, all copying game voices. Each needs its own file: Pocket TTS runs through Kyutai's own program, which Mantella downloads and starts for the player (Step 4 of the plan), and ElevenLabs and Inworld each copy voices their own way.

| Pick | Runs | Copies game voices? | How it plugs in | Why this one |
| --- | --- | --- | --- | --- |
| Pocket TTS | This PC, processor | Yes | Own file: Kyutai's own program, downloaded and started by Mantella; copying voices needs the player's Hugging Face sign-in | The best voice copier that leaves the graphics card to Skyrim |
| ElevenLabs | Online | Yes, each clip uploaded once | Own file | Ranked first in blind listening tests |
| Inworld | Online | Yes, free on every plan | Own file | Close to the top for a quarter of ElevenLabs' price |

Piper, XTTS and xVASynth stay as they are, with Piper as the backup voice.

Worth watching, not first: Chatterbox Turbo (copies voices well, English only, needs a graphics card), Qwen3-TTS (copies voices well, but needs 3 GB or more of graphics memory, which a modded Skyrim is already using), and Fish Audio Drama 3 and Breeze TTS 2 (top open models, too heavy to run next to Skyrim today).

My view: I agree with these three. All three wait on voice clips from the game, so those come first. Build order: Pocket TTS first, with clips from the game (see Making Pocket TTS plug and play), then ElevenLabs and Inworld.

## Pocket TTS in detail

Pocket TTS adds a fourth voice choice to Mantella, next to Piper, XTTS and xVASynth: a small voice program that copies a voice from a short sound clip and runs well without a graphics card. It is made by Kyutai.

What it gives the player:

- Natural voices on any PC. It runs on the processor (about 2 cores), so it leaves the graphics card to Skyrim. XTTS sounds good but wants a graphics card; Piper is light but flatter.
- Fast lines. Kyutai reports about 6 times faster than real time on a laptop. Mantella waits for each whole sentence before the game plays it, so what counts is how long a sentence takes to make: about half a second to a second for a typical 3-second sentence on an idle PC. (Kyutai's "0.2 seconds to the first sound" only applies to programs that play sound while it is still being made.)
- Voice copying. Give it 5–10 seconds of an NPC's real line from the game and that NPC speaks in that voice.
- No Python install. Kyutai ships a ready-made Windows program (pocket-tts.exe) that needs nothing else installed, like Piper today.

Limits to know:

- Languages: English, French, German, Portuguese, Italian, Spanish and Dutch. One language per run of the voice program.
- No Skyrim voices out of the box. It ships with about 25 generic voices (for example "alba", "george"). Skyrim-sounding NPCs need a clip from the game (see Making Pocket TTS plug and play).
- A sign-in for voice copying. Kyutai's download of the version that copies voices needs a free Hugging Face account that has accepted Kyutai's terms. Without it, Pocket TTS only has its built-in voices.
- Rules on copying voices. Kyutai's terms forbid copying a real person's voice without consent. Copying game voice types for personal play is the same grey area the XTTS voice pack is already in.

My view: the ready-made Windows program is what makes Pocket TTS a fit for Mantella: players who struggled to install XTTS can run it. One language per run is not a problem, because Mantella uses one language at a time anyway.

## Which program runs Pocket TTS

Decided: Kyutai's own program (pocket-tts.exe), running Kyutai's newest model from Kyutai's own download. Mantella downloads the program for the player; the program downloads the model, which needs the player's Hugging Face sign-in (see Making Pocket TTS plug and play).

Many programs can run Pocket TTS. The ones we looked at:

| Program | Model it runs | Windows download | How Mantella talks to it | Notes |
| --- | --- | --- | --- | --- |
| Kyutai's own program (our pick) | Kyutai's own, newest model on the day it comes out; all seven languages | 8 MB, one file | Its own request style: own file (Step 4) | Kyutai's own code and text rules; processor only |
| llama.cpp | A converted copy. You can convert Kyutai's newest model yourself, if llama.cpp already understands it; ready copies with no sign-in hold the April 2026 English model | 25 MB, new builds almost daily | OpenAI-style: a setup, no code | Can use the graphics card, and runs other voice models too; takes the clip itself with every request |
| audio.cpp | Its own converted copy, no sign-in: April 2026 English model, six languages (no Dutch) | 34 MB | OpenAI-style: a setup, no code | Can use the graphics card; takes a clip as a file on this PC; mostly one maker |
| sherpa-onnx, the copy AudioUtilTTS ships | A converted, shrunk January 2026 model, English only | – | No program Mantella can talk to | Would need new code inside Mantella |
| PocketTTS.cpp (VolgaGerm) | Only the January 2026 model; its converter breaks on newer ones | None, build it yourself | OpenAI-style | Abandoned since March 2026, with known noise bugs |
| pockettts.cpp | Converted copies up to September 2026 | None, build it yourself | OpenAI-style | One person's project |

Why Kyutai's program:

- How NPCs sound. Kyutai's newest English model (October 2026) is trained to cope with clips cut mid-word and with text that has no punctuation, both of which Mantella hits. Converted copies mostly hold the April model. The other programs are rewrites of Kyutai's code, so they can quietly sound different: missing Kyutai's text rules (such as swapping curly apostrophes for plain ones, which the model never heard in training) or using other default settings.
- New models work on the day they come out. A rewrite has to catch up first, and new Kyutai models have needed changes in those programs.
- Smallest: 8 MB, plus 219 MB per language.
- Speed: nothing published shows any program clearly faster on the processor; they all land around 3 to 6 times faster than real time.

What it costs:

- Processor only. A player whose processor can't keep up next to Skyrim has no graphics card fallback in the same program. llama.cpp covers that as a ready-made setup (Part 2), with Pocket TTS or a bigger voice model.
- Its own file instead of a setup with no code (Step 4).
- It won't take a clip as a file on this PC, only from a web address. Mantella turns each clip into a saved voice once and hands it over through its own small web address.
- It keeps only the last two voices ready. In a group conversation with three or more voice types, switching voices costs a little time.

Voice quality and file size: at full size, every program uses the same numbers for the same model, so the model version matters more than the program. Shrunk copies (about 128 MB instead of 219 MB per language) can change the sound slightly, which is not worth saving 90 MB.

My view: the costs are paid once (one file, the voice handover), while a rewrite costs a check of every new Kyutai model: does it load, does it sound right, does it follow the text rules. For a mod that will keep following Kyutai's newer models, Kyutai's own program is the better deal. If it is too slow next to Skyrim on a player's PC, llama.cpp on the graphics card is the fallback.

## Making Pocket TTS plug and play

Plug and play means: the player picks Pocket TTS under TTS Service and starts the game. No downloads by hand and no other settings; the one thing the player does is sign in to Hugging Face once, because we use Kyutai's own download. Every voice is copied from a clip the game hands Mantella while you play, the way SkyrimNet does it.

No training is needed. Pocket TTS copies a voice from one 5–10 second clip. Four things stand between a player and "pick Pocket TTS and Lydia sounds like Lydia": getting the program onto the PC, the sign-in that guards voice copying, a clip for every NPC, and the language.

### Is any training needed?

- Copying a Skyrim voice: no. Pocket TTS listens to the clip and speaks in that voice from the next line.
- The seven languages it ships with (English, French, German, Portuguese, Italian, Spanish, Dutch): no.
- Any other language: yes, a trained model. People have trained some (Japanese, Polish, Korean and others) and Pocket TTS can load them, but we haven't listened to any. Not in scope for now.
- Skyrim names said wrong: no. The list of words to say differently (Step 1 of the plan) fixes them.

### What stands in the way

| What | The problem | The fix |
| --- | --- | --- |
| The program | Kyutai ships a ready Windows program. Its licence lets us ship it. It needs a processor from about 2013 or later (AVX2); the version we use has no Windows build for older ones. | Mantella downloads Kyutai's program the first time you pick Pocket TTS, one fixed version, and checks the download. It starts the program itself. |
| A sign-in guards voice copying | Kyutai's own download of the version that copies voices only works after the player makes a Hugging Face account, accepts Kyutai's terms and gives the program a token. Without that, Pocket TTS only has its 25 built-in voices. | We keep Kyutai's own download. The TTS page explains the three steps (make an account, accept Kyutai's terms, save a token in HUGGINGFACE_SECRET_KEY.txt), and Mantella hands the token to Kyutai's program. Mantella checks the token before starting; without access, Pocket TTS still speaks with its built-in voices, and Mantella says why on the TTS page, in the log and once in game, so no one is left wondering why every NPC sounds generic. |
| A clip for every NPC | Without a clip, every NPC sounds generic. | The game hands Mantella one of the NPC's real lines the first time they speak (Step 3 of the plan). Nobody picks lines by hand, and mod voices and voice replacers are covered. |
| Language | Pocket TTS runs one language at a time, with a model per language. | Mantella starts Pocket TTS in the language from its Language setting, and the program downloads that language's model. The same game clip works for every language. |

Why Kyutai's own download: it is the model exactly as Kyutai publishes it, with nothing for us to host, check or keep up to date. The licence (CC BY 4.0) would allow sharing a copy, but Kyutai put the sign-in there on purpose, and one sign-in per player is a small cost.

Players don't get new models by themselves: each version of Kyutai's program points at fixed versions of the models. Mantella decides when the model changes, by updating the program version it downloads. That is what we want anyway: saved voices only work with the model they were made from, so on every model change Mantella makes them again from the saved clips.

### Steps

1. Mantella downloads Kyutai's Windows program the first time you pick Pocket TTS, one fixed version, and checks the download is complete.
2. The TTS page explains the Hugging Face sign-in, and Mantella hands the player's token to the program, which downloads Kyutai's model for the language. Without a working sign-in, Mantella says so clearly.
3. Mantella starts Pocket TTS itself when it is picked: in the language from the Language setting, on its own port, waits until it answers, and starts it again if it stops.
4. Clips from the game (Step 3 of the plan): the first time an NPC of a new voice type speaks, the game hands Mantella one of that voice type's lines and Pocket TTS turns it into a saved voice, once. Every NPC with that voice type then uses it. An NPC whose voice differs from the rest of their voice type, or one you choose, gets a clip of their own. Mantella hands saved voices to Pocket TTS through its own small web address, because Kyutai's program won't read them from a file.
5. Pick each NPC's voice in the shared order: a voice named for them in the character file, then their own clip if they have one, then their voice type's clip, then the one for their race and gender, then a built-in voice.
6. Clean up the sound in the shared clean-up: convert it to what the game plays, cut the silence at the start and end, make the lip file.
7. Fill Mantella's word list for Pocket TTS: Dovahkiin, Thu'um, Balgruuf and other Skyrim names, listening to each one (Step 1 of the plan).
8. Put Pocket TTS on the TTS page with the sign-in steps, a Test button, a credit to Kyutai, and Kyutai's rule against copying a real person's voice without consent.

My view: copying voices from the game, the way SkyrimNet does, solves the missing Skyrim voices with no list of lines for us to pick and keep up to date by hand. Mod voices and voice replacers work from the first day. The cost is that Pocket TTS now waits on Step 3: until clips from the game work, Pocket TTS NPCs only have built-in voices, so Pocket TTS ships together with Step 3. The sign-in is the one setup step left; the clear message when it is missing matters most here, because without it a player just hears generic voices. The clips are Bethesda's voice lines, the same grey area the XTTS voice pack is already in.

# Part 2: Making any voice service easy to add

The goal: any voice service that follows a common request style, such as OpenAI's, is added on the settings page with no code, and the ones we know come as ready-made setups. A service with its own way of talking needs one new file. Everything else is written once and shared by all of them, so every improvement reaches every service.

## Why it is hard today

Piper, XTTS and xVASynth were each added by hand, so adding Pocket TTS the same way means changing eight places:

1. The list of services on the TTS page.
2. The service's settings, and the code that reads them.
3. The check that its folder exists, done only when it is the one selected.
4. Two separate places that start the chosen service: once when Mantella starts, and again when you change settings mid-game.
5. The per-NPC tts_service column: the names it accepts, and the code that starts a second service for that NPC.
6. The tables that pick a voice from race and gender, kept separately for each service.
7. The order for choosing a voice, written again inside each service.
8. Starting the voice program and checking it is running, written again inside each service.

Miss one and the service half-works. Example: forget step 5, and pocket in Serana's tts_service column logs "Invalid TTS service" and she quietly speaks with the default service instead.

My view: this list is the strongest reason to do Step 1 before adding any new service. Every service added the old way makes the clean-up bigger, and a half-working service shows up as "my NPC has the wrong voice" with no error to point at.

## What each service file does

A service with its own way of talking (Piper, xVASynth, Kyutai's Pocket TTS server, ElevenLabs) gets one file that answers only the questions that differ between services:

| Question | Pocket TTS | An online service (ElevenLabs) |
| --- | --- | --- |
| What is it called, and which names work in the tts_service column? | Pocket TTS; pocket, pockettts | ElevenLabs; elevenlabs, 11labs |
| Does it run on this PC or online? | This PC | Online |
| Which settings does it need? | None: Mantella downloads and starts it | Key file, voice model |
| Is it ready, and how is it started? | Ask its address; start pocket-tts.exe if silent | Check the key works |
| How does an NPC get a voice? | Turns the NPC's game clip into a saved voice once, then hands it over through Mantella's own web address | Copies the clip once, then reuses the voice it made |
| Which languages can it speak? | English, French, German, Portuguese, Italian, Spanish, Dutch | Many |
| Turn this line, in this voice, into sound | Send it to its address | Send it to their website |

## What is shared by every service

Written once, so every new service gets it for free. Piper, XTTS and xVASynth stay as they are for now, with their own code, so they don't get these until they are moved over in a later change:

- Choosing the NPC's voice, in one order for all services: a voice named for the NPC in the character file, then the NPC's own clip if they have one, then their voice type's clip, then the clip of the voice type their race and gender point to (an Imperial man gets Male Even Toned), then a built-in male or female voice. One race and gender table replaces the separate table each service keeps today, so a fix reaches every service.
- Voice clips from the game, one per voice type plus one for each NPC whose voice differs or whom you choose, and turned into whatever each service wants (a sound file, a fast-loading voice file, or a voice made on an online service). Clips per voice type are the default because they take far less disk space, and a new NPC sounds right on their first line when someone with their voice type already has a clip. This helps every service that copies voices, not just Pocket TTS.
- The voice clips list on the TTS page: hear each clip and swap a bad one (Step 3 of the plan). The game picks clips automatically, and some picks will be bad (a shout, a combat grunt, a line with music under it); one bad clip makes every NPC with that voice type sound wrong, so fixing it must take one click.
- Cleaning up the sound: converting it to the kind of sound file the game plays, cutting the silence at the start and end (measured, keeping a few hundredths of a second so the first sound isn't clipped), then making the lip movement file. Many voice programs start each line with silence; cutting it makes replies start sooner and the lips match the sound better.
- Voice effects: sound changes such as pitch, echo and reverb, so draugr, ghosts, Dremora, werewolves and vampire lords sound right (Step 5 of the plan). Most creatures have no clean lines to copy a voice from, so effects are how they get their sound.
- The lists of words to say differently, per service and language, applied only to what is spoken, never to the subtitles or what NPCs remember: Mantella's list, your own list, and any shared list you add (Step 1 of the plan). Example: Pocket TTS says "Dovahkiin" wrong; you add Dovahkiin → Doh-vah-keen for Pocket TTS, and every NPC says it right from the next line. For Pocket TTS this is the only fix, because it reads text exactly as written.
- Waiting and failing well: time limits, one retry, then the Backup Voice Service (Piper by default), the same idea as the backup AI model Mantella already has. Example: you use ElevenLabs for everyone and your internet drops while Lydia is answering; Piper speaks that line, so her voice changes for one line instead of going silent.
- Choosing services: the TTS Service setting, the per-NPC column, and changing settings mid-game all read the same list of services.
- The settings page: each service's settings appear under its own name, without extra code.

## Two kinds of voice services

| Kind | Examples | How an NPC gets a voice |
| --- | --- | --- |
| Copies a voice from a clip | Pocket TTS, Chatterbox, Zonos, ElevenLabs | A clip taken from the game: one of their own lines, or one of their voice type's |
| Has trained Skyrim voices | Piper, xVASynth | A voice file named after the voice type |

The shared part treats each kind the same way, so a new service only says which kind it is. XTTS copies voices too, but the built-in XTTS option keeps its own voice pack until it is moved over; an XTTS server added as an XTTS-style setup uses clips from the game.

## Services that follow a common request style: no code

Many voice programs, on this PC and online, accept the same kind of request. Mantella learns each request style once. After that, any program or website that uses it is added by filling in a few boxes; nothing has to be built or released.

Two request styles from the start:

| Request style | What a request carries | Programs and websites that use it |
| --- | --- | --- |
| OpenAI-style | Text, a voice name and a model, sent to /v1/audio/speech, with a key if needed | llama.cpp and audio.cpp (both run Pocket TTS and other voice models, on the graphics card too), LocalAI, openedai-speech (which runs XTTS) |
| XTTS-style | Text, a voice clip name and a language, sent to /tts_to_audio | Mantella's XTTS server, CHIM's Pocket TTS add-on server, skyrimnet-pocket-tts, AudioUtilTTS, some Chatterbox servers |

If other programs later copy another request style, it is added the same way: once, in code, then every program using it needs no code.

### What you fill in for a new setup

| Box | Pocket TTS on the graphics card through llama.cpp |
| --- | --- |
| Name (shown in the TTS Service list and used in the per-NPC column) | Pocket TTS (graphics card) |
| Request style | OpenAI-style |
| Address | http://127.0.0.1:8080 |
| Key file | None |
| Model | tts |
| How NPCs get a voice | The clip itself, in the box speaker_ref_b64 |
| Languages | The language of the model file llama.cpp loaded |
| Extra settings sent with every request | None |
| Runs on this PC or online | This PC |

### How NPCs get a voice in a setup

Every setup copies voices. The setup names the box that carries the clip, and whether that box takes the clip's place on this PC or the clip itself; Mantella fills it with the clip for the NPC's voice type. Examples: audio.cpp takes the clip's place on this PC in a box called voice_ref; llama.cpp takes the clip itself, with every line, in a box called speaker_ref_b64.

### Where you add them

Setups are a list on the TTS page: add, edit, remove and test them with boxes and drop-downs, the same way model profiles work. Mistakes such as an empty address are caught as you type, and the list is saved to a file you can copy to another PC.

### Several setups side by side

You can keep as many setups as you like, even of the same request style. Example: Pocket TTS for most NPCs, and a Chatterbox server only for Serana, by putting Chatterbox in her tts_service column. Any setup can also be the backup service.

### Worked example: Pocket TTS on the graphics card through llama.cpp

For a player whose processor can't keep up with Pocket TTS next to Skyrim.

1. Start llama.cpp's server on this PC with a Pocket TTS model file. You start it yourself; Mantella only starts Kyutai's program.
2. On the TTS page, pick llama.cpp from the ready-made setups. It comes filled in: name Pocket TTS (graphics card), request style OpenAI-style, address http://127.0.0.1:8080, clip box speaker_ref_b64.
3. Press Test: it says a sample line as Male Nord, so you know it works before you play.
4. Pick Pocket TTS (graphics card) as the TTS Service, or put it in one NPC's tts_service column.

### Limits

Common request styles only agree on the basics: text in, sound out. Copying voices, listing voices and emotion words differ from program to program. The Extra settings box and the "which box carries the clip" setting cover most differences. A program that needs more than that gets its own service file.

Handing over the clip is one of those differences. A program on this PC can be given the clip's place on disk (audio.cpp takes it that way) or the clip itself with every line (llama.cpp). An online service can't read your disk and shouldn't get the clip with every line: it needs the clip uploaded once, which a setup can't describe, so online services that copy voices get their own file. XTTS-style programs differ in whether they take a place on disk or only a clip already in their own voices folder; a setup says which, in its clip setting.

My view: the OpenAI-style request style alone covers most programs on this PC, and gives players a graphics card route (llama.cpp) next to Pocket TTS on the processor. XTTS-style is worth adding only because Mantella already sends it, so it costs little. I would not add a third request style until a popular program needs one.

## Ready-made setups for services we know

Mantella ships a list of ready-made setups for the programs and websites it knows: llama.cpp to start, for Pocket TTS or another voice model on the graphics card. Each comes with its usual address, request style, model and the box that carries the clip. Adding one is a pick from the list, plus a key file for online ones. The list ships with Mantella and changes only with a Mantella update, so nothing goes online that you didn't set up; until an update adds a new service, you add it as your own setup. A ready-made setup is a few lines of data, so supporting the next good service means adding an entry, not writing code. The idea comes from CHIM, which builds its settings page from a list of services but still keeps a file for each of its 22; we go further and make most services just a list entry.

Example: you pick "llama.cpp" from the list and press Test.

## Mantella works out what is at an address

For a program that has no ready-made setup, you type its address and Mantella asks the program what it is, the way CHIM does: which request style it answers, and which box takes the voice clip. Mantella fills those boxes for you and you only type what it could not find out.

Example: you start audio.cpp and type http://127.0.0.1:8086. Mantella sees it answers OpenAI-style and takes the clip's place on this PC.

My view: ready-made setups matter more than the address check, because most players will pick from the list and never type an address. Build the address check for OpenAI-style programs first, which are most of them.

## What is different about online services

- A key file, like GPT_SECRET_KEY.txt for the AI model.
- Cost. They charge by the amount of text, and a long group conversation adds up. The TTS page marks which services are online.
- Copying a voice uploads a game clip to their website. Do it once per clip and remember the voice they made, instead of uploading it with every line. Since clips are per voice type, with only a few NPCs of their own, a playthrough needs dozens of copied voices, not hundreds. If a service's plan limit is reached, Mantella says so and the backup service speaks.
- They fail when the internet does, so the backup service matters more.
- The sound comes back in other formats (often mp3). The shared clean-up turns it into the sound file the game plays.

My view: cost should be shown, not just marked. A line next to each online setup such as "about $0.05 per 30-line conversation", worked out from the price the setup carries, would prevent surprises in long group scenes where many NPCs speak.

*[Drawing: shared voice layer. The original shows 6 service files between two shared steps; it needs redrawing with 3.]*

A service with its own way of talking adds one box to the middle row. One that follows a common request style is just another setup in the "Your setups" box, with no code. The shaded rows above and below are written once and reached by every service.

# What we learned from SkyrimNet and CHIM

SkyrimNet (its feature list) and CHIM (its server, HerikaServer) are AI NPC mods for Skyrim that already support Pocket TTS and many other voice services. They teach us something for both parts: their service lists back most of our shortlist (Part 1), and the way they plug services in shapes Part 2.

## What they are

| | SkyrimNet | CHIM (HerikaServer) |
| --- | --- | --- |
| How it runs | Entirely inside the game, as one SKSE plugin | A separate server program the game talks to, like Mantella; runs on Linux (DwemerDistro) |
| What we could read | Its feature list only; the main code isn't public | Its Pocket TTS code, voice clip code and service list |
| Voice services | 9: Pocket TTS (the default), XTTS, Zonos, Chatterbox, Higgs, OpenAI-style, ElevenLabs, Inworld, Fateless | 22, one file each, including Pocket TTS, XTTS, Chatterbox, Piper, xVASynth, Kokoro, ElevenLabs, Azure, OpenAI |
| Where voice clips come from | The game, per NPC | The game, per voice type |

## For Part 1: which services they support

All three of our picks are in both lists.

| Our pick | SkyrimNet | CHIM |
| --- | --- | --- |
| Pocket TTS | Yes, the default | Yes |
| ElevenLabs | Yes | Yes |
| Inworld | Yes | Yes |

Both lists are complete: SkyrimNet's 9 from its feature list, CHIM's 22 from the files in its tts folder.

What this tells us:

- Pocket TTS is the local pick in both, and SkyrimNet's default. It belongs first for players without graphics memory to spare.
- For copying voices online, both chose ElevenLabs and Inworld: the same two that get their own file in our shortlist.
- Both offer a general OpenAI-style service next to the named ones, which is what our no-code setups do.
- Both also support Chatterbox and Zonos. SkyrimNet adds Higgs Audio and Fateless; CHIM adds Cartesia, Azure, Google, Deepgram, MeloTTS, StyleTTS 2 and a few others. We have not checked Zonos or Fateless.
- SkyrimNet can rent a graphics card for XTTS. That is a third way to run voices, between this PC and an online service, and could reach the heavy open models (Fish Audio Drama 3, Breeze TTS 2). We skip it (Lesson 10).
- CHIM reaches 22 services by adding each one by hand. Players clearly want that breadth; its cost is what Part 2 avoids.

My view: their lists are a useful check, not a guide: a mod keeps a service it has supported for a year whether or not something better came along. They agree with all three of our picks (Pocket TTS on this PC, ElevenLabs and Inworld online), so I am confident in them. CHIM's 22 services tell me players want many choices; that argues for Part 2, not for us writing 22 files.

## For Part 2: how they plug services in

Their biggest lesson: take each voice clip straight from the game. Eight more ideas are worth taking now or later, and four are not. The table rates each one; a My view note under each lesson explains the rating.

| Lesson | What it gives us | Importance | Recommend | When |
| --- | --- | --- | --- | --- |
| 1. Voice clips from the game | Skyrim voices for every service that copies voices, mod and unique voices included | High | Yes | Step 3 |
| 2. One stand-in order | The same voice choice for every service, one copy of the code | Medium | Yes | Step 1 |
| 3. Cut the silence | Replies start sooner and lips match | Medium | Yes | Step 1 |
| 4. Several programs, one request style | Proof that coding request styles beats coding programs | High | Yes | Step 2 |
| 5. Services as data | The backbone of Part 2 | High | Yes | Steps 1–2 |
| 6. No setup | Good voices for players who never open the settings | High | Yes, for Pocket TTS (apart from the sign-in) | Step 4 |
| 7. Fix how words are said | Skyrim's names said right | Medium | Yes | Step 1 |
| 8. One key for words and voices | Online voices with no new account | Low | No | — |
| 9. Hear and swap voice clips | A bad automatic clip fixed in one click | Medium | Yes | Step 3 |
| 10. Voice effects | Draugr, ghosts and Dremora sound right | Medium | Yes | Step 5 |
| 10. Emotion words | More expressive lines on services that understand them | Medium | Yes, for Inworld | Step 8 |
| 10. Renting a graphics card | Heavy open models without a big card | Low | No | — |

### Lesson 1: Get voice clips from the game itself

How CHIM does it:

1. Lydia speaks for the first time and has no voice yet.
2. CHIM tells the game: "send me a voice line for Lydia". If nothing comes back, it asks again after 5 minutes at the earliest.
3. The game add-on picks one of Lydia's real voice lines from the game's files and sends it, together with its subtitle text.
4. CHIM converts it to a plain sound file and saves it under the voice type's name: femaleeventoned.wav. Every NPC with that voice type now uses it.
5. Until the clip arrives, Lydia speaks with a stand-in voice (Lesson 2).

SkyrimNet does the same from inside the game, but per NPC rather than per voice type: it "clones each NPC's voice from a sample", and its settings have a Voice Samples page. SkyrimNet confirmed it keeps no list of chosen lines (its repo holds only two clips, for creatures with no voice lines: a flame atronach and a skeleton). It reads every line the NPC can speak from the game files, drops lines whose subtitle contains certain words (songs, for example), and picks one of suitable length, while you play.

We pick lines much as SkyrimNet does (by length, leaving out songs), but find them by their file names (Step 3), and keep clips per voice type by default, as CHIM does: one clip per voice type, plus a clip of their own for NPCs whose voice differs from the rest of their voice type, and for any NPC you choose (see Mods with their own voices). Clips per voice type take far less disk space, and a new NPC sounds right on their first line when someone with their voice type already has a clip.

Why this beats a one-time clip script:

- Voice types added by mods are covered. A follower mod's own voice type works the first time that follower speaks.
- Unique voices are covered. Serana has her own voice type, so she sounds like Serana, not like Female Young Eager.
- It sees the same files the game sees, including mods in Mod Organizer 2's virtual folder, which programs outside the game can't see.
- Nothing to run by hand.

For Mantella: a new DLL in the game add-on, MantellaVoiceClips.dll, runs inside the game, so it can find and copy the line. Mantella then converts the game's sound format (.fuz) into a plain sound file, which needs a converter Mantella doesn't have today. This helps every service that copies voices (Chatterbox, ElevenLabs, an XTTS server added as a setup), not just Pocket TTS, so it belongs in the shared part.

We checked whether Mantella's XTTS download could give a head start: it can't. It keeps XTTS's own stored voice data (637 .json files for English, such as malenord.json), not sound clips, and other voice programs can't read it.

My view: the most valuable lesson here, and the riskiest piece of work. All three picks copy voices, and without clips they all sound generic; Pocket TTS has no other way to get Skyrim voices. The hard part is in the new MantellaVoiceClips.dll: finding a line of the right NPC or voice type that really has a sound file, and reading it from the game's packed files. I would start the DLL work early, alongside Step 1.

#### Mods with their own voices

Because the game add-on reads voice files the way the game does, most voice mods just work:

| What the mod does | Example | Covered? |
| --- | --- | --- |
| Adds a new voice type with its own recorded lines | A fully voiced follower such as Inigo or Lucien | Yes. Its lines sit under the mod's own plugin name, not Skyrim.esm, so the add-on looks in every plugin. |
| Replaces the base game's recordings | A new voice for Lydia, a remastered Serana, a German or Japanese voice pack | Yes. The add-on gets whichever file wins in your load order, the one you hear in game. |
| Gives an NPC a different existing voice type | Mods that spread vanilla voice types around so NPCs sound less alike | Yes. Mantella already reads the NPC's current voice type from the game. |
| Gives an NPC a new voice type with no recordings | Unvoiced followers | No clip exists. The NPC uses the clip for their race and gender (an Imperial man gets the Male Even Toned clip, the way Mantella already picks Piper and XTTS voices for unknown voice types), then a built-in male or female voice if that is missing too, or a clip you add (Lesson 9). |

Three things the game add-on and Mantella must do for this to hold:

- One clip per voice type, with a clip of their own for NPCs whose voice differs. Some mods replace only Lydia's own lines and leave the shared Female Even Toned lines alone. If the Female Even Toned clip came from her new lines, every Female Even Toned NPC would sound like the new Lydia; if it came from the shared lines, Lydia would lose her new voice. So:
  - A voice type's clip is always taken from its shared lines, the ones any NPC with that voice type can speak.
  - An NPC gets a clip of their own automatically when their own lines (lines only they speak) come from a different place than their voice type's shared lines (a loose file versus an archive, or different archives). The game add-on can tell those apart; it can't tell two loose voice mods apart under Mod Organizer 2.
  - You can give any NPC a clip of their own from the voice clips list (Lesson 9).
  - NPCs with a voice type of their own, such as Serana, need nothing special: their voice type's clip is already theirs.
- Notice when a clip is out of date. If you install a voice replacer after a clip was saved, you would keep the old voice. Mantella remembers which game line each clip came from and copies that line again when its file changes, so the NPC keeps the same line in the new voice. Only if the line is gone does Mantella pick another.
- Read every sound format. The base game packs voice lines as .fuz files; mods also use .xwm and plain .wav files.

### Lesson 2: One stand-in order for every service

CHIM picks a voice the same way for all of its services: the NPC's own voice, then a voice from an editable race and gender table (Nord → malenord / femalenord; Imperial and Breton → maleeventoned / femaleeventoned), then the service's default male or female voice. Mantella already has race and gender tables, but one copy per service. This is the shared voice choice in the section above.

My view: useful but not exciting. Mantella already picks voices in this order; the gain is one copy instead of one per service, so a fix reaches all of them. Cheap, and it comes with Step 1.

### Lesson 3: Cut the silence at the start of each line

CHIM cuts the first 250 ms (a quarter of a second) off every Pocket TTS line, because the voice program starts each line with silence. Replies start sooner and the lips match the sound better. In Mantella this goes in the shared clean-up, measuring the actual silence instead of cutting a fixed amount, so every service benefits.

My view: small effort, noticeable result: a quarter of a second before every line adds up over a conversation. Two changes to CHIM's version: measure the silence instead of cutting a fixed 250 ms, and leave a few hundredths of a second so the first sound isn't clipped. Trimming the silence at the end too would close the gaps between sentences.

### Lesson 4: More than one program can run Pocket TTS

CHIM never talks to Kyutai's own server. It supports two others:

- audio.cpp, a C++ program that runs Pocket TTS and many other voice models. It takes OpenAI-style requests and accepts a voice clip as a plain file path on this PC, which Kyutai's server refuses. It ships ready Windows builds.
- A Python add-on server that answers like XTTS (text, a voice name and a language), so XTTS-style code works with it.

Two more programs do the same for SkyrimNet, both answering XTTS-style requests so a mod that already talks to XTTS can use Pocket TTS without changes:

- AudioUtilTTS, a game add-on that runs a converted copy of Pocket TTS inside the game, with voice copying and no sign-in.
- skyrimnet-pocket-tts, a small Python program by one person. We won't use it: it needs Python and PyTorch installed, the player has to download the model by hand, it only speaks English, it fails with an error when an NPC's voice has no clip instead of using a stand-in, it has no licence, and Mantella's XTTS option can't use it as it is because it can't list its voices. Two ideas from it are worth knowing: a program can send a clip once and the server keeps the voice, which is what Step 3 needs; and it moves itself onto the processor's fast cores, which we leave out, since Skyrim wants those cores too.

CHIM also works out which of its two programs is at the address by asking it, and tries its other usual ports if the set one is silent. For Mantella, the two shared request styles (OpenAI-style and XTTS-style) turn the choice of program into a setting, not new code, and asking an address what it is becomes Mantella's address check (Part 2).

My view: important less for Pocket TTS than for what it proves: one program can speak another's request style, so we should write code for request styles, not for programs. For Pocket TTS itself we still chose Kyutai's own program, with its own file, for how NPCs sound and to get new models on the day they come out (see Which program runs Pocket TTS).


### Lesson 5: Describe each service as data

CHIM keeps one list entry per service: its name, which setting holds the voice, its usual address, its default settings, whether it needs a key, and whether it can switch language. Its settings page is built from that list. You can also save several setups, for example "Pocket TTS on this PC" and "XTTS on a rented graphics card", and pick one per profile. This is the model for three parts of Part 2: one file per service, your own setups, and ready-made setups that carry each service's usual address and settings.

My view: the most important lesson for Part 2. CHIM went half way: its settings page is built from a list, but it still has a file per service, 22 of them. We should go further: request styles and ready-made setups make most services a list entry, and only services with their own way of talking get a file.

### Lesson 6: No setup is the bar

SkyrimNet runs Pocket TTS inside the game and makes it the default voice. It downloads the voice model on first launch, with voice copying and no sign-in, and checks every downloaded file, so a half-finished download is never used. Mantella is a separate program and can't do exactly that. The closest is Mantella downloading and starting the voice program by itself and checking its download, so picking Pocket TTS just works. Unlike SkyrimNet, we keep Kyutai's own model download, so voice copying needs the player's Hugging Face sign-in once.

My view: the biggest lever for how many players actually hear a better voice, since most never open the settings. Shipping or downloading a program means hosting it, checking its licence and keeping it up to date, so do it for one program first: Kyutai's Pocket TTS program (see Making Pocket TTS plug and play).

### Lesson 7: Fix how words are said

CHIM keeps a list of words a voice program says wrong, each with a spelling it says right ("don't" → "donth" for MeloTTS), applied just before the line is sent, for English only. In Mantella this would be a shared list, per service and language, that you can edit.

Pocket TTS has no other way to fix a word: it reads the text as written, with no pronunciation dictionary or phonetic spelling. So for Pocket TTS, changing the spelling is the only fix.

Example: Pocket TTS says "Dovahkiin" wrong. You add Dovahkiin → Doh-vah-keen for Pocket TTS, and every NPC says it right from the next line.

#### Word lists: one from us, one of your own

- Mantella's list. We ship a word list with Mantella covering Skyrim's names and words (Dovahkiin, Thu'um, Balgruuf, Ysgramor and so on), for each service and language we support. A Mantella update replaces it with the newest version.
- Your list. A separate file you edit to add words or change ours. Updates never touch it. When both lists have the same word, yours wins.
- Lists from others. Any other word list put in the same folder is read too, so someone can share a list for a mod's names (for example a follower mod's place and character names) and you just drop it in.
- Each entry says which service and language it applies to, or leaves them blank to apply everywhere.
- An entry is either a spelling (Doh-vah-keen) or sound symbols, the phonetic alphabet dictionaries use (/ˈdoʊvɑːkiːn/). Sound symbols say exactly how a word sounds, stress included, but only some online services accept them (Inworld, Mistral and Cartesia; ElevenLabs is treated as not accepting them until we know it does). Each service says whether it accepts them; a service that doesn't uses the spelling entry for that word instead, so a word can have both.
- Changes apply from the next line; no restart needed.

Example: you play with a mod that adds a follower named Auri. Pocket TTS says "Ow-ree" and you want "Or-ee". You add Auri → Or-ee to your list. A later Mantella update adds more Skyrim names to Mantella's list, and your Auri entry stays as it is.

#### Hear a word before you play

The TTS page shows every word from all the lists, with the file each one comes from, and a play button next to each.

- Play speaks a short line with the word in it, through the voice service and voice you pick (any NPC whose clip you have). A second button plays the same line with the word as normally written, so you can compare.
- A box at the top lets you try a new word: type the word and a spelling, press play, change the spelling until it sounds right, then press Add to my list. That writes it to your list, so you never have to open the file.
- You can still edit the files by hand; the page shows the change the next time it is opened.

Example: you type Auri and Or-ee, press play and hear Lydia say "Have you seen Or-ee?". It sounds right, so you press Add to my list.

My view: cheap and worth doing in Step 1. Skyrim's made-up names (Dovahkiin, Thu'um, Balgruuf) are exactly what general-purpose voices get wrong, and today the only fix is to switch voice program. The list must change only what is spoken, never the subtitles or what the NPCs remember.

### Lesson 8: One key for words and voices

SkyrimNet offers Fateless, one account that covers the AI model, voices, speech recognition and bard songs: one sign-up, one bill.

My view: not now. The obvious route for Mantella is OpenRouter, which many players already use for the AI model, but it only offers ready voices, so it can't make Lydia sound like Lydia.

### Lesson 9: Hear and swap voice clips

SkyrimNet has a Voice Samples page in its settings, where the clips it copies voices from are managed.

My view: needed as soon as the game picks clips automatically. Some picks will be bad: a shout, a combat grunt, a line with music under it, and then every NPC with that voice type sounds wrong. A list of voice types and NPCs with a clip of their own on the TTS page, each with a play button and "pick another line", fixes that in a click. Do it with Step 3. There is no "use my own clip": an NPC with no recordings already speaks with the voice type in their character file, or their race and gender's, and nobody needs a voice from outside the game.

What the list does:

- Pick another line remembers the lines you turned down, so pressing it again never brings one back.
- Hear before you choose: pick another line offers three or four of the game's lines to listen to, and only the one you choose becomes the voice.
- Hear it speak: a sentence in the voice the TTS Service makes from the clip (the same voice NPCs use, so one made in game is reused), or from a line in the list before it is chosen (kept under a name of its own, so the clip's voice is never thrown away). No game needed.
- A line is one INFO to Mantella, though the game may split it into numbered files (_1, _2). Each line is listed once, and never another file of the clip's own line: picking that would turn down the line the clip then uses.
- Swapping a voice type's clip changes every NPC with that voice type; one swap fixes them all.
- Give this NPC their own clip. Example: you dislike how Ysolda sounds, but the other Female Young Eager NPCs are fine. You give Ysolda her own clip and pick another line for her; everyone else keeps the shared clip. Removing her own clip puts her back on the shared one.
- After a swap, the old voice is thrown away and the NPC's next line uses the new clip.
- Share your picks. Export picks saves a small file listing which game line each voice type and each NPC with a clip of their own uses, and the lines you turned down. It holds no sound, so no one's recordings change hands. Import picks reads someone else's file: each player's Mantella copies the lines from their own game files, so voice replacers still apply, and NPCs or lines they don't have are picked as usual. When the file and your own picks disagree, Mantella asks whether to keep yours or take theirs. Clips you added yourself are not included.

Example: a friend spent an evening swapping bad lines for 40 voice types and giving 10 NPCs their own clip. They export their picks and send you the file. You import it, and your game uses the same lines, in the voices of your own voice mods.

### Lesson 10: Voice effects, emotion words, and an idea we skip

- Voice effects (SkyrimNet): per-NPC sound changes such as pitch, echo and reverb, with ready-made recipes for werewolves, vampire lords, draugr, Dremora and ghosts, and a preview. This fits the shared clean-up, so every service gets it. We take it (Step 5).
- Emotion words (SkyrimNet): words like "sarcastically" or "menacing" are passed to services that understand them (ElevenLabs, Inworld). At first we skipped it, because every other service would read "sarcastically" out loud. We take it after all (Step 8): Mantella takes the words out of the line before anything else sees it, so only the service that understands them gets them.
- Renting a graphics card (SkyrimNet): rents a cloud computer for XTTS when this PC can't run it. We skip it: it needs an account, billing and minutes of start-up, and online services already serve players without a big card.

My view: voice effects are cheap once the shared clean-up exists, and they work with every service, including Pocket TTS. A draugr that sounds like a draugr is exactly the kind of thing copying a voice from a clip can't give you, because most creatures have no clean lines to copy.

### Not worth copying

- Reusing sound made earlier for the same text (CHIM). NPC lines in Mantella almost never repeat word for word.
- Searching other ports when the voice program is silent (CHIM). Mantella either starts the program itself or has its address in the setup.
- Turning numbers into Japanese characters before speaking (CHIM). Pocket TTS doesn't speak Japanese.

Already in Mantella, so nothing to take: voicing each sentence as soon as it is written (SkyrimNet starts speaking the first sentence while the AI writes the second), never making the game wait on a voice, and speaking the player's own lines in a chosen voice (Voice Player Input).

# The plan

Thirteen steps, each usable on its own. Steps 1 to 4 build Part 2, Step 5 adds voice effects, starting with what reaches the most services for the least work: the shared part, then request styles. Pocket TTS, our pick for this PC, comes with Step 3 (Skyrim voices from the game) and Step 4 (its own file, with Mantella downloading and starting Kyutai's program).

## Step 1: Build the shared part

- [ ] One list of voice services that the TTS Service setting, the per-NPC tts_service column and mid-game setting changes all read.
- [ ] One order for choosing an NPC's voice, used by every service.
- [ ] One race and gender table (for example Imperial man → Male Even Toned) in place of each service's own tables.
- [ ] One shared clean-up: convert the sound to what the game plays, cut the silence at the start and end (measured, not a fixed amount, keeping a few hundredths of a second), then make the lip movement file.
- [ ] Time limits, one retry, and a Backup Voice Service setting (Piper by default) that speaks the line when the chosen service fails.
- [ ] Each service gets a folded part of its own on the TTS page, named after it, with its settings (or, for Pocket TTS and the online services, its sign-in or key).
- [ ] Try A Voice on the TTS page: pick any service and a voice type, type a test sentence and press Hear it. No service needs a test button of its own; the setups list and Fix Pronunciation use the same way of speaking a line.
- [ ] Piper, XTTS and xVASynth stay untouched for now: they keep working exactly as today, and the new services are added next to them.
- [ ] Lists of words to say differently, per service and language, that change only what is spoken, never the subtitles or what NPCs remember: Mantella's list, shipped and replaced on update; your own list, which updates never touch and which wins over ours; and any other list put in the same folder, so someone can share a list for a mod's names.
- [ ] Mantella's list covers Skyrim's names and words (Dovahkiin, Thu'um, Balgruuf, Ysgramor and so on) for each service and language we support, starting with Pocket TTS, listening to each one.
- [ ] Each entry names the service and language it applies to, or leaves them blank to apply everywhere.
- [ ] An entry is a spelling (Doh-vah-keen) or sound symbols (/ˈdoʊvɑːkiːn/). Each service says whether it accepts sound symbols; one that doesn't uses the spelling entry for that word instead, so a word can have both.
- [ ] Changes apply from the next line, with no restart.
- [ ] Fix Pronunciation on the TTS page: every word from all the lists, with the file it comes from. Pick one, or type a new word, and press Hear it fixed or Hear it unfixed to compare, through the service and voice type you pick; Add to my list saves it, so you never have to open the file. Reload the lists shows changes made by hand.

## Step 2: Request styles, with no code

- [ ] OpenAI-style requests: text, voice, model and key in; the sound that comes back goes through the shared clean-up.
- [ ] XTTS-style requests, reusing what Mantella's XTTS code already sends.
- [ ] Your setups as a list on the TTS page (Voice Setups): add, edit, remove and hear them (Hear it) with boxes and drop-downs, the same way model profiles work. Mistakes such as an empty address are caught as you type. Saved to a file you can copy to another PC.
- [ ] Each setup's name appears in the TTS Service list, works in the per-NPC tts_service column and can be the backup service.
- [ ] Voice clips for setups that copy voices: the setup names the box that carries the clip, and whether it takes the clip's place on this PC or the clip itself.
- [ ] Ready-made setups for the programs and websites we know, so most players only pick one from a list. The list ships with Mantella and changes only with an update.
- [ ] The address check: Mantella asks a new address what it is and fills in the request style.
- [ ] First ready-made setup: llama.cpp, for Pocket TTS or another voice model on the graphics card.

## Step 3: Voice clips from the game

- [ ] When an NPC joins a conversation and neither they nor their voice type has a clip yet, Mantella asks the game for one, with its answer to the request they joined with. The game copies the lines while the AI writes. If nothing comes back, it asks again no sooner than 5 minutes later. Only the people in the conversation, never people nearby: the cost is that an NPC in a group who never speaks still gets their lines copied.
- [ ] A new DLL in the game add-on, MantellaVoiceClips.dll, shipped next to MantellaQuestChecks.dll, finds lines by their file names. Every voice line is a file in a folder named after its mod and voice type (for example Skyrim.esm/FemaleEvenToned), and the file name says which line it is. The add-on lists those folders for every mod, in the game's archives and as loose files, then reads the chosen file the way the game does. So the file you hear in game (a voice replacer's, if you have one) is the one copied, and Mod Organizer 2's virtual folder is seen. It copies the line where Mantella can read it.
- [ ] Why this happens inside the game: Papyrus scripts can't list or read files; a program outside the game can't see Mod Organizer 2's virtual folder and would have to rebuild the game's rules for which file wins; and only the game knows which lines belong to a single NPC. The voice clip work gets a DLL of its own rather than growing MantellaQuestChecks.dll, which answers quest checks; it is built the same way, as one DLL for Skyrim Special Edition, Anniversary Edition and VR.
- [ ] One clip per voice type, taken from its shared lines (the ones any NPC with that voice type can speak). Every NPC with that voice type uses it.
- [ ] An NPC gets a clip of their own, taken from lines only they speak, when those lines come from a different place than their voice type's shared lines: one is a loose file and the other is in an archive, or they are in different archives. Two loose voice mods look the same to the game under Mod Organizer 2, so in that case the NPC keeps the shared clip until you give them their own from the list. Only the lines that came with the game count: mods that add new lines for an NPC (follower dialogue, comments) don't change their voice, so they don't give the NPC a clip of their own. Example: a mod re-voices only Lydia's own lines. Taking the Female Even Toned clip from her new lines would make every Female Even Toned NPC sound like the new Lydia; taking only the shared lines would lose her new voice. So the voice type's clip comes from the shared lines and Lydia gets her own. NPCs with a voice type of their own, such as Serana, need nothing special.
- [ ] An NPC whose voice type has no recordings at all (for example an unvoiced follower) uses the clip of the voice type their race and gender point to, then a built-in voice, until you give them a clip of your own.
- [ ] Picking a line, much as SkyrimNet does: take every line that can be used, drop lines whose file name contains a word from a small list you can edit (starting with bardsongs, which every bard song's file name starts with), and pick one of 5–10 seconds, read from the file's header. Short combat sounds, shouts and grunts fall out on length; anything else that slips through goes on the word list. There are plenty to choose from: in the game's own voice archive, 957 Female Even Toned lines are 5–10 seconds long, and even Male Khajiit has 239.
- [ ] Mantella converts it to a plain sound file (from .fuz, .xwm or .wav), saves it in a voice clips folder and turns it into what each service needs. Mantella has no converter for the game's sound format today, so one ships with it.
- [ ] Works in Skyrim VR as well as Skyrim Special Edition, since Skyrim VR is Mantella's default game.
- [ ] Mantella remembers which game line each clip came from and copies it again when its file changes, for example after you install a voice replacer. It picks another line only if that line is gone. Only clips Mantella copied count: a sound file put in the folder by hand is left alone.
- [ ] A new voice's first line waits up to 10 seconds for clips already on their way to the game, so it is in the NPC's own voice. Each request holds up one line at most, and a line never waits for clips that would only go out with its own answer (an NPC who joins with the request their first line answers). No wait without MantellaVoiceClips.dll, which the game shows by sending where each NPC comes from.
- [ ] Their voice is made as soon as the clips arrive, not when their first line needs it: by Pocket TTS and voice setups for everyone in the conversation, by online services only in a one-on-one conversation, so no voice slots go to people in a group who never speak.
- [ ] Otherwise the NPC speaks with a stand-in until the clip is ready (their voice type's clip while their own is being made, otherwise the voice type in their character file, then their race and gender's). When the game has no lines for their voice type (an unvoiced follower), Mantella asks for the next of those at once, with the reply to that answer; their next line uses the new clip.
- [ ] The narrator (when Narration Handling uses a narrator) speaks with the voice in the Narrator Voice setting, as today. With a service that copies voices, that setting names a voice type, and the narrator uses that voice type's clip.
- [ ] Voice Clips on the TTS page. Change a voice: pick a voice type, or an NPC with a voice of their own, to hear the clip it's cloned from; pick one of the other clips you can clone from, press Hear the cloned voice, and Clone from this clip if you like it. Find more clips brings 4 more the next time you talk to someone in game.
- [ ] **Prepare all voices** on the TTS page gets the clip of every voice type the game's people use (not creatures such as dragons or draugr) and makes its voice, so nobody starts with a stand-in. It works one voice at a time at low priority while you play (about 5 seconds each with Pocket TTS), most used voice types first, and only when you press it: doing this by itself, or for everyone nearby, would make the game heavier. Voices are made only for services on this PC; an online service would spend your money or voice slots. With only online services in use, the page says Prepare all voices is for Pocket TTS and setups on your PC, and the game isn't asked for any clips.
- [ ] Give an NPC their own voice, and Go back to their voice type's voice. Example: you dislike how Ysolda sounds but the other Female Young Eager NPCs are fine; you give Ysolda her own voice and clone it from another clip. Going back puts her on the shared voice again. Give this NPC's voice to their whole voice type does the opposite.
- [ ] The other clips you can clone from are heard first, and only the one you clone from becomes the voice. A clip you swapped away goes back in the list; a removed one comes back only with Bring back removed clips.
- [ ] Swapping a voice type's clip changes every NPC with that voice type. After any swap the old voice is thrown away and the NPC's next line uses the new clip.
- [ ] Share voices with a friend, on the TTS page: Save my voices to a file writes which line each voice type and NPC is cloned from, and the clips removed, with no sound in the file. Load their voices: each player's Mantella copies the lines from their own game files, so voice replacers still apply; NPCs or lines you don't have are picked as usual. For voices you both have, you choose Keep mine or Use theirs. Clips you added yourself are not saved to the file.

## Step 4: Own files for what request styles can't do

- [ ] ElevenLabs: upload each game clip once, keep the voice it makes, then speak with it.
- [ ] Inworld: the same, through its own request style.
- [ ] Pocket TTS through Kyutai's own program: the first time you pick it, Mantella downloads the program, one fixed version, checked after download. The program downloads Kyutai's model for the language in Mantella's Language setting from Kyutai's own download, with the token the player saved after signing in to Hugging Face and accepting Kyutai's terms (HUGGINGFACE_SECRET_KEY.txt).
- [ ] Mantella checks the token before starting. Without access, Pocket TTS speaks with its built-in voices and Mantella says why: on the TTS page, in the log and once in game.
- [ ] Mantella starts the program itself, in that language, on its own port, waits until it answers and starts it again if it stops.
- [ ] Each game clip is turned into a saved voice once and handed to the program through Mantella's own small web address. Saved voices are made again from the saved clips whenever the model changes (a Mantella update or a new language).
- [ ] Credit Kyutai on the TTS page and show their rule against copying a real person's voice without consent.
- [ ] Pocket TTS ships together with Step 3, since without game clips it only has built-in voices.
- [ ] ElevenLabs and Inworld each get a folded part of their own on the TTS page, like Pocket TTS: one sentence on what it is and what it costs, how to turn on voice cloning, a box to paste the key, Save key and Check my key. The key is never shown again. Both are in Try A Voice, so neither has a test button of its own.
- [ ] Voice Clips works the same with an online service. Hear the cloned voice on a clip you're trying clones it on the service once, and Mantella deletes that voice again when you pick another one, so trying clips never uses up your plan's voices. Clone from this clip keeps it instead of cloning again; Go back to their voice type's voice deletes the NPC's voice on the service.

## Step 5: Voice effects

- [ ] Sound changes such as pitch, echo, reverb and distortion, added in the shared clean-up so every new voice service gets them (Piper, XTTS and xVASynth once they are moved over).
- [ ] Ready-made effects for werewolves, vampire lords, draugr, Dremora and ghosts. Every effect is off until the player ticks it (changed on 2026-11-19: they used to apply to everyone, and most players never open the section).
- [ ] Every effect is the same sliders: Strength, then Deeper or higher, Echo, Space, Doubled voice, Muffled, Thin, Growl and Waver (folded under Fine-tune). Players change Mantella's or save their own; nothing is hard-coded.
- [ ] Mantella picks a ticked effect from what the NPC is (for example a draugr or a ghost), and you can set one for a single NPC in the Bio Editor or the character file. An effect that isn't ticked is off for everyone, including a single NPC's pick. Race covers draugr, Dremora, werewolves and vampire lords; ghosts share their race with the living, so the game add-on tells Mantella when an NPC is a ghost.
- [ ] Voice Effects on the TTS page: Effects in use (a tick box each), then Change an effect: who gets it, Strength, Fine-tune, Hear it with the effect or Hear it without (as set on the page, saved or not), Save changes, Undo my changes, Delete this effect and Save as a new effect.
- [ ] Volume, one for each service on the TTS page (Pocket TTS, ElevenLabs, Inworld, HeyGen, Qwen, Boson AI, and each of your setups): every line is first made as loud as Skyrim's own lines, then the service's Volume makes NPCs louder or quieter (100% is like the game). It comes last, after the effect, because echo and reverb change how loud a line is, and loud lines are kept from crackling. Measured on 2026-11-17, Pocket TTS lines were already within about 1 dB of the game's.

Not doing: renting a graphics card (needs an account, billing and minutes of start-up, and online services already serve players without a big card).

## Step 6: Write it up and test

- [ ] A Voice Services section in FEATURES_README (What it does, then Where to find it), covering the shortlisted services, your own setups, voice clips from the game, the word lists, voice effects, Voice Volume and the backup service, with each part of the TTS page and its buttons named as the page shows them.
- [ ] A note in FEATURES_README of what changed (neither repo has a changelog).
- [ ] Tests for the list of services, both request styles, the address check, the voice order, the clean-up, the word lists, picking a clip line, voice effects and the backup service.
- [ ] In-game test: a group conversation with a Nord, a Khajiit and Serana on a service on this PC, then Serana switched to an online service in the per-NPC column, and a conversation with a draugr to hear its voice effect.

My view: build it in four parts: Steps 1 and 2 together; then Step 3 with the Pocket TTS part of Step 4, since Pocket TTS needs clips from the game; then ElevenLabs and Inworld, the rest of Step 4; then Step 5. Step 6's write-up and tests go with each part. Step 3 is the longest and least certain piece, and all three picks wait on it.

## Step 7: Online voices cloned from several clips

Why: Pocket TTS and voice setups copy a voice from one clip, so every voice is cloned from one game line of 5–10 seconds. The online services want more:

- Inworld: works best with 10–30 seconds and cuts anything past 30 seconds. It suggests joining a few short clips into one, and warns against whispering, coughs and other sounds that aren't speech.
- ElevenLabs: 1–2 minutes works best. More than 2–3 minutes helps little and can make the voice less steady. It takes several files at once.

So with one 5–10 second line, online voices sound less like the NPC than they could. The fix is a new way to pick clips, not a button added to the old one: each voice keeps a list of chosen clips, every service takes as much as it needs from the top, and Change a voice shows them the way the TTS Service uses them. This replaces how Change a voice works in Step 3 and the tried voices in Step 4. The feature hasn't been published yet, so nothing has to stay compatible with how it works now.

What each service is cloned from in game:

| Service | Lines the game sends for a new voice | Lines the voice is cloned from |
|---|---|---|
| Pocket TTS and voice setups | 4 | 1, the top one |
| Inworld | 4 | 3 or 4: as many as fit in 30 seconds |
| ElevenLabs | 10 | all of them, about 75 seconds, up to 2 minutes |

How Change a voice looks with Inworld:

```
Voice to change: [ Female Even Toned           ▾ ]

Cloned from · 22 s of 30 s
  ▶  dialoguesolitude__000dd60f_1.fuz   7.2 s   [Take out]
  ▶  dialoguewhiterun__0001a2b3_1.fuz   8.9 s   [Take out]
  ▶  dialoguegeneric__00045c11_1.fuz    6.1 s   [Take out]

Other clips
  ▶  dialoguemarkarth__000b7e20_1.fuz   9.4 s   [Add]
  [Find more clips]

Pitch  [────●────]
Test sentence [ ............ ]  [Hear the voice]
```

ElevenLabs looks the same, with "45 s · best with 60 s or more" in the heading. Pocket TTS and voice setups show one clip under Cloned from, with Use this one on the other clips.

Getting enough clips:

- [ ] A new voice arrives with all its lines chosen, in the order they came. The game is asked for as many lines as the service speaking needs: 10 for ElevenLabs, 4 for every other service.
- [ ] Topping up: when a voice has less than its service needs (Inworld 25 seconds, ElevenLabs 60), and you haven't changed that voice on the page, Mantella asks the game for more lines the next time the voice speaks, and adds them to the chosen clips. Example: you play with Pocket TTS for a week, then switch to ElevenLabs. Your voices have 4 lines, about 30 seconds. The first time each one speaks with ElevenLabs it is cloned from those 30 seconds and the game is asked for 6 more; from a later line it is cloned again from about 75 seconds. A voice you changed by hand is never topped up: the heading says it is short instead.
- [ ] Prepare all voices still asks for 1 line per voice type: it is only for Pocket TTS and setups, which use one clip. Topping up fills those voices if you switch to an online service later.
- [ ] ElevenLabs plans hold a limited number of voices. When the plan is full while a voice is being cloned again, Mantella deletes that voice's old copy first and tries once more, instead of failing.

The page:

- [ ] Each clip shows its game line's file name and how long it is, with a slim play button to hear it. What a line says isn't shown: the words live in the plugin, and reading them safely needs the game's main thread (decided against: risky for a label).
- [ ] Two groups: Cloned from (what the TTS Service makes the voice from now) and Other clips (what else you could use). Every row has one button. The separate Clip player, the Other clips you can clone from list, Remove, Bring back removed clips and Refresh go away.
- [ ] The page follows the TTS Service setting on the same page: switch from Pocket TTS to Inworld and Change a voice redraws at once. Pocket TTS and setups get the one-clip view; Inworld and ElevenLabs the several-clips view. Piper, XTTS and xVASynth don't use clips: the list is hidden and the page says so, unless the Backup Voice Service uses clips, in which case the list is shown for that service.
- [ ] One-clip view: Use this one swaps that clip with the one under Cloned from. Nothing else changes.
- [ ] Several-clips view: Add moves a clip into Cloned from; Take out moves it to Other clips. The heading counts the seconds against what the service takes: Inworld "22 s of 30 s"; ElevenLabs "45 s · best with 60 s or more" until it has 60. When Inworld's 30 seconds are used up, Add is greyed and says "Inworld is full: take one out first." ElevenLabs stops at 2 minutes (or 16 clips) the same way. The last clip can't be taken out: a voice always has one.
- [ ] Find more clips swaps the Other clips for 4 new ones from the game (all of them, except one that another service in use still takes). When the game has no new lines left, it starts over with the ones swapped out before.
- [ ] New clips show up on their own when the game sends them, the next time you talk to someone in game. There is no Refresh to press.
- [ ] Every change is saved at once. There is no Clone button to remember: the voice is cloned again the next time it is heard, on the page or in game. Cloning is free on both online services and happens once per change; the old voice is deleted on the service.
- [ ] Hear the voice always plays what NPCs will get: the clips under Cloned from, through the TTS Service as picked on the page.

Nothing mixed up:

- [ ] Each voice has one list of chosen clips, in order, shared by every service, so the backup service's voice is always one you can see. A line under the list says what each other service you use takes: "Your backup, Pocket TTS, uses the top clip."
- [ ] A clip under Other clips that another service in use still takes is tagged with its name, for example "used by ElevenLabs" after you switch from ElevenLabs to Inworld but keep ElevenLabs for one NPC. When no other service takes it, it is just another clip.
- [ ] Share voices with a friend carries the chosen clips in their order.
- [ ] Give an NPC their own voice and Give this NPC's voice to their whole voice type work as today, with the chosen clips moving with the voice.
- [ ] FEATURES_README's Voice Clips part describes both views, and the in-game test hears one voice type through Pocket TTS, Inworld and ElevenLabs, switching between them, before and after adding clips.

Example: Female Even Toned arrives with 4 lines, 30 seconds in all, and Inworld clones the voice from all four joined together. One of them is a shout, and the voice sounds harsh: you play it, press Take out, press Hear the voice, and it is cloned again from the other three. Your backup is Pocket TTS, which keeps using the top clip.

## Step 8: Sounds and directions

Why: NPCs on a cloned voice speak every line in the same tone. Inworld's TTS-2 can laugh, sigh and gasp in the middle of a line, and can say a line angrily or in a whisper when told to. The AI writes these in square brackets, and Mantella makes sure only Inworld hears them.

- [ ] Two switches in Inworld's part of the TTS page, both off at first. **Audio tags**: NPCs laugh, sigh, gasp and groan where it fits the line. **Directions**: NPCs say lines the way they feel, angrily, in a whisper, trembling. Directions work with the TTS-2 model only; TTS-2 Flash ignores them, so with Flash they stay locked.
- [ ] When a switch is on and an NPC in the conversation speaks with Inworld, a part of the prompt unlocks and tells the AI what it may write. Audio tags lists the sounds the NPC's voice can make (laugh, chuckle, sigh, gasp, groan, grunt, scoff, sob, sniffle, cough, clear throat, breathe, yawn, growl). Directions says the AI may start a spoken sentence with a short direction, such as [say angrily] or [whisper]. Both say most lines need none, and neither is allowed in narration.
- [ ] Only in the default prompts: one NPC, a group, a group in Director Mode, NPC Initiative, Radiant conversations and the Game Master NPC prompt. If you changed a prompt, reset it to default to get the new parts. With both switches off, the prompts send exactly what they sent before.
- [ ] The sounds and directions never show in subtitles, never go into what NPCs remember, and never reach another voice service: in a group, an NPC who speaks with Pocket TTS just gets the words. The backup voice service gets the words too.
- [ ] A direction changes only the sentence it starts, since Mantella sends each sentence to Inworld on its own, so only the sentences that need one are tagged and nothing has to switch it off. Inside a sentence, a new direction changes how the rest of it is said. Neither the prompt nor Mantella uses Inworld's [reset]; one the AI writes anyway is passed on. A short sentence Mantella joins to the one before it (Number of Words TTS) goes in the same request, so it is said with that sentence's direction. A sound with no words after it (the [sigh] at the very end of a reply) goes with the NPC's next sentence, or is dropped if there is none.
- [ ] A full stop or other sentence end inside the brackets ([say angrily. very loud]) doesn't split the sentence. A "[" still open after 150 characters is taken as a stray bracket, so it never holds a reply back.
- [ ] An action's keyword (Follow:, Barter: and so on) is taken out of what Inworld gets, as it is from the subtitles.
- [ ] While a switch is on, square brackets in a reply hold sounds and directions, not narration. Narration still works with stars and round brackets.
- [ ] Other services can join later: each says which sounds and directions it takes with its own settings, and everything else stays the same. HeyGen, Qwen and Boson AI joined in Step 9.

Example: Lydia is on Inworld with both switches on. The AI writes: `[sigh] Fine. [say coldly] Take it. Go.` The subtitles show "Fine. Take it. Go." Inworld gets "[sigh] Fine.", then "[say coldly] Take it.", then "Go.", so Lydia sighs, says "Take it" coldly, and "Go" in her normal voice. To stay cold, the AI writes [say coldly] again before "Go."

Tried and dropped (2026-11-18):
- A clip for each mood for Pocket TTS (an angry clip, a sad clip, picked by the line's mood): dropped after testing.
- Letting Inworld pick the mood itself from the line and the conversation (Inworld's "reasoning"): dropped after testing.

## Step 9: More online voice services

Why: players asked for more online voices. Three more clone voices on their free plan: HeyGen, Qwen and Boson AI. Each one works like ElevenLabs and Inworld: a part of its own on the TTS page, each voice cloned once on the player's account, the old voice deleted when the clips change, the service's built-in voices when it won't clone, and the backup service when it won't speak.

- [ ] HeyGen: a **Model** setting with Turbo and Turbo Free. Turbo Free costs nothing until HeyGen ends it on Nov 30, 2026; its end date on Mantella's list of models (Step 11) takes it out of the list by itself. HeyGen's Turbo price wasn't on a page we could read, so no cost is shown for it until we know.
- [ ] Qwen (Alibaba Cloud's Model Studio): Singapore only. Its keys only work in the region they were made in, and every workspace has its own address, so the player pastes a key and a **Workspace ID**. **Check my key** says plainly when the two don't belong together.
- [ ] Boson AI (Higgs TTS 3): it clones a voice only together with the words spoken in the clip. Mantella hears each clip once with the player's Speech-to-Text choice, also when they type instead of talking, and keeps the words. Reading the line's subtitle in game was turned down: it needs a call into the game's dialogue code on the main thread, which can crash the game if it goes wrong, and a voice pack in another language would give words that don't match the clip.
- [ ] Sounds (Step 8): an **Audio tags** switch on all three. The AI keeps writing Mantella's words ([laugh], [sigh]) and each service gets them its own way: HeyGen [laughs], Qwen [laughing], Boson AI <|sfx:laughter|>. Each offers only the sounds it knows.
- [ ] Directions (Step 8): only Qwen. It takes a free-form direction as a separate instruction for the whole line, so a second direction inside a line is left out, and only while Mantella's Language is English, because Qwen wants the instruction in the language of the line. HeyGen and Boson AI only take directions from their own short lists (Boson refuses a line with any other tag), so they get none.
- [ ] Sound symbols in Fix Pronunciation: HeyGen yes, but only for a cloned voice on Turbo (Turbo Free and HeyGen's own voices refuse the whole line, so they use the spelling); Qwen and Boson AI use the spelling.
- [ ] A voice whose clips a service turns down (HeyGen or Qwen rejects the sound, or Boson AI hears no words in any of them) uses the service's built-in voice on its own, and those clips aren't sent again this session. Before this, they were cloned again twice on every line, which used up HeyGen's 20 free clones a day, and one clip with no words stopped Boson AI cloning for every NPC for 5 minutes. Boson AI leaves out a clip with no words and clones from the rest.
- [ ] When HeyGen ends Turbo Free, a player still on it is told to pick Turbo, on the page and once in game, instead of the backup voice speaking with no reason given.
- [ ] Qwen's Workspace ID is read when the TTS page opens, so the Voice Clips buttons can delete voices on Qwen before Qwen has spoken that session.
- [ ] Live check with a free key on each service before shipping: Check my key, Try A Voice on a voice type with clips, with Audio tags on. A service that refuses to clone on a free key is dropped.

Example: Serana is on Qwen with both switches on and the AI writes `[say coldly] Fine. [sigh]`. The subtitles show "Fine."; Qwen gets "Fine. [sighing]" with the instruction "say coldly".

## Step 10: How cloned voices sound

Why: every cloned HeyGen voice ended its lines on a rising tone. Mantella sent HeyGen no tone settings, so HeyGen used its liveliest. Listening tests on three voices (Daegon, Female Young Eager, Male Even Toned) settled what each service offers and where it starts.

| Service | Setting | Choices | At first | Changes |
|---|---|---|---|---|
| HeyGen | Similarity | Medium, High, Very high, Highest | Highest | when a voice is cloned: changing it clones the voice again |
| HeyGen | Expressiveness | a slider, 0 (flattest) to 1 (HeyGen's own) | 0.5 | every line |
| Inworld | Delivery | Stable, Balanced, Creative | Balanced (Inworld's own) | every line; TTS-2 only, nothing on TTS-2 Flash |
| Boson AI | Expressiveness | Flat, Normal, Lively | Lively | every line |

- [ ] Each setting is on the TTS page for every NPC, in the service's part under a new heading, **How NPCs sound**. The part's key now sits under its own heading, **Your key**, with the steps folded under **How to get a key**.
- [ ] A setting that doesn't apply to the picked Model is hidden: Inworld's Delivery, and Directions too, with TTS-2 Flash. Since Step 11, Mantella's list of models says which settings each model skips, and each model keeps its own values.
- [ ] Each voice can have its own, on **Voice Clips** under **Pitch**, for the service the list follows. Each starts at "Same as the Text-to-Speech page"; a slider has a button to go back to the page's. Settings follow the voice like Pitch: NPCs who share a voice type share them, an NPC with a voice of their own has their own, and they move with "Give …'s voice to every … NPC". A service's built-in voice always uses the page's.
- [ ] A new Similarity, on the page or for one voice, clones only the voices it changes, once each, the next time they speak. Free HeyGen accounts can clone 20 voices a day, which the page says.
- [ ] HeyGen ignores Expressiveness on a sentence with a sound or a mood in it, and says so; only those sentences lose it.
- [ ] Moods join **Audio tags** for HeyGen and Boson AI, since both take them only from their own lists: angry, sad, scared, happy, excited, calm, surprised, disgusted, proud, tender, whisper and shout on both; nervous, cold and sarcastic on HeyGen; bitter and ashamed on Boson AI. The AI writes Mantella's word ([angry]), and each service gets its own ([angry], <|emotion:anger|>). A mood changes how the rest of the line is said. The prompt's sounds rule becomes "Sounds and moods". An NPC on Inworld TTS-2 with Directions on gets a mood as a direction; others don't get it.
- [ ] Boson AI: a mood replaces every tag before it, so the voice's Expressiveness goes right after each mood too.
- [ ] Sharing voices with a friend carries each voice's settings with its Pitch.
- [ ] Pocket TTS gets nothing: its program ignores the one setting it has (temperature) when it runs as a server.

Example: Daegon is a voice type on HeyGen. On the TTS page Expressiveness is 0.5. Under **Voice Clips**, Daegon's is set to 0.2: every NPC with Daegon's voice type now sounds flatter, every other NPC stays at 0.5. When the AI writes `[angry] Get out.` for Daegon, HeyGen gets "[angry] Get out." and uses its own expressiveness for that sentence only.

## Step 11: Settings per model, and new models

Why: the same setting can mean something different on another model (0.3 Expressiveness on one model isn't 0.3 on the next), so one value per service was wrong. And when a service releases a model, players shouldn't wait for a Mantella update to use it: they add it themselves. The services can't tell Mantella this themselves: none says which settings a model takes or whether it takes cloned voices, and only ElevenLabs and Qwen list their models at all. So we keep our own list.

- [ ] **Mantella's list of models**: a file Mantella ships (`data/voice_models.json`). Mantella doesn't read it from anywhere online. For each model it gives the name, the price, a note, the settings it doesn't take and where they start. It lists only text-to-speech models that speak with cloned voices, checked live.
- [ ] All five online services get a **Model**: ElevenLabs, Inworld, HeyGen, Qwen and Boson AI. It shows the list's models by name, and takes any model ID typed in.
- [ ] **Players change the list themselves**, under the Model next to **Settings for**: they type a model's name there and press **Add model**, and it shows up in both Model lists. **Remove model** takes the picked model off both lists; its settings are kept, so adding it again brings them back. Removing the model the service speaks with switches it to the service's usual model (or the first one left), and the last model can't be removed. **Put back Mantella's models** (shown only after removing one) brings back Mantella's models the player removed. The changes are kept in config.ini, one hidden setting per service. A typed model that isn't on the list shows every setting the service has, has no price, and gets no sound symbols. A model past its end date (Turbo Free after Nov 30) drops out of the list; a player still on it is told to pick another.
- [ ] **Each model keeps its own values** of the settings under **Settings for <model>** (Expressiveness, Delivery, and Settings Mantella doesn't have yet), on the page and for each voice under NPC voices. A model never used starts where the list says. **Model**, **Similarity**, **Audio tags**, **Directions** and **Volume** stay one per service, above the model's settings: the switches change what the AI writes, not the voice, and Similarity is how a voice is cloned, which works on every HeyGen model (one per model would clone every voice again on each switch, against HeyGen's 20 clones a day). A model that skips one of them hides it and treats it as off.
- [ ] **Settings Mantella doesn't have yet** (folded, per model): fields the player writes as JSON, sent with every line on that model. For a setting a service adds before Mantella has a slider for it. When the service refuses lines because of them, or refuses a model typed in (its answer names the model, even as "not found"), the backup voice speaks and the page says why with the service's own words, and Mantella tries again in 5 minutes. Other refusals stay as they were, so one odd line doesn't pause the service.
- [ ] Qwen voices only work with the model they were cloned for: another Qwen model clones each voice once more, and NPC voices says so under **Cloned from**. The other services keep their voices. A model that can't speak with cloned voices at all is told plainly, and NPCs use the built-in voices.
- [ ] NPC voices follows the Model: picking another one redraws "How this voice sounds with <model>" at once. A model that takes more speech than the service's usual can say so on the list, and **Cloned from** and **Add** follow it.
- [ ] A new kind of setting (a slider Mantella doesn't have) still needs a Mantella update, or Settings Mantella doesn't have yet until then.

Example: HeyGen releases Turbo 2. A player types `heygen-voice-2-turbo` in the Model next to **Settings for** and presses **Add model**. It's now in both Model lists. They pick it: every HeyGen setting shows, since Mantella doesn't know which ones Turbo 2 takes, and their Turbo values wait for them. They want Turbo 2's new speed, so they write `{"speed": 1.1}` under Settings Mantella doesn't have yet. They never use Turbo Free, so they pick it and press **Remove model**.

## Step 12: Iodine

Why: listening tests on eight game voices (Daegon, Female Young Eager and six more, 20 to 30 seconds of clips each, with their words) showed Iodine copies voices well, takes moods, directions, sounds and styles on a few words, and clones on its free plan. $8 per million characters.

- [ ] Iodine gets a part of its own on the TTS page, like the other online services: a key, a **Model** (Iodine v2), **Temperature**, **Audio tags**, **Directions**, **Talking speed** and **Volume**. Each voice is cloned once on the player's account, up to 50.
- [ ] **The words go with the clips**, as Iodine recommends: Mantella hears each clip once with the player's Speech-to-Text choice and sends the words with the sound. A clip with no words heard is left out of both, so they match. When Speech-to-Text can't hear them, the voice is cloned without words and Iodine hears the clips itself, so the NPC still gets their voice. If Iodine turns the words down, it tries once more without them.
- [ ] **Temperature**, Iodine's own name and range (0 to 2): lower sounds steadier and more alike each time, higher more varied. It starts at 1. Iodine suggests lowering it, for example to 0.7, if words come out misread, skipped or repeated. Each model keeps its own, and each voice can have its own.
- [ ] **Audio tags** turns on sounds ([laugh], [sigh], [pause], [shaky breath]), Iodine's 12 emotions ([happy], [nervous], [sarcastic]...) and **word styles**, which cover only a few words: [whisper]just between us[/whisper], [emphasis]never[/emphasis]. Word styles have no switch of their own.
- [ ] **Directions** turns on a delivery described in a few words, like a note to an actor: [quietly, trying not to laugh], commas allowed. A short sound of its own, such as [small laugh], works too.
- [ ] The AI writes square brackets, and Iodine gets curly ones ({happy}), each where the AI put it. Curly brackets are how Mantella's prompts write their variables, so the AI never sees them.
- [ ] An emotion and a direction side by side never reach Iodine together: `[happy] [low, gravelly]` keeps only the first. The prompt says the same in Iodine's words: "One emotion per sentence at most, and no more than two or three cues in a row. Most sentences need none."
- [ ] **The voice tag rules are rewritten for every service** in Iodine's style: one heading, one short line for each kind of tag, shown only when an NPC's voice takes it, and the same last line for all. The block never names a language: the conversation's language is the player's, from the prompt's {language}. The old rules contradicted each other ("most lines need none" against "start every sentence that has a clear feeling with one"). Every speaking prompt now shows an example reply with the tags the voices take. Players who changed their prompts keep their own text; the release notes say the rules changed.
- [ ] Lines longer than 275 characters get an error page from Iodine (its docs say 5,000). We take it as Iodine's bug and leave it: such a line goes to the backup voice like any other failed line.
- [ ] Live check with the free key before shipping: Check my key, clone one game voice (Iodine must say it used the words), a line at Temperature 0.7 and 1.5, a German line with a mood, a word style, a pause and a direction, then delete the voice.

Example: Ysolda is on Iodine with both switches on, and the AI writes `[nervous] [low, uneasy] Keep your voice down. [whisper]The guards are close.[/whisper]`. The subtitles show "Keep your voice down. The guards are close." Iodine gets `{nervous} Keep your voice down. {whisper}The guards are close.{/whisper}`: the direction right after the emotion is left out.

## Step 13: Talking speed

Why: Iodine has no speed setting, and some voices talk too fast or too slow for an NPC. Mantella changes the speed itself, so every newer service gets it the same way.

- [ ] **Talking speed**, from 0.7 to 1.5, starting at 1 (the voice's own speed). The pitch stays the same. Named so it isn't mixed up with **Speed and lip sync**, which is about how fast NPCs start talking.
- [ ] Online services (ElevenLabs, Inworld, HeyGen, Qwen, Boson AI, Iodine): one per model, under **Settings for <model>**. A new online service gets one by itself.
- [ ] Pocket TTS: one, next to its Volume. Each voice setup: one, next to its Volume in the setup editor.
- [ ] Each voice can have its own, on **Voice Clips** under **Pitch**: one Talking speed slider for the service shown, kept per model for an online service and per setup for a voice setup.
- [ ] The line is changed before its lip file is made, so the lips follow, and every Test or Hear button plays it. If the change fails, the line plays at its own speed.
- [ ] Piper, XTTS and xVASynth are left as they are. The services' own speed fields aren't used, so a voice sounds the same speed whichever service speaks it.

Example: Daegon's lines on Iodine feel rushed. Under **Voice Clips**, Daegon's Talking speed is set to 0.9 for Iodine v2: every NPC with Daegon's voice talks a little slower on Iodine, and everyone else stays at the page's 1.

# For developers

## Plain words to code names

| In this doc | In code (today → planned) |
| --- | --- |
| Voice service | TTSable subclasses in src/tts/ → same base, slimmed to the per-service questions; new src/tts/pocket_tts.py, src/tts/openai_style.py |
| The list of voice services | TTSEnum + display_name in tts_definitions.py, plus the if/elif chains → one registry (name, aliases, class, kind, runs online) that everything iterates |
| Two places that start the chosen service | MantellaRoute._setup_route and _hot_swap_settings (src/http/routes/mantella_route.py) → one create_tts(config, game) factory |
| Per-NPC column | OutputManager._parse_tts_service_str / _get_or_create_tts (src/output_manager.py) → aliases from the registry |
| Folder check only when selected | validate_xtts_path etc. in config_loader.py → each service's config values validated when it is the default or used per NPC |
| Settings under each service's name | ConfigValues in tts_definitions.py → each service declares its own list, the UI groups them |
| Order for choosing a voice | _select_voice_type copied in xtts.py, piper.py; change_voice in each service → one shared voice picker |
| Race and gender tables | MALE_/FEMALE_VOICE_MODELS_XTTS, _PIPERTTS, _XVASYNTH in skyrim.py, chosen by TTSEnum → one table (fallout4.py stays as it is) |
| Talking speed | new: `voice_speed.SpeedChange` in the shared clean-up (`audio_cleanup.clean_up`), the value from `voice_style.SPEEDS` / `SETUP_SPEED` |
| Iodine's cues ({happy}, {whisper}…{/whisper}) | new: `iodine.IodineCues`, from the square-bracket tags `voice_tags.split` keeps |
| Word styles | new: `VoiceTags.styles`, condition `word_styles`, variable `{voice_styles}` |
| Shared clean-up | TTSable.synthesize already does lip files; XTTS._convert_to_16bit → shared convert (16-bit PCM WAV, any input rate), leading and trailing silence trim (threshold-based, short margin kept), lip files |
| Backup service | per-NPC fallback in OutputManager.generate_sentence → a general fallback chain ending in the Backup Voice Service |
| Voice clips folder | new; voice_types/&lt;VoiceType editor ID&gt;.wav, plus npcs/&lt;plugin&gt;_&lt;local form ID&gt;.wav for NPCs with a clip of their own (plugin + local form ID, so load order changes don't break it). Each has a .json with how it came about (automatic: own lines from another mod; or chosen by the player), the source line (plugin + INFO form ID + voice file path), the file's size and source (loose or which archive) and the lines the player turned down (+ cached .safetensors or online voice id). Export picks = these .json files minus the sound, the size and source, as one JSON file keyed by plugin + form ID |

## Service interface (sketch)

Each service class declares: name, aliases, kind (clip / trained), runs_online, languages, config_values(), is_ready(), start() (local only), prepare_voice(voice_key, clip_path) (voice_key = an NPC or a voice type; clip kind: export a voice file or create an online voice, cached), synthesize(text, voice, out_path). Everything else stays in shared code.

Current caveats: Piper, XTTS and xVASynth keep their current classes and code paths (decided: untouched for now). The registry and create_tts sit next to the existing TTSEnum branches, which gain one branch that hands new services to the registry. TTSEnum's xVASynth-only branches in skyrim.py and fallout4.py stay as they are. Keep existing config keys (tts_service = Piper, xtts_url, ...) so the user's config.ini needs no change.

## Request styles (setups without code)

- Setups live in a JSON file next to config.ini and load into the same registry as built-in services; their aliases are the normalized setup name. Fields: name, style (openai / xtts), url, key_file, model, extra_fields (merged into every request body), clip_field, clip_mode (path / base64), languages, runs_online.
- OpenAI-style: POST {url}/v1/audio/speech, header Authorization: Bearer &lt;key&gt; when a key is set, JSON {model, input, voice, response_format: "wav", ...extra_fields}. Response = raw audio bytes; ask for wav, but accept mp3/opus/flac through the shared converter. GET {url}/v1/models doubles as the ready check. Clip modes (clip_mode field): path = the clip's local path goes in clip_field (voice_ref for audio.cpp); base64 = the clip's bytes, base64-encoded, go in clip_field with every request (speaker_ref_b64 for llama-server, which turns /v1/audio/speech into its /tts request, so /tts options such as seed and lang work too).
- XTTS-style: POST {url}/tts_to_audio JSON {text, speaker_wav, language}; voices from GET {url}/speakers_list. Send the same request shape as XTTS._synthesize_line_xtts, as separate code: the built-in XTTS service stays untouched, with its extras (starting the server, switching models).
- Test button: one synthesize call with a fixed sample line and the chosen voice, played in the UI.
- Ready-made setups: a JSON file shipped with Mantella, same fields as user setups plus a built-in flag; picking one copies it into the user's setups. Adding a service = adding an entry.
- Address check: probe GET {url}/v1/models (OpenAI-style), GET {url}/speakers_list (XTTS-style) and GET {url}/health (Kyutai's Pocket TTS server). CHIM probes /health, /v1/models, /provider_info and /openapi.json the same way. No port search: the address is the user's.

Own request styles seen in the research:

- Inworld (src/tts/inworld.py): Authorization: Basic <key as given>. Clone once with POST /voices/v1/voices:clone (voiceSamples[].audioData base64, languageCode), which returns voice.voiceId ({workspace}__{voice}); speak with POST /tts/v1/voice (modelId inworld-tts-2, LINEAR16 48 kHz, audioContent base64 with a WAV header); DELETE /voices/v1/voices/{voiceId}; Check my key lists GET /voices/v1/voices. Built-in voices Alex and Ashley. Sound symbols written /…/.
- ElevenLabs (src/tts/elevenlabs.py): xi-api-key header. Instant voice clone with POST /v1/voices/add (multipart files + name), speak with POST /v1/text-to-speech/{voice_id}?output_format=mp3_44100_128 (model_id eleven_v4_turbo), DELETE /v1/voices/{voice_id}; Check my key reads GET /v1/user/subscription (voice_limit, voice_slots_used, can_use_instant_voice_cloning). Built-in voices George and Sarah.
- Shared part (src/tts/online_service.py, OnlineCloneService): voice IDs kept in voice_clips/online_voices/<service>.json by voice key with the clip's hash and a fingerprint of the key (a new key forgets the old account's voices). A swapped clip is cloned again and the old voice deleted in the background; a 404 on speak forgets the voice so the retry clones again; CloneRefused (plan limit, no cloning, ElevenLabs' quota_exceeded or missing_permissions) or a rejected key turns cloning off for 5 minutes (RETRY_MINUTES), says why (log; error sound and in-game notice once per service copy; the service's part of the page via online_service.problem) and NPCs without a voice use built-in ones. A "not found" while speaking only clones again once voice_exists confirms the voice is gone, so an unrelated not-found never uses up voices. Tried voices are named like the voice they may become (no "(trying)"). Prices for the cost line sit in the registry (price_per_million_chars, list prices of 2026-11-17: $40 and $25), 30 lines of 100 characters.
- Voice Clips buttons go through src/tts/kept_voices.py, which acts on Pocket TTS's saved voices and each online service's VoiceKeeper (online_voices.py): tried voices (try_<key>) are kept on Clone from this clip, deleted on the service otherwise, and leftover ones are deleted once per run.

## Pocket TTS server (Kyutai's pocket-tts.exe serve, read from source: rust/src/server.rs, download.rs)

- Same endpoints as the Python server (rust/README.md): GET /health returns {"status": "healthy"}; POST /tts, multipart form or urlencoded, not JSON: text (required), voice_url or voice_wav (not both; 400).
- voice_url only accepts http://, https://, hf:// or a built-in voice name; local paths are refused. Serve the voice states from Mantella's own HTTP server and pass that URL.
- Voice cache: VOICE_CACHE_SIZE = 2, least recently used (like the Python lru_cache(maxsize=2)). A third voice evicts the oldest, so group conversations reload voices.
- http(s) URLs are downloaded once into ~/.cache/pocket_tts/&lt;sha256 of the full URL&gt;.&lt;ext&gt; and never refreshed. Put a version in the URL (e.g. ?v=&lt;clip hash&gt;) so a swapped clip gets a new URL; clean old files from that folder now and then.
- voice_wav uploads are written to a temp file and re-encoded on every request: too slow per line.
- Response: chunked audio/wav; sample rate is model.config.mimi.sample_rate (24 kHz; read it from the WAV header).
- Flags: --host, --port (default 8000), --default-voice (also takes a local .safetensors path), --language, --config (local path, https:// or hf://; not with --language), --quantize (xn int8). Always CPU. Pick a port other than 8000 and 8020 (XTTS).
- Environment: RAYON_NUM_THREADS sets the thread count (default 4); POCKET_TTS_SEED sets the seed, which is fixed by default, so the same line always gives the same sound.
- export-voice turns a clip into a fast-loading .safetensors voice state.

## Pocket TTS plug and play

- Windows program: the Rust standalone binary in the GitHub releases (v4.0.1: pocket-tts-3.3.0-x86_64-pc-windows-msvc.zip, 7.9 MB, SHA256SUMS in the release). It needs AVX2. The v4.0.1 release has no -v2 (SSE4.2) archive for Windows, so on a processor without AVX2 Mantella says so and the backup service speaks. Built on xn-ptts; audio is not bit-identical to the Python package (different noise generator), but the model is the same.
- Model per language: --language english in 3.3.0 means english_2026-10. Each config pins weights_path = hf://kyutai/pocket-tts/languages/&lt;lang&gt;/model.safetensors@&lt;revision&gt; (gated, auto-approved, needs an HF token) and weights_path_without_voice_cloning (not gated). The voice-cloning weights are stored in bf16, 219 MB per 6-layer language.
- Sign-in: we use Kyutai's gated download as it is. The player makes a Hugging Face account, accepts Kyutai's terms on kyutai/pocket-tts and saves a read token in HUGGINGFACE_SECRET_KEY.txt (read like the other key files). Mantella passes it to pocket-tts.exe (confirm the variable name in rust/src/download.rs; HF_TOKEN is the usual one) and starts it with --language &lt;lang&gt;, Kyutai's own config, so the program downloads and pins the weights itself. Before starting, Mantella checks the token can read the gated repo; without access the program uses weights_path_without_voice_cloning (built-in voices only) and Mantella warns on the TTS page, in the log and once in game. No copy of the weights is hosted or shipped.
- Model updates: only when Mantella moves to a newer program version, whose configs pin newer weights. Then rebuild every voice state from the saved clips (voice states are tied to the weights).
- Cache: export-voice turns each game clip into a .safetensors voice state, so the clip is encoded once, not per line. Rebuild them whenever the weights or the language change.
- Serve the voice states from Mantella's own HTTP server, e.g. voice_url=http://127.0.0.1:&lt;port&gt;/voices/english/femaleeventoned.safetensors?v=&lt;hash&gt;.
- Licences: code MIT (GitHub), weights CC BY 4.0 (Hugging Face model card). Credit Kyutai on the TTS page and in the download.

## Programs compared for Pocket TTS (Nov 2026, read from sources, not run)

- Kyutai pocket-tts.exe: see above. No published Windows speed numbers. Python version: ~6x real time on 2 cores of a MacBook Air M4; 2.3–2.5x on a 4-vCPU cloud VM.
- llama.cpp: Pocket TTS in libmtmd since 11 Aug 2026 (PR #26871). llama-tts and llama-server (/tts and /v1/audio/speech, clip as speaker_ref_b64 or multipart speaker_ref, per request). Two GGUFs per language (model + mmproj), converted with convert_hf_to_gguf.py from kyutai/pocket-tts languages/&lt;name&gt;; hparams are hard-coded in C++. EryriLabs/pocket-tts-GGUF: RTF 0.65 on 1 thread, 0.24 on 8 threads of an i9-13900K, WER equal to PyTorch within noise. Windows CPU build 25 MB.
- audio.cpp: v0.9.5 (14 Nov 2026), Windows CPU build 34 MB. Loads its GGUF (audio-cpp/audio.cpp-gguf, ungated, english bf16 219 MB / q8_0 128 MB, uploaded 22 Jul 2026, so english = 2026-04) or Kyutai's safetensors directly. Parity harness against Kyutai's Python with shared noise; bf16 GGUF passes, q8_0 passes with drift. voice_ref takes a local path; pocket_tts.voice_state_cache_slots defaults to 4. CUDA numbers only (3.7x faster than Kyutai's Python).
- sherpa-onnx pocket-tts-int8-2026-01-26 (98 MB, KevinAHM's ONNX export repackaged; shipped by AudioUtilTTS): English only, int8, no HTTP server; AudioUtilTTS reports ~0.3 s compute per second of speech on 2 threads.
- VolgaGerm/PocketTTS.cpp: ONNX Runtime, OpenAI-style server, .emb/.kv disk cache; last push 29 Mar 2026, exporter only handles the original b6369a24 weights (issues #8, #12, #14), int8 noise (#13), robotic voice (#10), no Windows builds.
- ServeurpersoCom/pockettts.cpp: ggml port with an OpenAI-style server; GGUFs up to english_2026-09 and Dutch; no releases.

## Word lists (Step 1)

- Folder: pronunciation/ next to config.ini (Documents\My Games\Mantella), so it survives reinstalls. Every *.csv in it is read.
- mantella_words.csv: shipped with Mantella, overwritten on every update. Seeded into the folder on first run.
- my_words.csv: created empty (header only) on first run, never overwritten. Load order: mantella_words.csv first, other files alphabetically, my_words.csv last; a later entry for the same word, service and language wins.
- Columns: word, say_as, kind (spelling / ipa; blank = spelling), service (blank = all; matches the registry name or alias), language (blank = all; Mantella's language code). CSV like the character files, so it opens in a spreadsheet.
- Sound symbols: each service declares accepts_ipa and how to send it (inline markup, or a pronunciation dictionary uploaded once and referenced per request, re-uploaded when the lists change). For a service without it, ipa rows are ignored and the spelling row for the same word is used; with it, the ipa row wins. A service can also refuse them for some voices (takes_ipa(voice)): voice_into picks the voice first, then applies the lists. HeyGen takes its <pron ipa> tag only for a cloned (instant) voice on heygen-voice-1-turbo; Turbo Free and its own voices answer 400 for the whole line, so they get the spelling, and speak_with strips any tag that still reaches them. Hear it fixed passes the word and its sound symbols to voice_into (ipa_word), which writes them with the service's format_ipa, or raises NoSoundSymbols with the voice's no_ipa_reason, shown on the page instead of the word read as written.
- Matching: whole words, case-insensitive, longest entry first (so "Jarl Balgruuf" can beat "Balgruuf"); keep a trailing 's or punctuation attached to the replaced word. Applied in the shared layer right before synthesize(), never to the subtitle, the transcript or memory.
- Reload when any file's modified time changes (checked per line, cheap), so edits apply mid-game.
- A bad row (missing word or say_as) is skipped with one log warning naming the file and row.
- Play button: reuses the Test button path (one synthesize call, played in the UI) on a sample sentence such as "Have you seen {word}?", with the replacement applied; the compare button skips it. Sentence template per language. Sounds go through the shared clean-up but are never saved.
- Add to my list appends a row to my_words.csv (creating it if missing), keeping the file's existing rows and line endings; an existing row for the same word, service and language is updated instead of duplicated.

## How CHIM does it (abeiro/HerikaServer)

- tts/tts-pockettts.php: two back ends. audio.cpp on port 8086: POST /v1/audio/speech JSON {model: "pocket-tts", input, language, voice_ref: &lt;local wav path&gt;} (or voice: "alba"). Python bridge on port 8024: XTTS-style POST /tts_to_audio JSON {text, speaker_wav, language}. Detects which by probing /health, /v1/models, /provider_info, /openapi.json; tries ports 8086/8024/8020 if the set one fails.
- Every Pocket TTS response gets trim_start 250 ms before saving.
- vsx.php (voice sample upload): the game posts a .fuz/.xwm/.wav plus actor_name, original_name (path like Sound/Voice/Skyrim.esm/&lt;VoiceType&gt;/&lt;file&gt;.fuz) and reference_text. Converted with ffmpeg to 22,050 Hz mono 16-bit, saved as data/voices/&lt;voicetype&gt;.wav plus a .json with the metadata.
- processor/misc.php maybeQueueNpcVoiceRefresh: for an NPC without a voice id, sends the game RefreshNPCVoice@&lt;refid&gt;@&lt;name&gt;, at most once per 300 s.
- lib/core/tts_connector.class.php: per-driver maps (display name, voice field, default URL, default metadata, API key badge, language override support); resolveNpcVoiceForConnector = NPC voice → TTSFallback race/gender table (lib/core/tts_fallback.class.php) → connector fallback_male/fallback_female (malenord/femalenord).

## Clip from the game (Step 3)

A new DLL, MantellaVoiceClips (its own repo, set up like MantellaQuestChecks: CommonLibSSE-NG with xmake options skyrim_se, skyrim_ae and skyrim_vr on, so one DLL covers SE, AE and VR; build-addon.ps1 packs it next to MantellaQuestChecks.dll), finds lines by listing voice files, not by walking dialogue records. It writes the chosen file to a folder Mantella watches. Mantella can't call the game on its own: the request rides on Mantella's reply to a game request, as CHIM's RefreshNPCVoice does, and the add-on answers with a new request.

- File names: Sound/Voice/&lt;plugin&gt;/&lt;VoiceType&gt;/&lt;quest&gt;_&lt;topic&gt;_&lt;INFO local form ID, 8 hex&gt;_&lt;response #&gt;.fuz, with the load-order byte written as 00. Checked on Skyrim - Voices_en0.bsa (BSA v105, archive flags 0x3 so folder and file names are stored; 75,380 of 75,408 names match) and on 53,385 loose voice files across 971 installed MO2 mods (all but a handful match). Skip names that don't match.
- Listing: loose files with std::filesystem under Data\Sound\Voice\&lt;plugin&gt;\&lt;VoiceType&gt; (inside the game process, MO2's virtual folder answers directory listings, as SPID and similar plugins rely on), plus the name tables of the .bsa files in Data (header, folder records, file name block; never the file data). Plugins from TESDataHandler. The list only has to be a superset: a name from an archive the game didn't load fails to open in the next step and is skipped. Cache per voice type.
- Reading: RE::BSResourceNiBinaryStream(path), the game's own file system, so loose-over-archive and archive order follow the game and the winning file is the one read.
- Shared vs own lines: TESDataHandler::LookupForm&lt;TESTopicInfo&gt;(local ID, plugin), then its objConditions. A line conditioned on GetIsID (one speaker) belongs to that NPC; the rest are shared. A voice type's clip only comes from shared lines, so a replacer for one NPC never becomes everyone's voice. No INFO found = the line is gone.
- Own clip, automatic: when the NPC's own lines and their voice type's shared lines come from different sources (most common source of each set). When the NPC has own lines in the game's own plugins (Skyrim.esm, Update.esm, Dawnguard.esm, HearthFires.esm, Dragonborn.esm), only those are compared, against the shared game lines of the same plugin; lines that mods add sit loose in the mod's own folder and would make every NPC with added dialogue look re-voiced. A game NPC whose only own lines come from mods: no own clip. An NPC added by a mod: all own lines vs all shared lines.
- Picking: the pool is shuffled, then the game's own plugins' lines go first; lines added by mods are taken only when those run out (mod lines are often stitched together or made with AI). Source = loose if the path exists under Data, otherwise the archive(s) whose name table lists it. Two loose replacers from different MO2 mods can't be told apart from inside the game. Checked the first time the NPC speaks and again when files change.
- Prepare all voices (src/voice_clips/preparing.py): one background thread makes at most one voice per round, most used voice type first, through the service's prepared_voice with the program at below-normal priority; a failed voice is tried again after 60 s, three times. Only services from serving_in_game (the route's and the per-NPC ones, not the Test buttons) and not runs_online. prepared_voice locks per voice, never while another voice is made, so a conversation's lines don't wait for it. The clip requests ask for 1 line each (count 1): lines to hear come later with Ask the game for more lines. The DLL counts NPCs on the main thread (an SKSE task the worker waits for) and only those whose race has ActorTypeNPC. Nothing is asked for or made ahead for the people in a conversation or nearby (decided against: it makes the game heavier).
- Prepare all voices: a request with list_voice_types makes the DLL list every voice type the game's NPCs use (an NPC without one: its race's default for its sex) that has lines, most used first. Mantella then asks for their clips 8 at a time; each delivery's reply carries the next ones.
- Reaching the game: Mantella can't call the game, so the list request goes with its next reply (a conversation, or the mantella_voice_clip_save_loaded request the add-on sends once when a save loads). After that, each delivery's reply carries the next batch. The game never checks in on a timer (decided against: no periodic work in game).
- Own clip, chosen by the player: from the NPC's own lines if they have any, otherwise from their voice type's shared lines.
- Length, without decoding: .fuz = "FUZE" header, lip data, then an xWMA RIFF; seconds = the last entry of the xWMA 'dpds' table (decoded bytes) / (sample rate × channels × bytes per sample); data size / average bytes per second overestimates it by about a fifth (5.58 s against a true 4.64 s for dialoguesolitude__000dd60f_1.fuz). The counts below used the rougher estimate. Measured on the vanilla archive, lines of 5–10 s per voice type: Female Even Toned 957 of 2,294, Male Nord 2,049 of 4,527, Female Young Eager 655 of 1,819, Male Brute 612 of 1,840, Female Commoner 375 of 1,434, Male Khajiit 239 of 927.
- Song filter on the file name, which carries the quest and topic names: all 305 vanilla bard song files start with bardsongs_. The editable word list matches file names.
- Subtitle text isn't needed: no service needs the clip's words, and Voice Clips shows the file name. Reading the words from the INFO (TESTopicInfo::GetDialogueData) has to run on the game's main thread and was dropped as too risky for a label.
- Formats: .fuz (a .lip + .xwm pair), .xwm and .wav. xWMA needs ffmpeg or Microsoft's xWMAEncode to decode.
- Record the source line (plugin + INFO + file path), the file's size and its source in the clip's .json; when that changes on a later request, copy the same line's file again. Pick a new line only if the old one no longer exists or has no voice file.
- Ghost flag for voice effects (Step 5): no DLL needed. The add-on's Papyrus scripts send Actor.IsGhost() with the NPC's other details.
- Re-ask throttle: at most one request per NPC every 300 s while no clip comes back (CHIM's maybeQueueNpcVoiceRefresh).
- No head start from Mantella's XTTS download: it holds XTTS speaker latents (637 .json files for English, such as malenord.json), not audio, and other voice programs can't read them.

## Voice effects (Step 5)

- Applied to the finished line, after the lip file: a hook in TTSable.synthesize (`_finish_line`) between lip generation and the rename, which does nothing for Piper, XTTS and xVASynth. Pitch and filters don't change timing, and echo or reverb tails would add false mouth movement.
- Effects are small JSON files (src/tts/voice_effects.py): `name`, `about`, `races` (race editor IDs such as DraugrRace), `ghosts` (true/false), `strength` (0-100) and `sliders` (`pitch` in semitones, -12 to 12; `echo`, `space`, `doubled`, `muffled`, `thin`, `growl`, `waver`, 0-100; a missing one is 0), plus an optional `extra` list of raw ffmpeg filters for power users. Mantella's are in data/voice_effects (draugr, ghost, dremora, werewolf with werebears, vampire_lord). The player's are in voice_effects next to config.ini: a file with the same name as one of Mantella's holds only what the player changed, laid over Mantella's (sliders one by one, lists whole), so later updates still reach untouched values; any other file is a whole effect of the player's own. `on` lives in the player's file and is missing (off) on a fresh install. Undo my changes rewrites the file keeping only `on`. Files are read again when one changes. A wrong slider name or `extra` step makes the file broken: logged once, listed under How it works and not used. An effect that still fails on a line is skipped (warned once) and the line keeps its Pitch and Voice Volume.
- The sound, in order: one pitch pass for the voice's own Pitch plus the effect's Deeper or higher (asetrate, aresample, atempo, so the length is kept); Thin (highpass 20 Hz to 800 Hz) and Muffled (lowpass 12 kHz to 1.2 kHz), both on a log scale; Growl (tremolo at 35 Hz); Waver (a 5 Hz pitch swing made in numpy, since ffmpeg's vibrato in PyAV 12.3 now and then gives broken samples); Doubled voice (chorus); Echo and Space (a reverb: the line convolved with decaying noise through scipy, 0.3 s to 4 s long, the tail after the last word cut at 1.2 s and faded, because the game waits for the whole file); then `extra`. Strength multiplies every slider but Space. The bit-crusher and slap-back echo of the first version were dropped: they sounded like a bad recording.
- Choosing an effect: the voice_effect column (a file name or the shown name; `none` for no effect) wins, and an unticked effect named there gives no effect; then ghosts (Actor.IsGhost from the add-on, `mantella_actor_is_ghost`); then race. Only ticked effects count, and the player's own are checked before Mantella's. The page's race names (Draugr, Nord, ...) each stand for every race ID they cover, including the vampire ones (NordRace and NordRaceVampire). The column is added to the character table when missing, so override files can set it. The Bio Editor has a Voice effect list (src/ui/bio_voice_effect.py), with unticked effects marked "(turned off)", that writes the column into the personal override file it already saves to (CSV or JSON) and into the character table in memory, so the NPC's next conversation uses it.
- Volume: the last step for every line, after the lip file and the effect. The spoken parts (50 ms windows within 20 dB of the loudest) are brought to -19 dB, the level of vanilla clips measured the same way on 2026-11-17, raising a quiet line at most 12 dB; then the service's Volume (a percent of the sound's amplitude); then ffmpeg's alimiter at about -1 dB. Pocket TTS, ElevenLabs and Inworld keep theirs in config.ini under [TTS] (pocket_tts_volume, elevenlabs_volume, inworld_volume; registry field volume_setting), shown inside the service's own part of the page (SettingsUIConstructor routes a setting whose folded part names a service panel into that panel); a voice setup keeps `volume` in voice_setups.json. Read live, so a change is heard from the next line.
- Pitch: per voice on Voice Clips (a voice type, or an NPC with a voice of their own), -4 to +4 semitones on the page, kept in voice_clips/voice_settings.json by "<kind>/<key>" so swapping a clip keeps it. Applied before the effect with the same length-keeping pitch step. Going back to the voice type's voice drops the NPC's; giving an NPC's voice to their voice type moves it. Shared voices files carry it.
- Hearing an effect: Voice Effects (after Voice Clips) speaks the test sentence once with the TTS Service and keeps it for 5 minutes, so Hear it with the effect and Hear it without compare the same line and an online service is paid once. Hear it with the effect uses the Strength and sliders as they are on the page, saved or not, ticked or not. Try A Voice, Hear the cloned voice, Fix Pronunciation and the setups' Hear it play with the voice's Pitch and the service's Volume, as set on the page.
- Page: a Voice Effects ConfigValueGroup (page=TTS, foldable) drawn by SettingsUIConstructor.__render_voice_group, like Voice Clips.

## Several clips per voice (Step 7)

- Storage keeps its layout, so Pocket TTS, setups, Prepare all voices, refresh and the DLL's file handling don't change: the top chosen clip is the clip (voice_types/&lt;key&gt;.wav, npcs/&lt;key&gt;.wav); the other clips are the lines in candidates/&lt;kind&gt;/&lt;key&gt;/. A new `order` field in each candidate's .json (ClipInfo) gives its place in the chosen list (1, 2, ... below the top clip); 0 = not chosen. A new `hand_picked` field on the clip's .json is set by any change on the page and stops topping up. ClipStore.voice_lines(kind, key) returns [clip] + chosen candidates by order. Unpublished, so no migration: test voices from before Step 7 are cloned again on first use; delete leftover try_ voices on test accounts by hand.
- Buttons on the store: Use this one = swap the clip and the candidate, each taking the other's order (choose_candidate, extended). Add = give the candidate the order just after the last clip the TTS Service takes, shifting the rest down. Take out = order 0; taking out the top clip promotes the next chosen one; the last chosen clip can't be taken out. Find more clips = add the order-0 candidates' lines to turned_down, delete them, and ask the game for 4 more (MORE). When the game sends none, clear turned_down and ask again once, so the old ones come back.
- What a service takes: ClipVoiceService.lines_used(kind, key) cuts voice_lines by the service's MOST_SECONDS: one-clip services (Pocket TTS, setups) take the top one; Inworld MOST_SECONDS = 30 (stop before a clip that would pass 29.5 s with the gaps, so Inworld's 30 s cut never lands mid-word); ElevenLabs MOST_SECONDS = 120. The page's Cloned from group is lines_used of the TTS Service; Other clips is every other line, in list order.
- Online voice key: OnlineCloneService hashes the files lines_used gives (clip_hash of each, in order, hashed together), stored where the single clip's hash is now (online_voices/&lt;service&gt;.json "clip"). Any change to what the service takes, or a replaced game file, changes it, so the next line clones again and VoiceKeeper.delete_later removes the old voice.
- clone(name, clip_paths, language) takes the list. Inworld: decode each with audio_cleanup.decode, resample to one rate (the first clip's, at least 22.05 kHz), join with 0.5 s of silence, write one 16-bit WAV to a temporary file, send as one voiceSamples entry. ElevenLabs: one multipart ("files", ...) entry per clip. ElevenLabs refusing for a full plan (voice_limit_reached and the like) while the voice already has an old copy: delete the old copy now (not delete_later), then clone once more; only then raise CloneRefused.
- Lines asked for: ClipRequest.count comes from the service asking (ClipVoiceService.synthesize → ClipRequests.ask_for(..., count=)); a stand-in voice type's request keeps it, and Give this NPC their own voice takes it from the TTS Service shown on the page. Registry fields per service: `clip_lines` (default 4, ElevenLabs 10), `clip_seconds` (0 = top clip; Inworld 29.5, ElevenLabs 120) and `fill_seconds` (Inworld 25, ElevenLabs 60). A new voice's delivered lines are filed chosen, in delivery order. Prepare all voices keeps count 1.
- First line in the NPC's own voice: GameStateManager.__update_context → __get_voices_ready (once per NPC per conversation) → ChatManager.get_voices_ready → ClipVoiceService.get_ready_for, which asks (ClipRequests.ask_for, same as synthesize) and, with make_ahead, VoicePreparation.make_soon. ClipRequests.requests_for_reply records FIRST requests in `on_the_way` until collect takes them in; ClipVoiceService.__wait_for_own_voice waits on a stand-in pick (voice_picker.STAND_INS) for those, FIRST_LINE_WAIT_SECONDS = 10, looking in the folder every 0.5 s, and marks them `waited_for`; the wait ends at once when ChatManager stops the reply (ClipVoiceService.stop_waiting, set to ChatManager.__stop_generation.is_set in __speak_with_chain), because Conversation's stop waits for the line being made. In a group, make_soon runs at below-normal priority (Soon.background, sets preparing._background.on). mantella_voice_clip_delivered is handled outside the request lock, since the request the first line answers holds it. ClipVoiceService.change_voice no longer makes a stand-in while the voice type isn't settled. Tests: tests/tts/test_first_line_voice.py and the make_soon tests in tests/voice_clips/test_preparing.py.
- Topping up: a registry field `fill_seconds` (Inworld 25, ElevenLabs 60, others 0). In synthesize, when the voice isn't hand_picked and voice_lines' seconds are under fill_seconds, ask the game for the missing lines (count = clip_lines minus lines held, excluding the lines held), at most once per voice per run (__can_ask; no_more stops it when the game has none). The lines that come back are filed chosen at the end of the list. The line speaks with what the voice has; the changed hash clones again from a later line.
- Tried voices go away: TRIAL_PREFIX, clip_voice's line_to_hear, kept_voices.use_trial_voice, remove_trial_voices, OnlineCloneService.__clear_leftover_trials and the TRYING_NOTE. move_saved_voice compares the list hash; the NPC's chosen candidates move with the clip to the voice type (ClipStore.use_npc_clip_for_voice_type) so the voice isn't cloned again.
- Page: Gradio 4.28 has no gr.render, so the groups have fixed rows: Cloned from 16 (MOST_CHOSEN), Other clips 20 (chosen ones the service can't fit, plus what Find more clips brings), shown or hidden per voice and per view. Each row is a gr.HTML (a round play button driving a plain audio element, the line's file name, its length) and its one gr.Button. The audio comes from Mantella's own server: voice_files_route serves /voice_clips/<kind>/<key> (the top clip) and /voice_clips/<kind>/<key>/<line> (the others). The TTS Service dropdown (SettingsUIConstructor passes it in, as for Voice Setups) redraws Change a voice on change. Find more clips first unchooses the chosen clips no service in use takes (ClipStore.keep_chosen), so it swaps exactly the clips the list shows under Other clips. The 3-second timer that updates Prepare all voices also checks whether clips arrived for the shown voice, or new voices for the list, and redraws only then (page only, no work in game). The line under the list and the "used by" tags read the other services in use from config (Backup Voice Service, the per-NPC ones serving in game). Check both views with a headless Chrome screenshot before calling the layout done.
- Shared voices file: each pick gets "lines" (the chosen lines below the top, in order); import asks the game for all of them (IMPORT with several lines) and files them in that order.
- Tests: tests/voice_clips (filing order, voice_lines, Use this one, Add, Take out, Find more's swap and start-over, topping up, import), tests/tts/test_online_services.py (re-clone when the list changes, lines_used and Inworld's 30 s cut, Inworld's join, ElevenLabs' several files, ElevenLabs' full-plan retry), tests/tts/test_voice_page.py (both views, the redraw on a service switch, Add greyed when Inworld is full, "used by" tags).

## Sounds and directions (Step 8)

- What a service takes: `VoiceServiceInfo.voice_tags`, a function of the settings returning `VoiceTags(sounds, directions)` (src/tts/voice_tags.py). None = takes nothing. Inworld's (src/tts/inworld.py `voice_tags`): `SOUNDS` when `inworld_audio_tags`, directions when `inworld_directions` and `inworld_model == "TTS-2"`. A new service only adds its own function and settings.
- Whose service: `voice_tags.tags_for(config, character)` = the character's `tts_service` column, otherwise the TTS Service, the same order as `ChatManager.generate_sentence`.
- Prompt: conditions `audio_tags` and `directions` (`conditions_for`, any NPC in the prompt) are merged into `conditions` in `context.generate_system_message`, and `{voice_sounds}` (`sounds_text`) is filled there. The speaking prompts became merged prompts (`PROMPT_CONDITIONS`: skyrim_prompt, skyrim_multi_npc_prompt, skyrim_multi_npc_director_prompt, skyrim_npc_initiative_prompt, skyrim_radiant_prompt, plus skyrim_game_master_npc_prompt) with their prompt type passed to `PromptChecker`. The default text shares `PromptDefinitions.VOICE_TAG_RULES`; skyrim_prompt's "You cannot respond with brackets" line says "round brackets" while a part is unlocked.
- Reading the reply (`ChatManager.process_response`): only while `conditions_for` is true for the reply's characters, the accumulator keeps `[` `]` (`clean_sentence(keep_square_brackets=True)`), the narration parser is built without `[` `]`, and `voice_tags_parser` (after `sentence_end_parser`) runs `voice_tags.split` on each sentence: clean text to `SentenceContent.text`, the service's text to `SentenceContent.voice_text`. Merged short sentences (`append_other_sentence_content`) join `voice_text` too. The tags of a sentence with no words are kept per speaker in `sentence_generation_settings.held_voice_tags`. The text left at the end of the stream goes through the same parser. `voice_text` stays None for a line without tags (the service says the text as it is). The accumulator and `sentence_end_parser` cut with `cut_outside_brackets` (src/llm/output/sentence_end_parser.py): never inside an open `[`, waiting at most 150 characters for its `]`. `actions_parser` takes keywords out of `voice_text` too.
- Speaking: `generate_sentence` → `_speak_as_character(..., voice_text)` → `ClipVoiceService.synthesize(voice_text=)`; `tts_synthesize` says `voice_text` instead of the line only when the service has `voice_tags`. Lip files, file names and the backup service keep the clean line. Inworld's `speak_with` sends the text as it is: the tags are already Inworld's.
- Sound words in brackets that the speaker's service doesn't make (Inworld's full list, `SOUND_WORDS`) are dropped, never taken for a direction.
- Tests: tests/tts/test_voice_tags.py (split, Inworld's settings, the prompt conditions and the unlocked prompt parts), tests/test_output_manager.py (a streamed reply: subtitles without tags, what the service gets, a direction kept to its sentence, merged short sentences, action keywords, a full stop inside a direction, both switches off, an NPC on another service), tests/tts/test_online_services.py (Inworld gets the tags, ElevenLabs doesn't).

## More online services (Step 9)

| | HeyGen (src/tts/heygen.py) | Qwen (src/tts/qwen.py) | Boson AI (src/tts/boson.py) |
|---|---|---|---|
| Address and key | api.heygen.com, X-Api-Key, HEYGEN_SECRET_KEY.txt | `https://{workspace}.ap-southeast-1.maas.aliyuncs.com/api/v1`, Bearer, QWEN_SECRET_KEY.txt + `qwen_workspace_id` | api.boson.ai/v1, Bearer, BOSON_SECRET_KEY.txt |
| Model | `heygen_model`: heygen-voice-1-turbo or heygen-voice-1-turbo-free | qwen-audio-3.1-tts-plus (a voice only works with the model it was cloned for) | higgs-tts-3 |
| Clone | POST /v3/models/audio/voices, mode instant, one base64 WAV; poll GET .../voices/{id} until ACTIVE | POST /services/audio/tts/customization, model voice-enrollment, create_voice, prefix mantella, data URI at 24 kHz or more; poll query_voice until OK | POST /audio/voices with ref_audio and ref_text (src/voice_clips/transcripts.py) |
| Clips | joined, up to 60 s | joined, up to 30 s | joined, up to 30 s |
| Speak | POST /v3/models/audio/tts, then download data.audio_url | POST /services/audio/tts/SpeechSynthesizer, then download output.audio.url; a direction goes in instruction | POST /audio/speech, WAV bytes |
| Built-in voices | Nadine; a male voice looked up once (public, en, male) | xunanchuan_v3.1, longanhuan_v3.1 | jake, chloe |

- Shared: `joined_clips(clip_paths, lowest_rate)`, `download` and `clone_in_background` in src/tts/online_service.py. `clone_in_background` waits up to 30 s for a voice HeyGen or Qwen makes in the background, asking every 2.5 s (HeyGen allows 30 requests a minute). A voice not ready by then is remembered by service, account, voice name and clips: the line goes to the backup service, and the next line asks about that voice once instead of cloning again. A voice the service failed to make is deleted there; `rewrite_tags(text, sound_names)` in src/tts/voice_tags.py turns Mantella's sound words into the service's, drops every other bracket ([reset] too) and keeps one of two side-by-side tags, and returns the first direction for Qwen.
- One voice that can't be made: `CloneFailed` (HeyGen FAILED, Qwen UNDEPLOYED, Boson with no words heard in any clip) is remembered in `online_service._failed` by (service, voice, clips hash) for the session; `prepare_voice` then gives that voice the built-in voice (or the one cloned before) without asking the service, and tells it once with `FAILED_VOICE`. `CloneRefused` still turns cloning off for the whole service for 5 minutes. HeyGen's refused Turbo Free model is `CantSpeak`, checked before a missing voice.
- Settings: `heygen_model`, `heygen_audio_tags`, `qwen_workspace_id`, `qwen_audio_tags`, `qwen_directions`, `boson_audio_tags`, and `heygen_volume`, `qwen_volume`, `boson_volume`. The online parts of the page come from `ONLINE_SERVICE_GROUPS` (tts_definitions.py) and `SERVICES` (src/ui/online_voices_ui.py).
- Clip words for Boson AI: src/voice_clips/transcripts.py loads the Speech-to-Text choice (`stt_backends.chosen` + `build_backend`) once per clone for the clips without words, and keeps them in voice_clips/clip_words.json by the clip's sound hash. It doesn't use the in-game transcriber, so a large Whisper on the graphics card loads a second time for a few seconds, once per new voice.
- Checked live on 2026-11-18 with free keys: HeyGen (Turbo Free) and Boson AI both speak with their built-in voices, clone from a game clip, reuse the voice and delete it; both took the sound tags. HeyGen wants the clip as audio/x-wav. HeyGen's paid Turbo refuses every line on an account without credit. Boson's clip words came from Parakeet (a name was misheard; the clone still worked).
- Still not checked: HeyGen's Turbo price, and all of Qwen (needs a Workspace ID): its built-in voices in English, its sound tags with a cloned voice, and where its 30-second clip setting goes in the request.
- Tests: tests/tts/test_more_online_services.py (clone once and reuse, swap, deleted on the website, refused, Check my key, each one's request), tests/tts/test_voice_tags.py (`rewrite_tags`, the switches), tests/tts/test_voice_page.py (the three parts).

## How cloned voices sound (Step 10)

- src/tts/voice_style.py: `StyleSetting` (name = the config.ini setting and the key in voice_settings.json, the service, choices or a 0–1 number, an optional Model it needs), the four settings, `style_value(config, clips, pick, setting)` (the voice's own by `clip_owner`-style kind and key, else the page's, read live from the definitions like Volume), `settings_for(config, service)` and `shared_settings` for the friend's file.
- Storage: `ClipStore.voice_setting` / `set_voice_setting` / `voice_settings` / `set_voice_settings`; Pitch is now one of them. `remove` drops the whole entry; `use_npc_clip_for_voice_type` copies it. picks.py writes them as `style` next to `pitch`.
- Each line: `ClipVoiceService.voice_into` calls `speak_line(text, voice, out, pick)`; `OnlineCloneService` passes the pick down to `speak_with(..., pick)`, and `self.style(pick, setting)` reads it. `clone(..., pick)` likewise. Test buttons and Hear the voice go through `voice_into`, so they hear the voice's settings.
- Similarity: `OnlineCloneService.clone_settings(pick)` (HeyGen: the HeyGen value of its Similarity) is added to the stored clips hash (`<hash>|max`), so `prepare_voice` and `voice_ready` clone only the changed voice again and delete the old one. `clone_in_background` keys running clones by it too. Voices cloned before this have no `|…` part, so they are cloned once more.
- Requests: HeyGen `expressiveness_boost` on every line and `similarity` when cloning; Inworld `deliveryMode` with TTS-2; Boson `boson_text(text, expressiveness)` puts `<|prosody:expressive_low/high|>` first and after each mood.
- Page: `ConfigValueTag.slider` draws a `ConfigValueFloat` as a slider; `__render_settings` (the services' parts) now honours `shown_when` like a section does. The Voice Clips controls are drawn once per setting and shown for the service the list follows.
- Tests: tests/tts/test_more_online_services.py (HeyGen expressiveness and similarity), tests/tts/test_online_services.py (Inworld delivery), tests/tts/test_voice_tags.py (moods, Boson), tests/tts/test_voice_effects.py (storage, sharing, which value a line gets), tests/tts/test_voice_page.py (both pages).

## Settings per model (Step 11)

- The list: `data/voice_models.json` (kept in git: `.gitignore` lets it through), shipped with Mantella and never fetched. Top level: `services` → each service's `default`, `clones_per_model` (Qwen) and `models`. Each model: `id`, `name`, `price` (per million characters, null when unknown), `note` (shown instead of the price), `ends` (a date), `skips` (config.ini names: style settings and the Audio tags or Directions switch), `defaults` (setting → value), `sound_symbols`, `voices` (`male`, `female`), `clip_seconds`, `fill_seconds`. Unknown fields are ignored, so older Mantella versions read newer files. **To add a model:** check it live with a free key (it must clone and speak with a cloned voice), then add its entry. Players get it with the next Mantella update.
- src/tts/model_catalog.py: `ModelCatalog` (`shared()`; reads the shipped copy), `ListChanges` (the player's `added` and `removed` model IDs, as JSON in the hidden `<key>_model_list`), `CatalogCopy` / `ServiceList` / `ServiceModel` (`takes`, `default_for`, `ended`, `unknown(id)`), and `ServiceModels`, one per service (`ELEVENLABS_MODELS` … `BOSON_MODELS`, `ServiceModels.of(name)`): `setting` (`<key>_model`), `stored_setting` (`<key>_model_settings`), `picked(config)` reads the page live (`live_value`), `resolve` (ID or old name, else the typed ID), `list_setting` (`<key>_model_list`), `offered(config)` (Mantella's models minus the removed ones, then the added ones), `add` / `remove` / `put_back` / `first_offered` (each change also refreshes the Model setting's options), `options(config)` / `choices(current, config)`, `config_value` (a free-edit selection with names as `option_labels`), `refresh_options(selection, config)`, `with_limits`. `with_model_limits(config, info)` gives a service's info with the picked model's clip lengths.
- src/tts/voice_style.py: `StyleSetting` loses `model_setting`/`model` and gains `json_object`, `per_voice` and `per_model` (False for HeyGen's Similarity: one value for every model, on the page and per voice, never pinned or stored by model). `EXTRA_REQUESTS` has one `<key>_extra_request` per service (label "Fields to send", in a fold named `EXTRA_REQUEST_LABEL`). `ServiceStyle(config, service)` replaces `page_value` / `style_value` / `settings_for`: `settings(per_voice)`, `per_model_settings()` (what `switch_model` keeps per model), `page_value`, `default`, `voice_own` / `set_voice_own` / `voice_value` (by the picked model's ID), `extra_request()`, `switch_model(value, clips)` and `sync(clips)`. The visible settings stay flat config.ini keys holding the picked model's values; `<key>_model_settings` (hidden, in [TTS]) holds `{"current": id, "models": {id: {setting: value}}}`. `shared_values` replaces `shared_settings`.
- ClipStore: `voice_setting(…, model_id)` and `set_voice_setting(…, model_id)` keep a style value as `{model id: value}`; a plain value (before Step 11, or from a version-2 friend's file) counts as the picked model's until `pin_plain_values` (called by `switch_model`) ties it to the model it was set for. Pitch stays plain. picks.py writes format 3.
- ConfigLoader: `__carry_over_models` after reading config.ini gives each Model setting the player's list (`refresh_options`), turns saved names into IDs and runs `ServiceStyle.sync` (a Model changed in config.ini by hand switches to that model's values), and writes config.ini once when something changed. It runs on every start, also one that writes a backup (often the first after an update). Each `<key>_model` is an attribute.
- Services: `OnlineCloneService.MODELS`, `model`, `_limits()` (used by `clips_for` and `_top_up`), `_request_body(body)` (`merged`: the player's fields win, nested objects merge), `_check_model_refusal(status, message)` raises `ModelRefused(CantSpeak)` on 400/422 when there are extra fields (any refusal), or with an unknown model only when the service's words name the model (`_model_refusal`); a `VoiceGone` ("not found") that names an unknown model pauses the same way before `voice_exists` is asked. `ServiceModels.switched_on(config, name)` reads an Audio tags or Directions switch as off on a model that skips it (every service's `voice_tags`). `ServiceModels.choices(current)` and the page's dropdown keep an ended model that is still picked under its name. `ModelCantClone(CloneRefused)` for Qwen's `target_model` refusals. Qwen's `clone_settings` is the model ID; its built-in voices come from the model's `voices`. Inworld's Delivery and Directions and Boson's Expressiveness follow `takes`; HeyGen's sound symbols follow `sound_symbols`. The registry's fixed prices are gone and every online service has `model=_model_name(service)` for `mode_text`.
- Page: `__render_model_settings` (settings_ui_constructor.py) draws How models work, the Model, a note (typed or ended model), the settings for every model, the `#### Settings for <model>` heading, the per-model settings and the folded extra box, each setting in a column hidden when the model skips it. `ModelSettingsUI` (online_voices_ui.py) follows `model_ui.change`: `switch_model`, the heading, the note, the columns, the per-model values, and `shown_model_ui` (a hidden box NPC voices listens to). `ModelListUI` (online_voices_ui.py) draws Add model, Remove model, Put back Mantella's models and a status line under the Settings for list, one per service with models, shown with its service; its handlers refill both Model dropdowns and move them off a removed model. `cost_line` reads the model. NPC voices: `style_heading`, `cloned_for_note`, `view_for` / `other_services` with `with_model_limits`.
- Tests: tests/tts/test_model_catalog.py (the list, added and removed models, typed models, per-model values on the page and per voice, sharing), tests/tts/test_more_online_services.py (extra fields, refusals, typed models, Qwen cloned again, built-in voices, skipped settings), tests/tts/test_voice_page.py (the page following the Model, NPC voices following it, Add model and Remove model), tests/tts/test_voice_tags.py (`mode_text`).

## Iodine (Step 12)

- src/tts/iodine.py: `Iodine(OnlineCloneService)`, modelled on boson.py. api.iodine.dev/v1, Bearer, IODINE_SECRET_KEY.txt. `IODINE_MODELS = ServiceModels("Iodine", "iodine", "v2")`; the list entry has price 8 and voices zander (male) and mia (female). Registry: clip_seconds 29.5, fill_seconds 20, `IODINE_LANGUAGES` (40 codes: every Mantella language but ha and yo).
- Clone: multipart POST /voices with `file` (joined clips), `name` (64 characters at most), `consent=true`, `language=auto` and `transcript` (the clips' words from `words_for`, only clips with words, at most 2,000 characters). Without words when Speech-to-Text fails, and once more without them on `invalid_transcript`. Answers 201 `{"voice": {"id": "vc_..."}}`.
- Speak: POST /tts `{text, voice, model, format: wav, stream: false, language (when Iodine speaks it), temperature}`, raw WAV back. `IODINE_TEMPERATURE = StyleSetting("iodine_temperature", ..., 1.0, low=0, high=2)`, per model and per voice. The whole line goes in one request.
- Other calls: DELETE /voices/{id}; GET /voices lists Iodine's own voices too, so `plan_is_full` and Check my key count only `custom` (or `vc_`) voices against 50, and `voice_exists` searches the list (there is no call for one voice).

| Iodine's answer | What Mantella does |
|---|---|
| 401 | clone: `BadKey`; speak: `CantSpeak` |
| 402 insufficient_credits | clone: `CloneRefused`; speak: `CantSpeak`, both with the billing page |
| 400 too_many_voices | `PlanFull` |
| 400 audio_too_short, audio_too_long, invalid_audio, missing_audio | `CloneFailed` |
| 400 unknown_voice or 404, for a cloned voice | `VoiceGone`: cloned again |
| 400 invalid_language | `CantSpeak` |
| other 400 or 422 | `_check_model_refusal`, else this line only |
| 502 or 503 (busy, or the long-line bug) | `RuntimeError`: tried once more, then the backup |

- The length limit, measured live on 2026-11-21: plain English up to 275 characters works; 276 and longer fail at once with Cloudflare's "502 Bad Gateway" page, with wav or mp3, streaming or not, and on Iodine's OpenAI-style address too. It counts characters, not bytes (200 Japanese characters work), and cues count. Left alone as Iodine's bug: no splitting.
- Cues: `IodineCues(ServiceCues)` turns the line `voice_tags.split` gives into Iodine's. `ServiceCues` (voice_tags.py) is the interface for a service that writes tags its own way.

| The AI writes | Iodine gets |
|---|---|
| [happy] … [sarcastic] (Iodine's 12 emotions) | {happy} … {sarcastic} |
| [laugh] [giggle] [sigh] [gasp] [sniffle] [sob] [cough] [clear throat] [shaky breath] [pause] [long pause] | {laughs} {giggles} {sighs} {gasps} {sniffles} {sobs} {coughs} {clears throat} {shaky breath} {pause} {long pause} |
| [whisper]…[/whisper], [soft], [loud], [emphasis], [fast], [slow] | {whisper}…{/whisper} and so on; a closer with no opener is dropped, an opener with no closer covers the rest of the sentence |
| any other short tag, with Directions on | the same words in curly brackets, in place |
| [reset], another service's sound, or a direction with Directions off | removed |

- A mood or direction with no words since the last one is dropped, also when a sound or word style sits between them; the sounds and word styles stay. A made-up sound of one or two words ending in a sound word ([small laugh], [deep breath], `made_up_sound`) counts as a sound, not a direction. Curly brackets in the AI's own words are removed.
- voice_tags.py: `VoiceTags.styles`, the `word_styles` condition (`WORD_STYLES`) and `{voice_styles}` (`styles_text`, filled in context.py). `split` keeps `[style]` and `[/style]` only for a service whose `styles` has them, and drops any other closing tag. "shaky breath", "pause" and "long pause" joined `SOUND_WORDS`, so no service takes them for a direction. `TAG_RE` and `tidy` are public for iodine.py.
- Prompts (prompt_definitions.py): `VOICE_TAG_LINES` (one line each, each inside its own condition), `voice_tag_rules(indent)` with the prompt's own indentation, `VOICE_TAG_EXAMPLES` and `voice_tag_example(indent, speaker, heading, plain)` (word_styles, then moods, directions, audio_tags; `plain` adds the no-tag line for Game Master NPC and NPC Initiative). `word_styles` joined the six speaking prompts' conditions and `VOICE_TAG_SITUATIONS`; `voice_styles` joined the allowed variables. The editor's condition help (`condition_meaning`) names the services from the registry (`voice_tag_services`, every switch on), so a new service is never left out.
- Settings: `iodine_audio_tags`, `iodine_directions`, `iodine_temperature`, `iodine_volume`, `iodine_speed`, `iodine_extra_request`, `iodine_model`, `iodine_model_settings`, `iodine_model_list`.
- Tests: tests/tts/test_more_online_services.py (the shared clone, swap, deleted and refused tests, the words sent with the clips, clips with no words, no Speech-to-Text, words turned down, Temperature per voice, language, no credit, only cloned voices counted), tests/tts/test_voice_tags.py (the cue table, emotion and direction side by side, word styles in `split`, the new sound words, what each service's prompt shows, the example reply in all six prompts, the editor's service names), tests/tts/test_model_catalog.py, tests/tts/test_voice_page.py, tests/ui/test_tts_page.py (Iodine on the page).

## Talking speed (Step 13)

- src/tts/voice_speed.py: `SpeedChange` (`apply` leaves a speed of 1 and any failure alone; `changed` does the work) and `FilterSpeedChange`, ffmpeg's `atempo` through `voice_effects.run_filters`. `audio_cleanup.clean_up(..., speed=, speed_change=)` applies it after the silence trim; `ClipVoiceService.voice_into` passes `speed_for(pick)`. That is before the lip file and before `finish_line` (Pitch, effect, Volume).
- src/tts/voice_style.py: `speed_setting(service, key, per_model)`, `SPEEDS` (one `<key>_speed` per `ServiceModels.all()`, plus `pocket_tts_speed` with `per_model=False`), `SETUP_SPEED` (`setup_speed`), `ServiceStyle.speed_setting()`, `SetupStyle(ServiceStyle)` (the page's value is the setup's `"speed"`; a voice's own is kept with the setup's name in place of a model ID) and `style_for(config, info)`. `ServiceStyle.__model_id` became `_model_id` so `SetupStyle` can change it. `ClipVoiceService._style` (moved up from `OnlineCloneService`); a voice setup's style is read fresh each line, like its Volume.
- Page: each online service's Talking speed is a per-model setting (`TTSDefinitions.get_speed_config_value`), drawn under Settings for <model> by `__render_model_settings`; Pocket TTS's sits after its Volume. voice_setups.py: `"speed"` in `FIELDS`, `empty_setup`, `normalized` (kept within 0.7 to 1.5) and `problems`; voice_ui.py: a slider after Volume. voice_clips_ui.py: one slider (`SPEED_SLOT`) that stands for the shown service's own speed setting; the style handlers now take the shown service and use `style_for`.
- Help texts' example for Settings Mantella doesn't have yet changed from `{"speed": 1.1}` to `{"seed": 42}`.
- Tests: tests/tts/test_audio_cleanup.py (the length changes and the pitch doesn't, 1 leaves it alone, a failure keeps the line), tests/tts/test_voice_effects.py (the lip file is made from the faster line; a voice's own value wins, per model and per setup), tests/tts/test_model_catalog.py (one per online service and model, one for Pocket TTS), tests/tts/test_voice_setups.py (the setup's range), tests/tts/test_voice_page.py (a slider in each service's part, one on Voice Clips).

## Not in scope

- Fallout 4: not supported by this work. Its code paths stay as they are.
- The services' own model lists (ElevenLabs' and Qwen's): they don't say which models take cloned voices or which settings, so Mantella's own list is used instead, plus the models players add (Step 11). New kinds of setting without a Mantella update: Settings Mantella doesn't have yet covers them until then.
- Our own copy of Kyutai's model, to skip the sign-in: we use Kyutai's own download.
- Measuring services next to Skyrim before building: we go with Kyutai's own Pocket TTS program as it is.
- Streaming sound before a sentence is finished: Mantella already voices sentence by sentence.
- Graphics card use for Pocket TTS inside Mantella: Kyutai's program is processor only. Players who want the graphics card add llama.cpp as a setup (ready-made in Step 2); Mantella doesn't download or start it.
- Other programs as Mantella's Pocket TTS program: audio.cpp and llama.cpp (rewrites that lag behind new Kyutai models; ready copies hold the April 2026 English model), the sherpa-onnx copy AudioUtilTTS ships (January 2026 model, English only, shrunk, no program to talk to), VolgaGerm's PocketTTS.cpp (abandoned, January model only, known noise bugs) and pockettts.cpp (one person's project, no Windows download). See Which program runs Pocket TTS.
- Shrunk models (Q8, Q4, --quantize) for Pocket TTS: saves about 90 MB per language at a small, untested cost in sound.
- Renting a graphics card (SkyrimNet): skipped, see the note under Step 5.
- Emotion words for services other than Inworld: each joins later by declaring what it takes (Step 8).
- One account for the AI model and voices (SkyrimNet's Fateless): the obvious route, OpenRouter, only offers ready voices, so it can't copy game voices.
- skyrimnet-pocket-tts as the Pocket TTS program: needs Python and PyTorch and a hand download of the model, speaks only English, errors instead of using a stand-in when a voice has no clip, has no licence, and can't list its voices for Mantella's XTTS option. Its good idea is kept: the server keeps a voice after one clip upload (the .safetensors cache). Pinning to the processor's fast cores is left out, since Skyrim wants those cores too.
- Reusing sound made earlier for the same text (CHIM): NPC lines almost never repeat word for word.
- Turning numbers into Japanese characters before speaking (CHIM): Pocket TTS doesn't speak Japanese.
- Searching other ports when the voice program is silent (CHIM): Mantella starts the program itself or has its address in the setup.

# Sources

- kyutai-labs/pocket-tts, its README, releases, serve docs and server source (tts_model.py, config/english.yaml), read 14 Nov 2026
- kyutai/pocket-tts and kyutai/pocket-tts-without-voice-cloning model cards on Hugging Face, read 14 Nov 2026
- SkyrimNet-GamePlugin, its FEATURES.md and LICENSE, read 14 Nov 2026
- chunkychud/skyrimnet-pocket-tts, its README and server source (src/skyrimnet_api.py, weights/skyrimnet.yaml), read 14 Nov 2026
- crajjjj/AudioUtilTTS, its 0.7.0 release notes and voice models page, read 16 Nov 2026
- KevinAHM/pocket-tts-onnx-export and Hugging Face mirrors of the export (ottomate/pocket-tts-ONNX, OpenVoiceOS/phoonnx-pocket-tts)
- kyutai-labs/pocket-tts rust/ (README, server.rs, download.rs, Cargo.toml) and the history of its config/english*.yaml files, read 16 Nov 2026
- lunahr/pocket-tts-ungated on Hugging Face, read 16 Nov 2026
- ggml-org/llama.cpp: docs/multimodal/tts.md, tools/server/README.md, PR #26871 (Pocket TTS support), read 16 Nov 2026
- EryriLabs/pocket-tts-GGUF, Serveurperso/pocket-tts-GGUF, cstr/pocket-tts-GGUF and idle-intelligence/pocket-tts-gguf model cards, read 16 Nov 2026
- 0xShug0/audio.cpp v0.9.5: README, docs/tts.md, docs/gguf.md, model_specs/pocket_tts.json, docs/reports, and audio-cpp/audio.cpp-gguf (files and discussion #21), read 16 Nov 2026
- k2-fsa/sherpa-onnx Pocket TTS docs, read 16 Nov 2026
- VolgaGerm/PocketTTS.cpp README and issues, and ServeurpersoCom/pockettts.cpp README, read 16 Nov 2026
- Mantella's XTTS download (xtts_mantella_api_server 1.5), latent_speaker_folder, checked 14 Nov 2026
- abeiro/HerikaServer (CHIM)
- audio.cpp and VoxCtrl's notes on its Pocket TTS package
- LocalAI text to audio
- Rankings and prices: Artificial Analysis TTS leaderboard and its open-weights view, read 14 Nov 2026
- ElevenLabs: Introducing Eleven v4
- Fish Audio Drama 3 licence and requirements
- Breeze TTS 2 model card and running it locally
- Mistral: Voxtral TTS
- Qwen3-TTS languages and an OpenAI-style Qwen3-TTS server
- Chatterbox Turbo
- Inworld: OpenAI SDK and TTS
- Inworld: voice cloning best practices (docs.inworld.ai/tts/best-practices/voice-cloning) and the clone voice API reference, read 17 Nov 2026
- ElevenLabs: Instant Voice Cloning and "How many voice samples should I upload", read 17 Nov 2026
- CHIM's tts folder (22 voice services) and its MeloTTS pronunciation list
