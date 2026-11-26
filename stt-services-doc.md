# Speech-to-Text: Picking the Best Options

Nov 14, 2026 · @Yuji

## What it does

Speech-to-text is how Mantella turns what the player says into the microphone into the player's line. This work has two parts:

1. **The best options.** Find and offer the best speech-to-text options, both on the player's own PC and online, and say which one suits which player.
2. **How Mantella connects to them.** Rebuild Mantella's speech-to-text so it can use as many options as possible in a smart way, and so new ones can be added later without new code.

Two other Skyrim AI mods, CHIM and SkyrimNet, already solved parts of this. What we take from them, and the mistakes we avoid, are marked in the plan under the step they shape.

The doc follows the same order: Part 1, Part 2, then the plan that builds all of it.

What players get:

- **Better choices on the PC.** A faster model that understands 25 languages (Parakeet) and a faster version of the largest Whisper. All free, all offline.
- **Real online choices.** Pick Online Service, pick a service like Groq or Deepgram from a second list, add the key, and play. Nothing runs on the PC, so the game keeps the whole graphics card.
- **Anything else that speaks a common format.** A program on another PC at home, a new online service next year: pick the format, type the address, done.
- **Fewer misheard names.** A longer list of the names the player is likely to say, sent with every line.

The trade-off between the two sides:

|  | On your PC | Online |
| --- | --- | --- |
| Cost | Free | Usually 1 to 4 US cents per hour of play |
| Internet | Not needed | Needed |
| Load on the PC | Uses the processor or graphics card the game also needs | None |
| Accuracy and languages | Depends on the model and the PC | Usually the best available, dozens of languages |

## Words used in this doc

A few words come up again and again. This is what they mean here.

| Word | What it means |
| --- | --- |
| Speech-to-text | Turning what the player says into the microphone into written text. Mantella sends that text to the AI as the player's line, exactly as if they had typed it. |
| Model | The trained "brain" that does the listening. Different models trade speed against accuracy. Bigger models hear better but need a stronger PC, or cost more online. |
| Speech program | The program on the PC that loads and runs a model. One program can run many models. For example, the Whisper program can run every Whisper size, plus versions other people trained further. |
| On your PC (local) | The model runs on the player's own computer. Free, works offline, but uses the same processor and graphics card the game needs. |
| Online service | A company runs the model on its own computers. Mantella sends the recording over the internet and gets the text back. Needs an account and usually costs a little per minute of speech. |
| Format | The exact way a request must be written, like a form to fill in. Many services and programs accept the same form as OpenAI, so one piece of Mantella code can talk to all of them. |
| Ready-made choice | A named entry in Mantella's lists, like "Groq" or "Parakeet", with every detail already filled in. |
| Key | A long password the online service gives you when you sign up. Mantella sends it with each request so the service knows who to bill. |
| Hint | Extra text sent with the recording, such as "This is a conversation with Balgruuf and Proventus in Dragonsreach." It helps the model spell names it has never heard. |
| Words to listen for | The same idea as a hint, but as a list of single words or names (Balgruuf, Proventus, Dragonsreach). Some services only accept this form. |
| Error rate | Out of every 100 words spoken, how many the model gets wrong. Lower is better. 6% means about 6 wrong words in 100. |
| Making things up in silence | Whisper models sometimes "hear" a phrase in pure silence or noise, often "Thanks for watching", because they learned from YouTube videos. Mantella throws away a list of these known phrases. |

## How voice input works today

Mantella offers two models on the PC, Moonshine and Whisper, plus a hidden, half-finished way to use an online service. Both sides have real gaps.

What happens when the player speaks:

1. Mantella listens to the microphone and notices, on the player's own PC, when they start and stop talking.
2. When they stop, it hands the recording to one of three things: Moonshine on the PC, Whisper on the PC, or (if **External Whisper Service** is turned on in the advanced settings) a Whisper server somewhere else.
3. With the recording it sends a short hint: "This is a conversation with Lydia and Hulda in Whiterun." This helps the service spell the names right.
4. The text comes back and becomes the player's line.

**Gaps in the options (Part 1 fixes these):**

- **Moonshine only understands English,** and its small sizes mishear more than the other options.
- **Whisper on the PC only uses NVIDIA graphics cards.** Players with AMD or Intel cards run it on the processor, where the accurate sizes are slow.
- **Mantella's Whisper program is old** (version 1.0.3). It does not know the newer, faster large-v3-turbo model.
- **No model knows Skyrim.** "Balgruuf", "Dragonsreach" and "Fus Ro Dah" are often misheard; only the hint helps.
- **Online, only OpenAI and Groq really work,** and only with older models. Dedicated speech companies like Deepgram and ElevenLabs are missing.
- **Every OpenAI model Mantella can use today stops working on 26 February 2027.**

**Problems in how Mantella connects to them (Part 2 fixes these):**

- **Every option is a special case.** Each one is handled by its own branch inside one long piece of code, so adding an option means changing that code.
- **The list is fixed.** A new model needs a Mantella update, except for the hidden trick of typing a full model name into Whisper Model.
- **The online option is hidden.** The player must pick Whisper, open the advanced settings, turn on External Whisper Service, then pick a service in a second list.
- **One model list for everything.** The **Whisper Model** list mixes PC model sizes (tiny, base, large-v3) with online names (whisper-1). The player has to know which ones the online service accepts, or the request fails.
- **Addresses only work if they contain "openai".** Any other address is sent without the key, so paid services like Mistral, Together or Fireworks are turned away.
- **The key is shared.** It reads `STT_SECRET_KEY.txt`, and if that file is missing it quietly uses the chat AI's key from `GPT_SECRET_KEY.txt`. Someone using OpenRouter for chat and Groq for speech gets a confusing error.
- **A missing key stops Mantella.** It shows an error and waits for Enter, then quits.
- **No way to check a setup without playing.** The player only finds out the key or address is wrong when they talk to an NPC and nothing happens.
- **Names are only partly sent.** The hint names the NPCs in the conversation and the location, nothing else, and only some options use it.
- **Proactive Mode gets expensive online.** That option re-sends the whole recording every 0.3 seconds while the player talks. On a PC that is free; online, every re-send is billed.

## Part 1: The best options

Which speech-to-text options Mantella should offer, on the PC and online, and which one suits which kind of player.

### Services we will offer

Players will pick from 10 choices. The Speech-to-Text Service list holds the 3 PC choices and Online Service. Picking Online Service shows a second list, Online Service, with the 6 online choices. Custom Service is the last choice in the Speech-to-Text Service list, and picking it shows its own settings. Six choices are new; the other four exist today and get updates.

| Choice | Where it runs | New or existing | What the player gets | Plan step |
| --- | --- | --- | --- | --- |
| Moonshine | Your PC | Existing | No change. Stays the default for new players, but recommended only for weak laptops. | None |
| Whisper | Your PC | Existing, 1 new model | The Model list gains large-v3-turbo (fast and accurate on NVIDIA cards). | Step 4 |
| Parakeet | Your PC | New | Fast and free without a graphics card, 25 European languages. Becomes the default only if it passes the in-game name test. | Step 6 |
| OpenAI | Online | Existing | Moves to gpt-transcribe before today's models stop on 26 February 2027. | Step 1 |
| Groq | Online | Existing, hidden today | Picked straight from the Online Service list. The cheapest, about 1 cent per hour. | Step 2 |
| Mistral | Online | New | Strong at European languages. Lowest online priority. | Step 5 |
| Deepgram | Online | New | The recommended online choice: very fast, accurate, $200 free credit. | Step 7 |
| ElevenLabs | Online | New | Among the most accurate. Suits players who already pay for ElevenLabs voices. | Step 7 |
| OpenRouter | Online | New | Reuses the OpenRouter chat key when chat runs through OpenRouter: one key, one bill. Lowest priority. | Step 8 |
| Custom Service | Your PC, another PC at home, or online | New, replaces External Whisper Service | Anything that accepts a known format: whisper.cpp (for AMD and Intel graphics cards), Speaches, LocalAI, Together, Fireworks. | Step 2 |

Not offered:

