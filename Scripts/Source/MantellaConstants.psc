Scriptname MantellaConstants extends Quest hidden

string property HTTP_ROUTE_MAIN = "Mantella" auto
string property HTTP_ROUTE_STT = "stt" auto

string property HTTP_ERROR = "SKSE_HTTP_error" auto

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          Mod events         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; string property EVENT_ACTIONS = "MantellaConversation_Action_" auto
; string property EVENT_CONVERSATION_STARTED = "MantellaConversation_Started" auto
; string property EVENT_CONVERSATION_ENDED = "MantellaConversation_Ended" auto
; string property EVENT_CONVERSATION_NPC_ADDED = "MantellaConversation_NPC_Added" auto
; string property EVENT_CONVERSATION_NPC_REMOVED = "MantellaConversation_NPC_Removed" auto

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; JSON keys for communication ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

string property PREFIX = "mantella_" auto
string property KEY_REQUESTTYPE = "mantella_request_type" auto
string property KEY_REPLYTYPE = "mantella_reply_type" auto
string property KEY_INPUTTYPE = "mantella_input_type" auto

string property KEY_REQUEST_EXTRA_ACTIONS = "mantella_extra_actions" auto

;Conversation
string property KEY_REQUESTTYPE_INIT = "mantella_initialize" auto
string property KEY_REQUESTTYPE_STARTCONVERSATION = "mantella_start_conversation" auto
string property KEY_REQUESTTYPE_CONTINUECONVERSATION = "mantella_continue_conversation" auto
string property KEY_REQUESTTYPE_PLAYERINPUT = "mantella_player_input" auto
string property KEY_REQUESTTYPE_ENDCONVERSATION = "mantella_end_conversation" auto
string property KEY_REQUESTTYPE_INTERRUPT = "mantella_interrupt" auto

string property KEY_REPLYTTYPE_INITCOMPLETED = "mantella_init_completed" auto
string property KEY_REPLYTTYPE_STARTCONVERSATIONCOMPLETED = "mantella_start_conversation_completed" auto

string property KEY_REPLYTYPE_NPCTALK = "mantella_npc_talk" auto
string property KEY_REPLYTYPE_PLAYERTALK = "mantella_player_talk" auto
string property KEY_REPLYTYPE_NPCACTION = "mantella_npc_action" auto
string property KEY_REPLYTYPE_ENDCONVERSATION = "mantella_end_conversation" auto
string property KEY_REPLYTYPE_INTERRUPTRECEIVED = "mantella_interrupt_received" auto

string property KEY_REQUESTTYPE_NPCINITIATIVE = "mantella_npc_initiative_check" auto
string property KEY_REPLYTYPE_NPCINITIATIVE = "mantella_npc_initiative_result" auto
string property KEY_STARTCONVERSATION_NPCINITIATIVE = "mantella_npc_initiative" auto
string property KEY_NPCINITIATIVE_CHOSEN_REFID = "mantella_npc_initiative_chosen_refid" auto
string property KEY_NPCINITIATIVE_SKIPTHRESHOLD = "mantella_npc_initiative_skip_threshold" auto

string property KEY_REQUESTTYPE_NPCEVENT = "mantella_npc_event_check" auto
string property KEY_REPLYTYPE_NPCEVENT = "mantella_npc_event_result" auto
string property KEY_REPLYTYPE_NPCEVENT_ADDACTOR = "mantella_npc_event_add_actor" auto
string property KEY_NPCEVENT_ID = "mantella_npc_event_id" auto
string property KEY_NPCEVENT_PARTICIPANT_REFIDS = "mantella_npc_event_participant_refids" auto
string property KEY_NPCEVENT_ADDACTOR_REFID = "mantella_npc_event_add_actor_refid" auto ; Only the player watching: anyone else joins by Shout
string property KEY_NPCEVENT_NEARBY_REFIDS = "mantella_npc_event_nearby_refids" auto ; In the check: everyone nearby, nearest first
string property KEY_NPCEVENT_NEARBY_NAMES = "mantella_npc_event_nearby_names" auto ; In the same order as the refids
string property KEY_NPCEVENT_PLAYERNOTICEABLE = "mantella_npc_event_player_noticeable" auto
string property KEY_EVENT_HINT = "mantella_event_hint" auto ; What the player would like to happen (Ask for a Hint). Only for the event generator

