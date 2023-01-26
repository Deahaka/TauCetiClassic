//Programs that are generally useful for population control and non-harmful suppression.

/datum/nanite_program/sleepy
	name = "Sleep Induction"
	desc = "The nanites cause rapid narcolepsy when triggered."
	trigger_cost = 15
	trigger_cooldown = 1200
	rogue_types = list(/datum/nanite_program/brain_misfire, /datum/nanite_program/brain_decay)

/datum/nanite_program/sleepy/on_trigger(comm_message)
	to_chat(host_mob, "<span class='warning'>You start to feel very sleepy...</span>")
	host_mob.blurEyes(10)
	host_mob.drowsyness += min(host_mob.drowsyness, 20)
	addtimer(CALLBACK(host_mob, /mob/living.proc/Sleeping, 200), rand(60,200))

/datum/nanite_program/paralyzing
	name = "Paralysis"
	desc = "The nanites force muscle contraction, effectively paralyzing the host."
	use_rate = 3
	rogue_types = list(/datum/nanite_program/nerve_decay)

/datum/nanite_program/paralyzing/active_effect()
	host_mob.Stun(40)

/datum/nanite_program/paralyzing/enable_passive_effect()
	. = ..()
	to_chat(host_mob, "<span class='warning'>Your muscles seize! You can't move!</span>")

/datum/nanite_program/paralyzing/disable_passive_effect()
	. = ..()
	to_chat(host_mob, "<span class='notice'>Your muscles relax, and you can move again.</span>")

/datum/nanite_program/shocking
	name = "Electric Shock"
	desc = "The nanites shock the host when triggered. Destroys a large amount of nanites!"
	trigger_cost = 10
	trigger_cooldown = 300
	program_flags = NANITE_SHOCK_IMMUNE
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/shocking/on_trigger(comm_message)
	host_mob.electrocute_act(rand(5,30), src)

/datum/nanite_program/stun
	name = "Neural Shock"
	desc = "The nanites pulse the host's nerves when triggered, inapacitating them for a short period."
	trigger_cost = 4
	trigger_cooldown = 300
	rogue_types = list(/datum/nanite_program/shocking, /datum/nanite_program/nerve_decay)

/datum/nanite_program/stun/on_trigger(comm_message)
	playsound(host_mob, pick(SOUNDIN_SPARKS), VOL_EFFECTS_MASTER)
	host_mob.AdjustWeakened(20)

/datum/nanite_program/pacifying
	name = "Pacification"
	desc = "The nanites suppress the aggression center of the brain, preventing the host from causing direct harm to others."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/brain_misfire, /datum/nanite_program/brain_decay)

/datum/nanite_program/pacifying/enable_passive_effect()
	. = ..()
	/*TODO: TRAIT
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		H.mutations.Add(CLUMSY)
		*/

/datum/nanite_program/pacifying/disable_passive_effect()
	. = ..()
	//host_mob.remove_trait(TRAIT_PACIFISM, "nanites")

/datum/nanite_program/blinding
	name = "Blindness"
	desc = "The nanites suppress the host's ocular nerves, blinding them while they're active."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/nerve_decay)

/datum/nanite_program/blinding/enable_passive_effect()
	. = ..()
	ADD_TRAIT(host_mob, TRAIT_BLIND, NANITE_TRAIT)

/datum/nanite_program/blinding/disable_passive_effect()
	. = ..()
	REMOVE_TRAIT(host_mob, TRAIT_BLIND, NANITE_TRAIT)

/datum/nanite_program/mute
	name = "Mute"
	desc = "The nanites suppress the host's speech, making them mute while they're active."
	use_rate = 0.75
	rogue_types = list(/datum/nanite_program/brain_decay, /datum/nanite_program/brain_misfire)

/datum/nanite_program/mute/enable_passive_effect()
	. = ..()
	ADD_TRAIT(host_mob, TRAIT_MUTE, NANITE_TRAIT)

/datum/nanite_program/mute/disable_passive_effect()
	. = ..()
	REMOVE_TRAIT(host_mob, TRAIT_MUTE, NANITE_TRAIT)

/datum/nanite_program/fake_death
	name = "Death Simulation"
	desc = "The nanites induce a death-like coma into the host, able to fool most medical scans."
	use_rate = 3.5
	rogue_types = list(/datum/nanite_program/nerve_decay, /datum/nanite_program/necrotic, /datum/nanite_program/brain_decay)

/datum/nanite_program/fake_death/enable_passive_effect()
	. = ..()
	host_mob.emote("deathgasp")
	host_mob.add_status_flags(FAKEDEATH)
	host_mob.update_canmove()

/datum/nanite_program/fake_death/disable_passive_effect()
	. = ..()
	host_mob.remove_status_flags(FAKEDEATH)

//Can receive transmissions from a nanite communication remote for customized messages
/datum/nanite_program/comm
	var/comm_code = 0
	var/comm_message = ""

/datum/nanite_program/comm/register_extra_settings()
	extra_settings[NES_COMM_CODE] = new /datum/nanite_extra_setting/number(0, 0, 9999)

/datum/nanite_program/comm/proc/receive_comm_signal(signal_comm_code, comm_message, comm_source)
	if(!activated || !comm_code)
		return
	if(signal_comm_code == comm_code)
		trigger(comm_message)

/datum/nanite_program/comm/speech
	name = "Forced Speech"
	desc = "The nanites force the host to say a pre-programmed sentence when triggered."
	unique = FALSE
	trigger_cost = 3
	trigger_cooldown = 20
	rogue_types = list(/datum/nanite_program/brain_misfire, /datum/nanite_program/brain_decay)
	var/static/list/blacklist = list("*collapse") //<= May i return that? XD

/datum/nanite_program/comm/speech/register_extra_settings()
	. = ..()
	extra_settings[NES_SENTENCE] = new /datum/nanite_extra_setting/text("")

/datum/nanite_program/comm/speech/on_trigger(comm_message)
	var/sent_message = comm_message
	if(!comm_message)
		var/datum/nanite_extra_setting/sentence = extra_settings[NES_SENTENCE]
		sent_message = sentence.get_value()
	if(sent_message in blacklist)
		return

	if(host_mob.stat == DEAD)
		return
	to_chat(host_mob, "<span class='warning'>You feel compelled to speak...</span>")
	host_mob.say(sent_message)

/datum/nanite_program/comm/voice
	name = "Skull Echo"
	desc = "The nanites echo a synthesized message inside the host's skull."
	unique = FALSE
	trigger_cost = 1
	trigger_cooldown = 20
	rogue_types = list(/datum/nanite_program/brain_misfire, /datum/nanite_program/brain_decay)

	extra_settings = list(NES_MESSAGE, NES_COMM_CODE)
	var/message = ""

/datum/nanite_program/comm/voice/register_extra_settings()
	. = ..()
	extra_settings[NES_MESSAGE] = new /datum/nanite_extra_setting/text("")

/datum/nanite_program/comm/voice/on_trigger(comm_message)
	var/sent_message = comm_message
	if(!comm_message)
		var/datum/nanite_extra_setting/message_setting = extra_settings[NES_MESSAGE]
		sent_message = message_setting.get_value()
	if(host_mob.stat == DEAD)
		return
	to_chat(host_mob, "<i>You hear a strange, robotic voice in your head...</i> \"<span class='robot'>[sent_message]</span>\"")