- **Google, Microsoft Azure and AssemblyAI** (see [Online services](#mjj77yv1phs.55653)).
- **Translating the player's speech to English for the other options** (CHIM does this for its services). Today's chat AIs understand the player's own language directly, so translating first only loses nuance. It helps only with a weak chat AI, and OpenAI's translation model is being retired. Mantella's existing **Whisper STT Translate** setting stays as it is: it only works with Whisper on your PC, and no other option gets it.
- **A gateway service that reaches other companies' models with one key** (CHIM offers Inworld). OpenRouter already covers this, and any gateway that copies OpenAI's form works through Custom Service.
- **Chrome's built-in speech recognition** (CHIM's "Free Auto STT" keeps a Chrome window open for it). It is free, but fiddly, and Chrome sends the sound to Google anyway.

Listening while the player talks (Deepgram Flux) and reading tone of voice wait for [Later, not in this round](#mjj77yv1phs.30706).

### All options compared

There is no single best option: the right one depends on the player's PC, language and budget. The table lists everything worth offering; the best pick for each kind of player follows below it.

| Option | Where it runs | Languages | Speed | Accuracy | Takes name hints | Cost | Setup |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Moonshine | PC, processor | English | Very fast | Lowest of these | No | Free | In Mantella today |
| Parakeet | PC, processor | 25 European | Fast (5 s of speech in about 0.15 s in onnx-asr's benchmarks; about 1 s in Mantella on an i9-13900HX with the 670 MB copy) | High (about 6.3% errors) | No | Free | New choice, 670 MB download |
| Whisper base / small | PC, processor or NVIDIA card | 99 | Fast | Fair | Yes | Free | In Mantella today |
| Whisper large-v3-turbo | PC, NVIDIA card | 99 | Fast on an NVIDIA card, slow on a processor | High | Yes | Free | New entry in the Model list, 1.6 GB download |
| Whisper large-v3 | PC, NVIDIA card | 99 | Slow | High (about 7.4% errors) | Yes | Free | In Mantella today, 3 GB |
| whisper.cpp | PC, any graphics card (separate program) | 99 | Depends on the card | Same as the Whisper model it runs | Yes | Free | Install the separate program, then Custom Service |
| Groq | Online | 99 | Very fast | High | Yes | About 1 cent per hour of play | Key |
| OpenAI | Online | Many | Fast | High | Yes | About 4 cents per hour | Key |
| Mistral | Online | Many, strong at European | Not measured | High | Words to listen for | About 3 cents per hour | Key |
| Deepgram | Online | Many | Very fast | High | Words to listen for | About 3.5 cents per hour, $200 free credit | Key |
| ElevenLabs | Online | 90+ | Fast | Among the highest | Words to listen for (small extra charge) | About 3 cents per hour | Key |
| OpenRouter | Online | Depends on the model | Fast | High | No (it has no field for them) | About 2.5 cents per hour | Key, or the OpenRouter chat key |

PC numbers come from public comparisons (see Sources). Online speed and accuracy are the services' own claims and public reviews; none of them has been measured inside Mantella yet. Costs assume 100 player lines an hour, 5 seconds each.

#### Best pick for each kind of player

| Kind of player | Best pick | Why |
| --- | --- | --- |
| New player, does not want to set anything up | Moonshine (the default); Parakeet once it passes the in-game name test | Free, offline, light on the PC |
| Has an NVIDIA card with room to spare | Whisper large-v3-turbo | High accuracy, fast, free, takes name hints |
| Has an AMD or Intel graphics card | whisper.cpp through Custom Service, or Parakeet on the processor | Mantella's own Whisper program cannot use these cards |
| Speaks a European language | Parakeet | Fast and accurate in 25 languages, free |
| Speaks another language | Whisper on the PC, or any online service | 99 languages |
| Wants the best accuracy and no load on the PC | Deepgram or ElevenLabs | Top accuracy; Deepgram's free credit lasts thousands of hours |
| Wants online but as cheap as possible | Groq | About 1 cent per hour of play |
| Already pays for OpenRouter for chat | OpenRouter | One key, one bill |

#### Default for new players

**Moonshine stays the default for now.** The default is what a player gets if they never open the Speech-to-Text settings, so it must work offline, with no key, on any PC. Parakeet becomes the default in a later update only if it spells Skyrim names at least as well as Moonshine in game tests. The default affects every new player, so it changes only after that test.

> **My view:** the strongest set for this round is Whisper large-v3-turbo for players with an NVIDIA card, Parakeet for everyone else on the PC, Deepgram as the recommended online choice and Groq as the cheap one. OpenAI matters mostly because many players already have a key, not because it is the best. Moonshine should stay available, but I would stop recommending it to anyone who has more than a weak laptop.

### Options on your PC

Two free, offline options are worth adding on the PC side: Parakeet and Whisper large-v3-turbo.

Mantella offers two models on the PC today:

- **Moonshine:** small and fast on a normal processor, but English only and less accurate.
- **Whisper:** many languages and sizes. The large sizes are accurate but slow without an NVIDIA graphics card.

| Option | What it is | Good at | Weak at | Effort |
| --- | --- | --- | --- | --- |
| Parakeet | A speech model by NVIDIA that runs well on a normal processor. CHIM recommends it. | Fast without a graphics card; slightly more accurate than the largest Whisper; 25 European languages; rarely makes things up in silence | Cannot take a hint, so fantasy names come out worse | New choice in the list, about 670 MB download on first use |
| Whisper large-v3-turbo | A faster version of the largest Whisper. SkyrimNet offers it. | About 8 times faster than large-v3 with nearly the same accuracy | Still wants an NVIDIA card | Small: add to the list |
|  |  |  |  |  |

#### Parakeet

Parakeet ([NVIDIA's speech model](https://openwhispr.com/blog/parakeet-vs-whisper-vs-nemotron)) is the most interesting. On a fast processor it turns 5 seconds of speech into text in about 0.15 seconds ([onnx-asr benchmarks](https://github.com/istupakov/onnx-asr)). Measured in Mantella (17 November 2026, the 670 MB int8 copy, i9-13900HX processor): about 1 second for the 5-second Test recording once loaded, against about 0.5 seconds for Moonshine tiny, and 3 seconds to load. Its error rate on the public comparison list is about 6.3%, against about 7.4% for the largest Whisper. It covers 25 European languages, where Moonshine covers only English. It is built differently from Whisper, so it rarely invents "Thanks for watching" in silence.

The catch: Parakeet has no way to take a hint. "This is a conversation with Balgruuf" cannot be passed to it, so Balgruuf may come out as "Bal Groove" more often than with Whisper.

**Decided: Parakeet is added as a choice.** It fills the biggest gap on the PC side: fast, free, and not English-only. Example: a French player with no graphics card to spare says "Balgruuf, avez-vous vu Proventus ?" Today their only free choices are Moonshine (English only, so it fails) or Whisper on the processor (slow). With Parakeet they get fast, accurate French text, with a chance that "Balgruuf" comes out as "Bal Groove". Whether it also becomes the default depends on the name test (see Default for new players).

Adding it is light work: the tool that runs it only needs pieces Mantella already ships for Moonshine.

#### Whisper large-v3-turbo

Mantella's copy of the Whisper tool (version 1.0.3) is too old to know "large-v3-turbo" by name, so it is missing from the list. It can still run it: given the full download name of a ready-made copy, it downloads and runs that copy. The Model list shows large-v3-turbo, and Mantella asks for the same ready-made copy that newer versions of the tool download under that name. The tool itself needs no update. One limit: large-v3-turbo was trained only to write down speech, not to translate, so the existing Whisper STT Translate setting gives poor results with it.

#### AMD and Intel graphics cards

Mantella's Whisper on the PC can only use NVIDIA graphics cards. Players with AMD or Intel cards fall back to the much slower processor. SkyrimNet does not have this problem. In Mantella, the existing whisper.cpp choice already fixes it: whisper.cpp is a separate small program that can use any graphics card, and Mantella connects to it. This only needs explaining in the Speech-to-Text page, not new code.

> **My view:** Parakeet is the most important PC addition, because it is the first free option that is fast without a graphics card and not English-only. Its weakness with names is real, but I expect it to matter less than it sounds: most lines contain one name at most, and the AI usually understands "Bal Groove" from context. That still needs testing before it becomes the default.

### Online services

Offer six online services as ready-made choices, plus Custom Service for anything else. Every one of them costs about 1 to 4 US cents per hour of play, so price should not decide which to recommend.

The cost column assumes a talkative player: 100 lines an hour, 5 seconds each (about 8 minutes of speech).

| Service | Default model | Price (official) | Cost per hour of play (estimate) | Why include it | Works like OpenAI's? |
| --- | --- | --- | --- | --- | --- |
| [OpenAI](https://developers.openai.com/api/docs/models/gpt-transcribe) | gpt-transcribe | $0.0045 per minute | \~4 cents | Most players already have a key. Mantella offers OpenAI today. | Yes |
| [Groq](https://console.groq.com/docs/speech-to-text) | whisper-large-v3-turbo | $0.04 per hour of speech, each line billed as at least 10 seconds | \~1 cent | Very fast and the cheapest. Mantella offers Groq today. | Yes |
| [Mistral](https://docs.mistral.ai/en/studio-api/audio/overview) | voxtral-mini-transcribe-3 | \~$0.0035 per minute (third-party report, not confirmed on Mistral's site) | \~3 cents | Strong at European languages, accepts a list of words to listen for. | Yes, except names go as words to listen for |
| [Deepgram](https://deepgram.com/pricing) | nova-3 | $0.0043 per minute | \~3.5 cents | $200 free credit, no card needed. That is thousands of hours of play. | No, its own format |
| [ElevenLabs](https://elevenlabs.io/pricing/api) | scribe\_v3 | $0.20 per hour of speech | \~3 cents | Among the most accurate. Many Mantella players already use ElevenLabs for voices. | No, its own format |
| [OpenRouter](https://openrouter.ai/docs/guides/overview/multimodal/stt) | openai/gpt-transcribe (gpt-4o-mini-transcribe retires with OpenAI's other models) | Same as the original maker, no markup | \~4 cents | Players who chat through OpenRouter can reuse that one key. | Yes, but no names |
| Custom Service (any address) | (typed by the player) | Depends | Depends | whisper.cpp on another PC, Together, Fireworks, and other services that copy OpenAI's format. | Yes |

Prices checked on 14 November 2026.

**OpenAI is retiring every model Mantella can use today.** whisper-1, gpt-4o-transcribe and gpt-4o-mini-transcribe all stop working on 26 February 2027 ([OpenAI notice](https://developers.openai.com/api/docs/deprecations)). The replacement for recordings is gpt-transcribe. Anyone on Mantella's current OpenAI setting will lose voice input that day, so this work has a deadline.

**Left out on purpose:** Google and Microsoft speech services (separate cloud accounts, complicated setup) and AssemblyAI (nothing the others don't already cover). Any service that copies OpenAI's format still works through Custom Service (see How it stays expandable).

> **My view:** recommend Deepgram first for online (free credit, very fast, takes a list of names), Groq second for players who want the cheapest, and ElevenLabs for players who already pay for it. OpenRouter is worth its small cost in code because one key for everything is a real convenience. Mistral is the lowest priority. The OpenAI retirement date makes switching OpenAI to gpt-transcribe the one online change that is not optional.

### Deepgram in detail

Deepgram is the strongest online choice for most players: fast, accurate, and the $200 free credit covers roughly 5,000 hours of play. CHIM (another Skyrim AI mod) lists it as one of its two recommended choices. It is online only: running Deepgram on your own computer needs a business contract and a Linux server ([Deepgram self-hosting](https://developers.deepgram.com/on-prem/)).

Deepgram offers two models that fit Mantella in two different ways.

#### Nova-3: send the recording when the player stops talking

This works the same way as every other service in this plan: Mantella notices the player stopped, sends the recording, and gets the text back. It is part of Step 7 of the plan.

- **Price:** $0.0043 per minute of speech, about 3.5 cents per hour of play ([Deepgram pricing](https://deepgram.com/pricing)).
- **Names:** Nova-3 does not take a hint sentence. It takes "words to listen for": up to about 100 per request, and Deepgram suggests sending the 20 to 50 that matter most ([Deepgram docs](https://developers.deepgram.com/docs/keyterm)). Names go in with the spelling we want, for example `Balgruuf`. Mantella always sends them (see Sending the right names).
- **A trap to avoid:** each word must be sent separately. If all the names are sent as one list with commas between them, Deepgram accepts the request without any error, but ignores the names completely. Nothing looks broken; names are just spelled wrong. CHIM's code has a different bug with the same result (see Step 10).
- **Punctuation:** Mantella must ask for it. Without it, Nova-3 returns one long string with no full stops or question marks, which makes the player's line harder for the AI to read.
- **"Um" and "uh":** Deepgram can keep or drop them. Mantella drops them, so the NPCs see "I didn't take it." whichever service the player picks, the same as Whisper, Moonshine and most services already do. How the player sounds is left to the tone-of-voice idea in the Later section.
- **Languages:** Nova-3 supports many languages, and a mixed mode for players who switch languages mid-sentence.

#### Flux: listen while the player is still talking

Flux is Deepgram's model for live conversation. Mantella would send the sound to Deepgram while the player is speaking, and Deepgram itself decides when the player has finished.

Why that matters: today Mantella decides the player has finished after a fixed pause, the **Pause Threshold** setting (0.25 seconds by default). That is always a compromise:

- Set it short, and "I need… um… your help" is cut off and sent as "I need".
- Set it long, and every line has an extra delay before anyone answers.

Flux listens to *what* was said, not only to the silence. It knows "I need…" is unfinished and "I need your help." is complete. Deepgram says it notices the end in about a quarter of a second ([Flux docs](https://developers.deepgram.com/docs/flux/quickstart)), and a setting controls how sure it must be before it decides.

- **Price:** $0.0065 per minute of sound sent. Mantella's microphone stays open the whole time it waits for the player, so sending everything would mean paying for silence. Mantella would keep its own "has the player started talking" check and only start sending once they do.
- **Languages:** English, plus a version that covers 10 languages.
- **Cost to build:** much bigger than anything else in this doc. It needs a connection that stays open while the player talks, and a new way of listening inside Mantella. That is why it is in the "Later" section, not in the plan.

> **My view:** Nova-3 now, Flux later. Flux is the most promising idea in the Later section, because cut-off sentences are a complaint that no amount of Pause Threshold tuning fully fixes. But it only helps Deepgram users, so it should come after the rest works for everyone.

## Part 2: How Mantella connects to them

How Mantella should be built so it can use as many options as possible in a smart way: new ones added without new code, each one sent the right information, and problems explained clearly to the player.

### How it stays expandable

Mantella should not need new code for every new model or service. It learns a small number of **speech programs** (for the PC) and **formats** (for sending a recording somewhere) once. After that, any model one of those programs can run, and any service or program that accepts one of those formats, works by filling in a few settings.

#### On the PC: speech programs

A speech program loads a model and runs it. One program can run many models, so adding a model is just typing its name.

| Speech program | Models it can run | Examples |
| --- | --- | --- |
| Whisper program (faster-whisper) | Any Whisper model saved in its format | The normal sizes, large-v3-turbo, trained for other languages |
| Moonshine program | The Moonshine models | tiny, base |
| onnx-asr | The models this tool supports | Parakeet, and others it adds over time |

#### Sending the recording somewhere: formats

A format is the form Mantella fills in to send a recording: the sound, the model name, the hint, the language. Many services and programs copy OpenAI's form exactly, so the same code that talks to OpenAI also talks to Groq, Together, or a free program running on another PC at home. A few, like Deepgram and ElevenLabs, use a form of their own.

| Format | Online services that use it | Programs you can run yourself |
| --- | --- | --- |
| OpenAI-style | OpenAI, Groq, Mistral (names sent as words to listen for), OpenRouter (no names), Together, Fireworks | whisper.cpp, Speaches (formerly faster-whisper-server), LocalAI, Parakeet servers like the one CHIM uses |
| Deepgram-style | Deepgram | Deepgram's own servers (business contract only) |
| ElevenLabs-style | ElevenLabs | None |

"Sending somewhere" does not have to mean online. A program on the same PC or on another PC at home works exactly the same way, just at a home address instead of a company's.

#### Ready-made choices

Every named entry in the Speech-to-Text Service and Online Service lists is a ready-made choice: a speech program or format with every detail already filled in.

- "Parakeet (on your PC)" = the onnx-asr program, with the Parakeet model filled in.
- "Whisper (on your PC)" = the Whisper program, with a recommended model filled in.
- "Groq" = OpenAI-style + Groq's address + Groq's recommended model + Groq's key.

Adding another named choice later is one new line in a list, not new code.

#### Adding your own

**Any model on the PC.** Every PC choice has a **Model** box. Its dropdown lists the recommended models, but the player can type the name of any other model that speech program can run. No separate "custom" choice is needed on the PC side.

Example: someone trains a Skyrim Whisper model for German and shares it. A German player picks Whisper (on your PC) and types that model's name into Model.

**Any service or program that accepts a known format: Custom Service.** It is the last choice in the Speech-to-Text Service list, after Online Service. Picking it shows its own settings, the same way picking Online Service shows the Online Service list. The player fills in:

- **Format**: OpenAI-style, Deepgram-style or ElevenLabs-style.
- **Address**: where to send the recording. Mantella accepts the short form (`https://api.groq.com/openai/v1`) or the full one (`https://api.groq.com/openai/v1/audio/transcriptions`) and adds the missing end itself.
- **Model**: the model name that service expects.
- **Key**: optional, pasted into the section's own Key box. Programs on your own PC usually need no key, and Mantella then sends none.

Example: a player runs Speaches on a second PC at home. They pick Custom Service in Speech-to-Text Service, choose OpenAI-style, type `http://192.168.1.20:8000/v1`, type the model `Systran/faster-whisper-large-v3`, and leave the key out. Their main PC's graphics card stays free for the game.

#### What this cannot cover

A new speech program or a service with a form of its own (Google, Microsoft Azure) still needs new code: one new piece per program or format, after which everything that uses it works. And not every service uses every part of the form: some ignore the hint or the language. Mantella sends them anyway; a service that does not use them simply skips them.

> **My view:** this is the most important decision in the whole doc. There are hundreds of speech services and programs, but only a handful of forms they accept, so building around forms instead of services is what makes Mantella keep up without constant updates. The risk is a confusing settings page; Format and Address only show while Custom Service is picked, so ordinary players only see the Speech-to-Text Service list, the Online Service list and Key box if they go online, and one Model box.

### Sending the right names

The most common speech-to-text mistake in Skyrim is a misheard name. Mantella will build one list of the names the player is likely to say, and send it to every option that can use it, in the form that option understands.

**What goes in the list**, most likely first:

1. The NPCs in the conversation (as today).
2. Every other NPC nearby.
3. The current location.
4. The player's own name.

Nearby places are left out: the game only tells Mantella the current location, and sending more would need a change to the game add-on.

**The list is an editable prompt.** It is a new prompt next to Mantella's other prompts, and it makes a plain list of names with commas between them, for example "Balgruuf, Proventus, Irileth, Dragonsreach, Dovahkiin". Players and modders can change what goes in, add names from mods or their own stories, or empty it to send nothing. Every option gets its names from this one list, so a change reaches all of them.

Example: a player adds "Ulfric" to the prompt because their story talks about him a lot. Whisper, OpenAI and Groq then get "Names: Balgruuf, Proventus, Irileth, Dragonsreach, Dovahkiin, Ulfric.", and Deepgram gets Ulfric as one more word to listen for.

Why a list and not a sentence: the options that take words to listen for need each name on its own. Cutting a sentence such as "This is a conversation with Balgruuf and Proventus" into names would lose names or keep pieces that are not names.

**How long it can be.** Whisper (on your PC, and online at OpenAI and Groq) only reads the last part of a long hint, about 220 word pieces, and silently drops the start, which is where the most likely names are. In English, 400 characters of Skyrim names is about 170 pieces, safely under. The same 500 characters in Russian is about 265 pieces, over the limit. So Mantella shortens the list by Whisper's own count, not by characters, dropping the least likely names from the end. The lists of words to listen for (Deepgram, ElevenLabs, Mistral) keep a 500-character cap.

**How it is sent**, depending on the option:

| Option | Form | Example |
| --- | --- | --- |
| Whisper on the PC, OpenAI, Groq, most Custom Services | The list as one line, after "Names:" | "Names: Balgruuf, Proventus, Dragonsreach." |
| Deepgram, ElevenLabs, Mistral | Words to listen for, each sent separately | Balgruuf · Proventus · Dragonsreach |
| Moonshine, Parakeet, OpenRouter | Not sent | These models cannot take names; OpenRouter has no field for them that every model behind it understands |

**Always sent, no setting.** Deepgram and ElevenLabs charge extra for words to listen for: about 1 cent more per hour of play on either. Mistral does not list a charge for them. Mantella sends the names anyway, because a misspelled name confuses the NPCs more than it costs.

**Whisper on the PC keeps the hint.** SkyrimNet turns it off by default because Whisper sometimes copies the hint into its answer. Mantella keeps sending it, and the safety check below catches the copies.

**Built ahead of time.** The list is rebuilt whenever the game sends new details (who is in the conversation, who is nearby, the location), not at the moment the player stops talking, so it never slows down the answer. The microphone starts listening before the game sends that turn's details, so the list uses the details from the turn before.

**Safety check.** If Whisper returns nothing but the hint itself, part of it, or the hint twice (it sometimes does when the player says nothing), Mantella throws it away, the same way it already throws away "Thanks for watching". Example: the player clicks to talk, then stays silent, and Whisper returns "Names: Lydia, Whiterun." That line is thrown away instead of becoming the player's line.

> **My view:** this is the best value for effort in Part 2. It improves every option that takes hints, costs nothing extra (except a cent an hour on Deepgram and ElevenLabs), and is mostly a matter of collecting names Mantella already knows.

### What the player sees and sets up

The player picks an option from the Speech-to-Text Service list (and, to go online, a service from the Online Service list) and plays. Online options also need a key, pasted into the Key box. Everything else has a sensible default for each option.

**Settings on the Speech-to-Text tab** (proposed):

The tab has two parts, each a fold that starts open, so the player can close the one they aren't using. **Talking** comes first: the microphone settings, with switches beside switches and boxes beside boxes, so no switch sits in a tall empty panel. Enable PTT beside Proactive Mode, with PTT Hotkey and Refresh Frequency right under them; then Audio Threshold, Pause Threshold and Listen Timeout in one row; then Allow Interruption, Cough Error Sound and Save Mic Input in one row. A setting that can't change anything is greyed out, for example PTT Hotkey while Enable PTT is off. **Service** comes second: Speech-to-Text Service beside Spoken Language, then only what the picked choice needs, then Test at the end of the page. Example: a player picks Whisper and sees Model beside Graphics Card or Processor, and Whisper STT Translate, and nothing about online keys.

- **Speech-to-Text Service**: Moonshine (on your PC), Whisper (on your PC), Parakeet (on your PC), Online Service, Custom Service.
- **Online Service**: shown only when Speech-to-Text Service is Online Service. Lists OpenAI, Groq, Mistral, Deepgram, ElevenLabs and OpenRouter. It sits right below Speech-to-Text Service on the same tab, not in the advanced settings. Example: the player wants Groq, so they pick Online Service, then Groq.
- **Key**: shown below Online Service. The player pastes the chosen service's key and presses Test (see The key).
- **Model**: shown for every choice. It remembers the model picked for each choice, so trying Groq does not lose the player's Whisper model; a choice never used before starts with its recommended model. The dropdown lists the other good models for that choice (for Whisper: the normal sizes, large-v3-turbo, and the player can type any other name. For online choices, once the key is in place, the dropdown also fills itself from the service's own model list, the way the OpenRouter chat model list does. Only speech models are kept: names with whisper, transcribe or voxtral for OpenAI, Groq and Mistral, Deepgram's speech models, and OpenRouter models that accept audio (each still needs checking for transcription). ElevenLabs keeps the fixed list, since its model list may not include Scribe. With no key, or if the call fails, the dropdown shows the ready-made suggestions.
- **Custom Service**: the last choice in Speech-to-Text Service. Picking it shows Format, Address, Model, Key and a time limit (see How it stays expandable). Example: an AMD player runs whisper.cpp on their own PC, picks Custom Service, and picks OpenAI-style and `http://127.0.0.1:8080/inference`.
- **Spoken Language**: the same setting as today, now used by every choice that supports more than English.
- **Graphics card or processor**: the existing setting, shown only for Whisper on your PC.
- **Test** button: sends a short sample recording that ships with Mantella through the chosen option and shows the text that came back and how long it took, or a plain message saying what went wrong (model not downloaded yet, no key, key refused, service unreachable). No need to start the game.

The old **External Whisper Service** switch, **Whisper Service** list, **Whisper Model** list and **Moonshine Model** list are replaced by Speech-to-Text Service, Online Service, Model, Key and Custom Service's settings.

**The key.** Each online service needs its own key, and the player pastes it into the Key box instead of making a text file. Example: the player chats through OpenRouter. They pick Groq, paste the Groq key and press Test. Later they switch to Deepgram: the Key box is empty, so they paste the Deepgram key. Switching back to Groq shows that a Groq key is saved. The key itself is never shown again, so it never reaches the browser.

- Behind the Key box, Mantella saves each key in a text file named after the service, next to `GPT_SECRET_KEY.txt`: `GROQ_SECRET_KEY.txt`, `DEEPGRAM_SECRET_KEY.txt`, `OPENROUTER_SECRET_KEY.txt` and so on. Mantella looks for key files in the mod folder first, then in its own folder, so the Key box saves over the file wherever Mantella already finds it, and creates it next to `GPT_SECRET_KEY.txt` only when there is none. Otherwise an old file in the mod folder would win, and the box would seem to do nothing. The player never has to make these files, but they are the same kind of key file the chat AI and the voice services already read. So when the voice services add ElevenLabs, they read the same `ELEVENLABS_SECRET_KEY.txt`, and the player enters that key once.
- Keys are never stored in config.ini, so they are never shared when a player posts their settings.
- An existing `STT_SECRET_KEY.txt` is copied once into the key file of the service the player was using (see Step 2), then no longer read. As a backup for every service it would send a Groq key to Deepgram, the same wrong-key error this work removes.
- The chat key in `GPT_SECRET_KEY.txt` is used for speech only when the speech service is the same as the chat AI's: OpenAI with OpenAI, OpenRouter with OpenRouter. Many players use one OpenAI key for both. It is used only when that service's own key file is empty, and never sent to any other service or address: a player who chats through NanoGPT and picks OpenRouter for speech pastes an OpenRouter key. The chat AI keeps `GPT_SECRET_KEY.txt` in this round.
- Custom Service sends no key when its Key box is empty.

**While playing.** Nothing changes. The player talks, stops, and their line appears. With a fast service (Groq, Deepgram) the text should come back in well under a second.

**When something goes wrong**, Mantella never quits or waits for Enter. "Cough sound" below means the Cough Error Sound setting, which is on by default:

| What happened | What the player gets |
| --- | --- |
| No key | A message in the Mantella window saying to paste the key into the Key box on the Speech-to-Text tab. The cough sound plays when they speak. Typing still works. |
| Wrong key or no credit left | A message saying the service refused the key or the account is out of credit. Cough sound. |
| Service slow or down | Mantella tries once more, and gives up after about 8 seconds in total. Cough sound, so the player knows to say it again. |
| Model name the service doesn't know | A message naming the service's recommended model. |

**No fallback to a model on the PC.** When an online service fails, Mantella does not switch to Moonshine or another PC model. Example: the Wi-Fi drops while the player says "Watch out, a bandit!" to Lydia. Mantella tries once more, gives up after about 8 seconds, plays the cough sound and shows a message; the player says it again once the connection is back, or types it. Dropped connections are rare, and the chat AI also needs the internet, so the conversation would stall anyway. Keeping Moonshine loaded just in case would slow start-up and use memory the whole time.

**Proactive Mode** (text updates while the player is still talking) is switched off automatically for the services in the Online Service list, and its description says so. Custom Service keeps it as the player sets it, because Mantella cannot tell whether the address is a paid service or a free program at home; the description warns that online addresses are billed for every update. Each update would be a separate paid request, and with Groq each one is billed as 10 seconds: 6 seconds of speech becomes about 20 requests and over 3 minutes billed. The fast services answer in a fraction of a second anyway.

> **My view:** the Test button is the most useful single addition for players. Most "my voice doesn't work" problems are a wrong key, a wrong address or a model that never downloaded, and today players only find out in game. Every error message should name the exact file or setting to fix.

## The plan

Build it in ten steps, most useful first, so PC and online steps are mixed. Each step says which part of this doc it delivers. Each one can be tried in game on its own.

**How it is being built.** The steps are grouped into four parts, each tried in game before the next:

1. Steps 1 to 5. Step 1's fixes go straight into the new code of Step 2, instead of first patching the code Step 2 replaces.
2. Step 9 (the names).
3. Step 6 (Parakeet).
4. Steps 7 and 8 (Deepgram, ElevenLabs, OpenRouter).

Step 10's tests and docs are done inside each part.

Two other Skyrim AI mods, CHIM and SkyrimNet, already solved parts of this. Under each step, "From CHIM" or "From SkyrimNet" notes what we take from them, or which of their mistakes the step avoids. CHIM's speech code is [public](https://github.com/abeiro/HerikaServer/tree/aiagent/stt); SkyrimNet's is not, so what we know comes from its [feature list](https://github.com/MinLL/SkyrimNet-GamePlugin/blob/main/docs/FEATURES.md) and its [name hint file](https://github.com/MinLL/SkyrimNet-GamePlugin/blob/main/plugins/skyrimnet/base/prompts/stt_hints.prompt).

- [ ] **Step 1 (Part 2): Make today's options safe.** Send the key to any address, not only ones containing "openai", and only when a key is set. Use the chat key from `GPT_SECRET_KEY.txt` only when the speech service is the same as the chat AI's (OpenAI with OpenAI), so it never goes to Groq, whisper.cpp or an address the player typed. Never quit when the key is missing. Give each online request a time limit of about 8 seconds in total, including one retry: the recording is turned into text on the microphone's own thread, so a longer wait holds up the microphone too. Turn Proactive Mode off when External Whisper Service points at OpenAI or Groq. Never write keys, even partly, to the log. Make gpt-transcribe the OpenAI model before whisper-1, gpt-4o-transcribe and gpt-4o-mini-transcribe stop on 26 February 2027: change the suggested model, and move players who use one of those three over to it. Today's code already sends whatever model name is set, so this deadline does not wait for the bigger Step 2.
    - *From CHIM (a mistake to avoid):* when the service is down, CHIM waits up to 60 seconds, so the player stands there for a minute. A short wait plus the cough sound is far better than silence.
    - *From CHIM (a mistake to avoid):* CHIM's Gemini code writes the first 10 characters of the key into its log. Players paste their logs into Discord and GitHub when asking for help. Mantella does not do this today; every new format must keep it that way.
- [ ] **Step 2 (Part 2): The building blocks and the new settings.** Split the code into speech programs (PC) and formats (sending somewhere), with a table of ready-made choices on top (see How it stays expandable). Build the OpenAI-style format by moving today's request code over, with ready-made choices for OpenAI and Groq using today's models, so everything that works today keeps working after this step. Add the Speech-to-Text Service list, the Online Service list (shown only when Online Service is picked), Model (remembered per choice), the Key box and its key files (see The key), and Custom Service as the list's last choice (Format, Address, Model, Key, time limit; only OpenAI-style until Steps 7 and 8). Hand the names to the speech code both as the hint sentence and as a list, starting with today's names (the NPCs in the conversation and the location), so Deepgram and ElevenLabs in Step 7 can send them as words to listen for before Step 9 makes the list longer. Remove the old settings, and move each player's existing setup over automatically (below).
    - *Moving existing setups,* the first time the new version starts, so no player loses voice input after updating:
        - External Whisper Service on with OpenAI or Groq becomes Online Service with that service and the same model. Whisper on your PC goes back to its recommended model, because the old Whisper Model held the online model's name (for example whisper-1), which Whisper on your PC cannot run.
        - External Whisper Service on with whisper.cpp or a typed address becomes Custom Service, OpenAI-style, with that address and model. Whisper on your PC goes back to its recommended model, for the same reason.
        - With External Whisper Service off, Whisper Model and Moonshine Model become the Model for Whisper and Moonshine.
        - An existing `STT_SECRET_KEY.txt` is copied into the key file of the service the player was using (for example `GROQ_SECRET_KEY.txt`, or Custom Service's), so no one has to enter a key again. After that it is no longer read, so a Groq key in it is never sent to Deepgram.
    - *From CHIM:* each service is its own small file, so adding one does not touch the rest. That is the right idea, but CHIM copied the same code into each file: its OpenAI and Parakeet files fill in the same form by hand, line for line, and the Parakeet copy still sends OpenAI's model name and looks for an OpenAI key. Every fix then has to be made in several places, and some copies get missed. We write each format once and share it, and named services are just lines in a table.
    - *From CHIM:* one key per service, kept in a key list on its settings page and shared by all its features. That ends the confusing "wrong key sent to the wrong service" errors, and is where the Key box comes from.
    - *From CHIM:* it marks speech-to-text as "running" in its status, because without a sign that Mantella heard them, players repeat themselves. Mantella already covers this: "Listening..." stays on screen in game until the text comes back, so no new notice is needed. A different notice would need a game add-on change.
    - *From CHIM and SkyrimNet:* both let players set how long to wait for their own address. Our 8-second limit suits online services, but a home PC running a large Whisper may need longer, so Custom Service gets this as a setting of its own.
- [ ] **Step 3 (Part 2): Test button, model lists and language check.** Add the Test button. It uses a short recording that ships with Mantella: "Balgruuf, have you seen Proventus in Dragonsreach?", made with Windows' built-in voice. For a choice on your PC it uses the model the game already has loaded when it is the same choice; otherwise it loads the model, tests, and unloads it again, so a large Whisper is never on the graphics card twice. Fill the Model dropdown for online choices from each service's model list, falling back to the ready-made suggestions. Show a clear message when the chosen option does not support the player's language: each ready-made choice carries its list of languages, and Custom Service, whose languages Mantella cannot know, gets no message.
    - *From CHIM:* the Test button. CHIM's sends a sample recording and shows the text, or which step failed. Ours also shows how long the answer took, so players can compare options.
    - *From CHIM (a mistake to avoid):* when the chosen language is not on Deepgram's list, CHIM quietly uses English instead. A French player then gets English nonsense with no explanation and thinks speech-to-text is broken. We say the option does not support their language, and name one that does.
- [ ] **Step 4 (Part 1): Quick wins on the PC.** Add large-v3-turbo to the Whisper dropdown. Mantella asks the Whisper program for the ready-made copy newer versions download under that name, so the program needs no update (see Whisper large-v3-turbo). Its description says that Whisper STT Translate works poorly with it.
    - *From SkyrimNet:* it offers large-v3-turbo, and its built-in Whisper works on NVIDIA, AMD and Intel graphics cards. We do not rebuild Mantella's Whisper on a different engine to match that: whisper.cpp already gives AMD and Intel players the same result through Custom Service (explained in Step 10).
- [ ] **Step 5 (Part 1): Mistral, and programs through Custom Service.** Add Mistral as a ready-made choice. It takes OpenAI's address and form, with one difference: it has no hint sentence, and takes the names as words to listen for instead, each name sent separately. Check that whisper.cpp, Speaches, LocalAI, Together and Fireworks each work through Custom Service.
- [ ] **Step 6 (Part 1): Parakeet on the PC.** Add the onnx-asr program and the Parakeet ready-made choice. Add onnx-asr to Mantella's package list and to the build, so it ships inside Mantella. The 670 MB model downloads on first use from Hugging Face, into the same download folder Whisper and Moonshine already use. Moonshine stays the default. Test Parakeet in game with Skyrim names; if it spells them at least as well as Moonshine, make it the default in a later update.
    - *From CHIM:* it marks Parakeet "Recommended" on the PC. An independent team that tried many options landed on the same pick as our own research.
- [ ] **Step 7 (Parts 1 and 2): The Deepgram-style and ElevenLabs-style formats.** Ready-made choices for Deepgram (Nova-3) and ElevenLabs, also selectable as a format in Custom Service. Always send each name as its own word to listen for, ask Deepgram for punctuation, and drop "um" and "uh". ElevenLabs' key goes in `ELEVENLABS_SECRET_KEY.txt`; the voice services doc must use the same file name when it adds ElevenLabs voices, so the player enters that key once.
    - *From CHIM:* it marks Deepgram "Recommended" online, the same pick as ours.
- [ ] **Step 8 (Parts 1 and 2): OpenRouter.** OpenRouter now also takes OpenAI's form (checked 17 November 2026), so it is a ready-made choice on the OpenAI-style format and needs no format of its own. It has no hint sentence and no field for names that every model behind it understands, so it gets no names.
- [ ] **Step 9 (Part 2): Sending the right names.** Build the longer list of names described in Sending the right names, ahead of time, as one of Mantella's editable prompts that makes a plain list of names. Send it as one line after "Names:" or as separate words, depending on the option. Add the "result is just the hint" safety check.
    - *From SkyrimNet:* the longer list: everyone nearby, the location and the player's name, most likely first. SkyrimNet caps it at 500 characters; Mantella caps it by Whisper's own count instead (see Sending the right names). SkyrimNet also adds nearby places and rebuilds its list every 30 seconds; Mantella leaves places out (the game does not send them) and rebuilds the list whenever the game sends new details, the only time anything in it can change. It is the biggest accuracy gain for the least work: misheard names are the most common complaint, and Mantella already knows all these names.
    - *From SkyrimNet:* the list is an editable file. Players and modders can change what goes in, add names from mods or their own stories, or send nothing, without new code.
    - *Not taken from SkyrimNet:* it sends no hint to Whisper on the PC unless the player turns it on. That makes names worse for everyone to prevent a rare problem; the safety check fixes the problem without losing the names.
- [ ] **Step 10 (Part 2): Tests and docs.** Automatic tests that check each format's request and answer with a pretend service (no internet, no cost), and that the old settings move over correctly, using a temporary config.ini, never the player's real one. Loading each speech program's model is checked by hand, since the downloads are large. One in-game test per ready-made choice, plus one with a program on the PC through Custom Service. A FEATURES\_README section, a line in the release notes, and plain-English descriptions for every new setting, including how AMD and Intel players can use their graphics card through whisper.cpp.
    - *From CHIM (a mistake to avoid):* its Deepgram code builds the list of words to listen for, then accidentally throws it away one line later. Nothing looks broken; names are just spelled wrong forever. Only an automatic check of every format's request catches that.

Listening while the player talks (Deepgram Flux) and reading the player's tone of voice are not in these steps. They are described in the next section.

**No change to the game add-on** (Mantella-Spell). All of this happens in Mantella itself.

> **My view:** Steps 1 to 5 and Step 9 are the core. If time runs short, those six alone deliver a safe, expandable setup with the best online choices and better names. Step 4 is tiny and can be done any time. Only making Parakeet the default waits for the name test. Step 8 (OpenRouter) is the lowest priority.

## Later, not in this round

Two bigger ideas and a few smaller ones came out of the research. All are worth doing, but only after the ten steps are done and tried in game.

### Listening while the player talks (Deepgram Flux)

Instead of waiting for the player to stop, Mantella would send the sound to Deepgram while they speak, and Deepgram would decide when they have finished (see Deepgram in detail above). The main win is fewer sentences cut off halfway, with no extra wait. Speed is a smaller bonus.

Why later: it changes how Mantella listens, needs a connection that stays open, and only Deepgram, ElevenLabs, OpenAI and Mistral offer it. OpenAI's live model also costs nearly 4 times more than its normal one ($0.017 per minute). The steps above should be measured in game first, to see whether cut-off sentences are still a real problem.

### Reading the player's tone of voice

CHIM has an option that sends the recording to Google's Gemini AI and asks for two things at once: the words, and how the player sounded. The player's line then reaches the NPCs as "(angry) Get out of my house." instead of just "Get out of my house." NPCs can react to shouting, whispering or sarcasm, which plain text loses.

Why later: a general AI is slower than a dedicated speech service, so every line would take longer. It is a new feature, not a speech-to-text service, and needs its own design.

> **My view:** of the two, listening while the player talks matters more, because it fixes a real everyday annoyance. Tone of voice is the more exciting idea for roleplay, but it adds a delay to every line, so it should be an option players turn on, not the default.

### Smaller later ideas

- **Rewrite plain speech into an in-character line** (from SkyrimNet): the player says "can you help me", the NPCs hear "Might I ask your aid, friend?"
- **Prepare the AI's next step while the speech is being turned into text** (from SkyrimNet): gather bios, memories and the scene while waiting for the text, probably saving a few tenths of a second on every line. It belongs in a separate speed task.
- **Saved setups** (from CHIM): several named setups the player can switch between, such as "at home" and "on the laptop". Few players need it, so wait until someone asks.
- **Names from recent lines** (from CHIM): add names spoken in the last 30 lines to the list. It catches names of people who are not there ("Ulfric"). Keep only words that match a known NPC or place: CHIM's way of spotting names also picks up ordinary capitalised words.
- **Several voice keys for different purposes** (from SkyrimNet): one to talk, one to talk only to the target, one to think aloud, and one for the in-character rewrite above. Mantella's Conversation Wheel already chooses who hears the player, so only the rewrite adds something new.

## For developers

Keep the microphone thread and the start/stop detection as they are; only the "turn the recording into text" call changes. Today that call is a long method with an if/else per backend, plus model loading in `Transcriber.__init__`. Replace both with one small class per speech program and per format, chosen through a preset table.

**Proposed shape**

- New package `src/stt_backends/` with one interface for both sides: `SpeechBackend.transcribe(audio: np.ndarray, hint_sentence, names, language) -> str`, plus `load()` / `close()`. `Transcriber` holds one backend and never branches on the service again.
- **Speech programs (PC):**
  - `FasterWhisperProgram`: faster-whisper `WhisperModel`; model = size alias or any Hugging Face CTranslate2 id; device cpu/cuda; passes `initial_prompt`; keeps `task="translate"` for Whisper STT Translate. `large-v3-turbo` maps to `mobiuslabsgmbh/faster-whisper-large-v3-turbo`, the id faster-whisper 1.1 uses for that alias.
  - `MoonshineProgram`: today's `MoonshineOnnxModel` + tokenizer + `ensure_sentence_ending`.
  - `OnnxAsrProgram`: `onnx-asr` (`onnx-asr[cpu,hub]==0.12.0` in requirements.txt; `collect_all('onnx_asr')` in `Mantella_onefile.spec`, since the package ships its sound preprocessing models as data files), default model `nemo-parakeet-tdt-0.6b-v3`, loaded as the `int8` copy (670 MB; a typed model without one loads in full); needs Python 3.11+ (Mantella uses 3.11), NumPy 1.23.5+ (shipped: 1.25.0) and onnxruntime (shipped: 1.20.1). Downloads through huggingface_hub into the usual cache. No hint support.
- **Formats (sent somewhere):**
  - `OpenAIStyleFormat`: multipart `file`, `model`, `prompt`, `language` to `<base>/audio/transcriptions`, `Authorization: Bearer <key>` only when a key exists. Plain `requests` for every address (the `openai` client is no longer used for speech). Replaces the `'openai' in self.whisper_url` test and the keyless `requests.post`. A preset can swap the `prompt` sentence for one repeated field per name: Mistral has no `prompt` and takes `context_bias` (one `-F context_bias=<name>` per name; no documented count limit, an over-long request fails with 400). Mistral's [transcription guide](https://docs.mistral.ai/studio/audio/speech-to-text/transcribe-files) (checked 17 November 2026) shows OpenAI's address, Bearer key, `file`, `model` and `language` fields and `text` in the answer, and no `prompt`, so Mantella never sends it one.
  - `DeepgramStyleFormat`: `POST <base>/v1/listen?model=..&language=..&punctuate=true&keyterm=A&keyterm=B`, raw WAV body, `Authorization: Token <key>`. One `keyterm` per name, never comma-joined (silently ignored). Leave `filler_words` off so "um" and "uh" are dropped. Text at `results.channels[0].alternatives[0].transcript`.
  - `ElevenLabsStyleFormat`: `POST <base>/v1/speech-to-text`, multipart `file` + `model_id` (default `scribe_v3`) + `language_code` + one `keyterms` field per name (max 50 characters and 5 words each; over 100 terms bills at least 20 seconds per request), header `xi-api-key`.
  - OpenRouter: no format of its own. Its [transcription API](https://openrouter.ai/docs/api/api-reference/stt/create-transcription) (checked 17 November 2026) takes JSON with base64 `input_audio` or "an OpenAI-style multipart/form-data file upload", so the preset uses `OpenAIStyleFormat` at `https://openrouter.ai/api/v1` with `sends_prompt=False`: `prompt` "is accepted but ignored", and words to listen for only go through per-provider `provider.options`. Its speech models: `GET /models?output_modalities=transcription`, no key needed.
  - Shared by all three: `ServiceFormat` (`service_format.py`) holds the address rule, the time limit and retry, key hiding and the status → message mapping; each format only builds its request and reads its answer. Error words are read from OpenAI's `error.message`, Deepgram's `err_msg` and ElevenLabs' `detail.message`. ElevenLabs also gets `tag_audio_events=false`, so "(laughter)" never ends up in the player's line.
- **Presets**: one plain table, `name -> (backend kind, default model, model suggestions, base address, key name)`. E.g. `Whisper -> (faster_whisper, base, [tiny ... large-v3-turbo], -, -)`, `Groq -> (openai_style, whisper-large-v3-turbo, [...], https://api.groq.com/openai/v1, groq)`. Each preset also lists its languages (two-letter codes), used by the language check; Custom Service has none and is never checked. Custom Service builds the tuple from its own Format, Address, Model and Key settings when `stt_service` is `Custom Service`. Adding a choice = one row.
- **Settings**: `stt_service` gains `Parakeet`, `Online Service` and `Custom Service`; a new `stt_online_service` selection (OpenAI, Groq, Mistral, Deepgram, ElevenLabs, OpenRouter) is shown only when `stt_service` is `Online Service`. The settings page's `shown_when` only follows on/off switches today, so it needs a small extension to follow a selection's value. Custom Service's settings are shown while `stt_service` is `Custom Service`: `stt_custom_format`, `stt_custom_address`, `stt_custom_model`, `stt_custom_timeout`. Models are remembered per choice: each ready-made choice has a Model setting of its own (`moonshine_model_size`, `whisper_model_size`, `stt_model_<choice>`), shown with `shown_when` only while that choice is picked, so the player sees one Model box at a time.
- **Moving old settings** (first start after the update), in `ConfigLoader` the way the old `active_actions` list is carried over, before unknown keys are dropped: `external_whisper_service` on + `whisper_url` OpenAI/Groq → `stt_service = Online Service`, `stt_online_service` = that service, its model = `whisper_model_size`; any other `whisper_url` (whisper.cpp or a typed address) → `stt_service = Custom Service`, OpenAI-style, `stt_custom_address` from `__get_endpoint`, `stt_custom_model = whisper_model_size`. In both cases reset `whisper_model_size` to its default (`base`). Copy `STT_SECRET_KEY.txt` into that service's key file if that file does not exist yet. Then drop the old keys.
- `hot_swap_settings` follows the new settings, and a Key box save refreshes the backend's key without a rebuild.
- `Conversation` hands the backend both the hint sentence and the names list: `start_listening(prompt)` becomes `start_listening(hint_sentence, names)` in Step 2, filled from today's data (`get_character_names_as_text`, `location`) until Step 9.
- Test button (Step 3): a short bundled WAV under `data/`. For a PC choice, reuse the game's `Transcriber` backend when it is loaded with the same program and model (the UI runs in the same process); otherwise load a temporary backend, transcribe, `close()` it.
- **Keys**: one text file per service next to `GPT_SECRET_KEY.txt` (`OPENAI_SECRET_KEY.txt`, `GROQ_SECRET_KEY.txt`, `MISTRAL_SECRET_KEY.txt`, `DEEPGRAM_SECRET_KEY.txt`, `ELEVENLABS_SECRET_KEY.txt`, `OPENROUTER_SECRET_KEY.txt`, `CUSTOM_STT_SECRET_KEY.txt`), read with `read_key_file` from `src/tts/voice_setups.py` like the voice services. That reads the mod folder (`resolve_path()` three levels up) before Mantella's folder, so the Key box writes to the first place where the file already exists, else next to `GPT_SECRET_KEY.txt`. It never shows the key in full (masked); nothing goes into config.ini. Lookup for a preset: its own file, then `GPT_SECRET_KEY.txt` only when `llm_api` is the same service (OpenAI, OpenRouter). `STT_SECRET_KEY.txt` is only read by the move.
- Address handling: accept a base or a full path; append the format's path only when it is missing.
- Text clean-up shared by every backend: the made-up-phrase list, a "result equals the hint" check, sentence ending.
- Every online request: about 8 s in total across both tries (it runs on the microphone thread, inside `_process_audio`), one retry on connection error or 5xx, no retry on 401/402/404. Never `input()` / `sys.exit()` on a missing key. No fallback to a local backend on failure.
- Proactive Mode is ignored for the Online Service presets. Custom Service keeps the player's setting.
- faster-whisper is 1.0.3 (ctranslate2 4.6.0): no `large-v3-turbo` alias (added in 1.1), but any name containing `/` is treated as a Hugging Face model id, so the id above works without an upgrade.

**Name list (Part 2, Step 9).** A new editable prompt rendered by the existing prompt system, replacing the fixed sentence in `Conversation.__get_mic_prompt` (`src/conversation/conversation.py`). It renders a comma list of names; the hint is `"Names: " + list + "."` and the names are the pieces between commas. Prompts already support `{player_name}`, `{names}` and `{location}`. Rendered whenever the game sends new details and cached; the mic starts before that turn's details arrive (`KEY_PLAYERINPUT_DETAILSFOLLOW`), so it uses the previous turn's. Nearby NPCs come from `Characters.get_all_names_w_nearby`. faster-whisper keeps only the last 223 tokens of the prompt (`previous_tokens[-(max_length // 2 - 1):]` in 1.0.3's `transcribe.py`), and OpenAI and Groq also consider only the final 224, so the hint is capped at about 200 tokens counted with the Whisper tokenizer, dropping names from the end of the list. Measured with Whisper's own tokenizer (shipped as `data/stt_whisper_tokenizer.json`, counted with `tokenizers`): 407 characters of English Skyrim names is 167 tokens, 500 characters of Russian names 265. The split list of names (pieces between commas, up to five words each, as SkyrimNet does, so a piece that is a sentence a player typed is left out) for Deepgram, ElevenLabs and Mistral stays capped at 500 characters at the last separator.

**Where things are now**

| Plain words in this doc | Name in code | Where |
| --- | --- | --- |
| Speech-to-Text Service | `stt_service` | `stt_definitions.py`, loaded in `config_loader.py` |
| External Whisper Service / Whisper Service (to remove) | `external_whisper_service`, `whisper_url` | `stt_definitions.py`, `config_loader.py`, registered in `mantella_config_value_definitions_new.py` (and the classic file) |
| Whisper Model | `whisper_model_size` → `config.whisper_model` | `stt_definitions.py` |
| Whisper STT Translate (stays) | `stt_translate` → `task="translate"` | `stt_definitions.py`, used in `whisper_transcribe` |
| Spoken Language | `stt_language` (`default` = the main language) | `config_loader.py` |
| Cough Error Sound | `play_cough_sound` (on by default) | `stt_definitions.py`, played in `get_latest_transcription` |
| Start/stop detection | Silero VAD, `Transcriber._process_audio` | `src/stt.py` |
| Turn the recording into text | `Transcriber._transcribe` → `whisper_transcribe` | `src/stt.py` |
| The "openai" address bug | `if 'openai' in self.whisper_url` | `src/stt.py`: `__init__`, `whisper_transcribe`, `hot_swap_settings` |
| Service name → address | `__get_endpoint` | `src/stt.py` |
| The key, and the silent fallback to the chat key | `__get_api_key`, `STT_SECRET_KEY.txt` → `GPT_SECRET_KEY.txt` | `src/stt.py` |
| Key files (existing patterns) | `KeyFileResolver` (chat), `read_key_file` (voices) | `src/llm/key_file_resolver.py`, `src/tts/voice_setups.py` |
| The chat AI's service | `llm_api` | `config_loader.py` |
| The hint sentence | `__get_mic_prompt` | `src/conversation/conversation.py` |
| Proactive Mode | `proactive_mic_mode`, `min_refresh_secs` (0.3 s) | `stt_definitions.py`, used in `_process_audio` |
| Settings shown only while a switch is on | `shown_when` | `src/ui/settings_ui_constructor.py` |
| "Listening..." in game, cleared when the text comes back | `ShowRepeatingMessage`, `sendRequestForVoiceTranscribe` | `MantellaConversation.psc` (game add-on, unchanged) |
| Changing settings mid-game | `Transcriber.hot_swap_settings` | `src/stt.py` |
| Where the Transcriber is made | `Transcriber(config, stt_api_file, api_file)` | `src/game_manager.py` (two places) |

**Tests.** There are no speech-to-text tests yet. Add `tests/test_stt_services.py`: one test per service that checks the request (address, headers, form fields) and parses a recorded sample answer, using a fake HTTP layer, plus one test per old-settings case for the move. The move tests build their config in `tmp_path` like the `default_config` fixture, never through `actual_config`, which loads the real config.ini from My Games. Run only that file.

## Sources

All opened on 14 November 2026.

- [OpenAI deprecations](https://developers.openai.com/api/docs/deprecations): whisper-1, gpt-4o-transcribe, gpt-4o-mini-transcribe shut down 26 February 2027.
- [OpenAI gpt-transcribe](https://developers.openai.com/api/docs/models/gpt-transcribe): $0.0045 per minute.
- [Groq speech-to-text docs](https://console.groq.com/docs/speech-to-text): prices, 10-second minimum, prompt up to 224 tokens.
- [Deepgram pricing](https://deepgram.com/pricing): Nova-3 and Flux per-minute rates, $200 credit.
- [Deepgram words to listen for (keyterm)](https://developers.deepgram.com/docs/keyterm): limits and the comma trap.
- [Deepgram Flux](https://developers.deepgram.com/docs/flux/quickstart): end-of-turn detection, languages.
- [Deepgram self-hosting](https://developers.deepgram.com/on-prem/): needs an Enterprise plan.
- [ElevenLabs API pricing](https://elevenlabs.io/pricing/api) (Scribe v3 and v2 $0.20 per hour, words to listen for $0.05 per hour), [models](https://elevenlabs.io/docs/overview/models) (scribe\_v3 is the newest for recordings) and [speech-to-text API reference](https://elevenlabs.io/docs/api-reference/speech-to-text/convert).
- [Mistral audio overview](https://docs.mistral.ai/en/studio-api/audio/overview): Voxtral model names (the page shows no prices). Opened 16 November 2026: [transcription API reference](https://docs.mistral.ai/api/endpoint/audio/transcriptions) (fields: `file`, `model`, `language`, `context_bias`; no `prompt`) and [context bias](https://docs.mistral.ai/studio/audio/speech-to-text/bias-context-and-vocabulary) (one `context_bias` field per word or phrase).
- [OpenRouter gpt-4o-mini-transcribe API](https://openrouter.ai/openai/gpt-4o-mini-transcribe/api): request format and price.
- [SkyrimNet features](https://github.com/MinLL/SkyrimNet-GamePlugin/blob/main/docs/FEATURES.md) and [hint template](https://github.com/MinLL/SkyrimNet-GamePlugin/blob/main/plugins/skyrimnet/base/prompts/stt_hints.prompt).
- What the other mods offer: SkyrimNet has Whisper built in (any graphics card, models up to large-v3-turbo) plus OpenAI and its own paid service, Fateless. CHIM has Whisper as a separate program and Parakeet on the PC, plus OpenAI, Deepgram, Gemini, Azure and Inworld online.
- [CHIM speech-to-text code](https://github.com/abeiro/HerikaServer/tree/aiagent/stt), [recent-names function](https://github.com/abeiro/HerikaServer/blob/aiagent/lib/chat_helper_functions.php), [Test page](https://github.com/abeiro/HerikaServer/blob/aiagent/ui/tests/stt-test.php).
- [Parakeet vs Whisper comparison](https://openwhispr.com/blog/parakeet-vs-whisper-vs-nemotron) (July 2026) and [onnx-asr](https://github.com/istupakov/onnx-asr) (Python 3.11 to 3.14, NumPy 1.23.5+).