; Conversation, Nearby and Random Events (Conversation Wheel). Sent during the player's turn
string property KEY_REQUESTTYPE_CONVERSATIONEVENT = "mantella_conversation_event" auto
string property KEY_REPLYTYPE_CONVERSATIONEVENT = "mantella_conversation_event_result" auto
string property KEY_EVENT_KIND = "mantella_event_kind" auto ; "conversation", "nearby" or "random". In an interrupt request: an event was picked, so a wait for the player to speak ends
string property KEY_EVENT_SENDHISTORY = "mantella_event_send_history" auto
string property KEY_EVENT_INCLUDEPLAYER = "mantella_event_include_player" auto
string property KEY_EVENT_NEARBY_REFIDS = "mantella_event_nearby_refids" auto ; Nearby and Random: who the event can be about, nearest first
string property KEY_EVENT_NEARBY_NAMES = "mantella_event_nearby_names" auto
string property KEY_EVENT_NEARBY_ACTORS = "mantella_event_nearby_actors" auto ; Full actor settings of the nearest who are not in the conversation
string property KEY_EVENT_MAXDESCRIBED = "mantella_event_max_described" auto
string property KEY_EVENT_RESULT = "mantella_event_result" auto ; In the reply: true if something happened
string property KEY_EVENT_CANCEL = "mantella_event_cancel" auto ; In an interrupt request: the player ended the conversation while the event was being generated
string property KEY_GAMEMASTERMODE = "mantella_game_master_mode" auto ; In the start, continue and event replies

; Shout: sent with every continue and player input request. The rest only while the player shouts
string property KEY_SHOUT_ENABLED = "mantella_shout_enabled" auto
string property KEY_SHOUT_NEARBY_REFIDS = "mantella_shout_nearby_refids" auto
string property KEY_SHOUT_NEARBY_NAMES = "mantella_shout_nearby_names" auto
string property KEY_SHOUT_NEARBY_ACTORS = "mantella_shout_nearby_actors" auto ; Full actor settings, sent once for each person new to the list
string property KEY_SHOUT_MAXPEOPLE = "mantella_shout_max_people" auto
string property KEY_SHOUT_MAXDESCRIBED = "mantella_shout_max_described" auto ; How many of the nearest people the Game Master gets the bios and memories of
string property KEY_SHOUT_NEWCOMERSREMEMBER = "mantella_shout_newcomers_remember" auto ; What someone who joins by shouting heard before: 0 since shouting, 1 your last line, 2 everything
string property KEY_SHOUT_MAXANSWERING = "mantella_shout_max_answering" auto ; Most People Answering at Once: how many answer a line said to a group
string property KEY_SHOUT_ADDFAILED_REFIDS = "mantella_shout_add_failed_refids" auto ; Who of the people asked for could not be added
string property KEY_SHOUT_ADDFAILED_REASONS = "mantella_shout_add_failed_reasons" auto ; In the same order: why, for the log
string property KEY_REPLYTYPE_SHOUT_ADDACTOR = "mantella_shout_add_actor" auto
string property KEY_SHOUT_ADDACTOR_REFIDS = "mantella_shout_add_actor_refids" auto ; Everyone the line was spoken to, added in one step
string property KEY_SHOUT_UNAVAILABLE = "mantella_shout_unavailable" auto

; Quest tags: the MantellaQuestChecks plugin answers the checks of the quest tag conditions
string property KEY_REQUESTTYPE_QUESTCHECKLIST = "mantella_quest_check_list_request" auto
string property KEY_REPLYTYPE_QUESTCHECKLIST = "mantella_quest_check_list_result" auto
string property KEY_QUESTCHECKS_LIST = "mantella_quest_check_list" auto
string property KEY_QUESTCHECKS_FUNCTIONS = "mantella_quest_check_functions" auto
string property KEY_QUESTCHECKS_REFERENCES = "mantella_quest_check_references" auto
string property KEY_QUESTCHECKS_PARAMS1 = "mantella_quest_check_params1" auto
string property KEY_QUESTCHECKS_PARAMS2 = "mantella_quest_check_params2" auto
string property KEY_QUESTCHECKS_VERSION = "mantella_quest_check_version" auto
string property KEY_QUESTCHECKS_RESULTS = "mantella_quest_check_results" auto

string property KEY_STARTCONVERSATION_WORLDID = "mantella_worldid" auto
string property KEY_STARTCONVERSATION_USENARRATOR = "mantella_use_narrator" auto
string property KEY_CONTINUECONVERSATION_TOPICINFOFILE = "mantella_topicinfofile" auto

;Actors
string property KEY_ACTORS = "mantella_actors" auto
string property KEY_ACTOR_BASEID = "mantella_actor_baseid" auto
string property KEY_ACTOR_REFID = "mantella_actor_refid" auto
string property KEY_ACTOR_NAME = "mantella_actor_name" auto
string property KEY_ACTOR_GENDER = "mantella_actor_gender" auto
string property KEY_ACTOR_RACE = "mantella_actor_race" auto
string property KEY_ACTOR_ISPLAYER = "mantella_actor_is_player" auto
string property KEY_ACTOR_RELATIONSHIPRANK = "mantella_actor_relationshiprank" auto
string property KEY_ACTOR_VOICETYPE = "mantella_actor_voicetype" auto
string property KEY_ACTOR_ISINCOMBAT = "mantella_actor_is_in_combat" auto
string property KEY_ACTOR_ISENEMY = "mantella_actor_is_enemy" auto
string property KEY_ACTOR_CUSTOMVALUES = "mantella_actor_custom_values" auto

string property KEY_ACTOR_PC_DESCRIPTION = "mantella_pc_description" auto
string property KEY_ACTOR_PC_VOICEPLAYERINPUT = "mantella_pc_voiceplayerinput" auto
string property KEY_ACTOR_PC_VOICEMODEL = "mantella_pc_voicemodel" auto


;sentence
string property KEY_ACTOR_SPEAKER = "mantella_actor_speaker" auto
string property KEY_ACTOR_LINETOSPEAK = "mantella_actor_line_to_speak" auto
string property KEY_ACTOR_ISNARRATION = "mantella_is_narration" auto
string property KEY_ACTOR_VOICEFILE= "mantella_actor_voice_file" auto
string property KEY_ACTOR_DURATION = "mantella_actor_line_duration" auto
string property KEY_ACTOR_ACTIONS = "mantella_actor_actions" auto

;context
string property KEY_CONTEXT = "mantella_context" auto
string property KEY_CONTEXT_LOCATION = "mantella_location" auto
string property KEY_CONTEXT_WEATHER = "mantella_weather" auto
string property KEY_CONTEXT_WEATHER_ID = "mantella_weather_id" auto
string property KEY_CONTEXT_WEATHER_CLASSIFICATION = "mantella_weather_classification" auto
string property KEY_CONTEXT_TIME = "mantella_time" auto
string property KEY_CONTEXT_INGAMEEVENTS = "mantella_ingame_events" auto

;player input
string property KEY_REQUESTTYPE_TTS = "mantella_tts" auto
string property KEY_INPUT_NAMESINCONVERSATION = "mantella_names_in_conversation" auto
string property KEY_TRANSCRIBE = "mantella_transcribe" auto
string property KEY_INPUTTYPE_TEXT = "mantella_text_input" auto
string property KEY_INPUTTYPE_MIC = "mantella_mic_input" auto
string property KEY_INPUTTYPE_PTT = "mantella_push_to_talk" auto

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Possible actions      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

string property ACTION_RELOADCONVERSATION = "mantella_reload_conversation" auto
string property ACTION_ENDCONVERSATION = "mantella_end_conversation" auto
string property ACTION_REMOVECHARACTER = "mantella_remove_character" auto

string property ACTION_NPC_OFFENDED = "mantella_npc_offended" auto
string property ACTION_NPC_FORGIVEN = "mantella_npc_forgiven" auto
string property ACTION_NPC_FOLLOW = "mantella_npc_follow" auto
string property ACTION_NPC_INVENTORY = "mantella_npc_inventory" auto
