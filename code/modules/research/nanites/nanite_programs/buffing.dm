//Programs that buff the host in generally passive ways.

/datum/nanite_program/nervous
	name = "Nerve Support"
	desc = "The nanites act as a secondary nervous system, reducing the amount of time the host is stunned."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/nerve_decay)

/datum/nanite_program/nervous/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		ADD_TRAIT(H, TRAIT_STEEL_NERVES, NANITE_TRAIT)

/datum/nanite_program/nervous/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		REMOVE_TRAIT(H, TRAIT_STEEL_NERVES, NANITE_TRAIT)

/datum/nanite_program/adrenaline
	name = "Adrenaline Burst"
	desc = "The nanites cause a burst of adrenaline when triggered, waking the host from stuns and temporarily increasing their speed."
	trigger_cost = 25
	trigger_cooldown = 1200
	rogue_types = list(/datum/nanite_program/toxic, /datum/nanite_program/nerve_decay)

/datum/nanite_program/adrenaline/on_trigger()
	to_chat(host_mob, "<span class='notice'>You feel a sudden surge of energy!</span>")
	host_mob.AdjustStunned(-10)
	host_mob.AdjustWeakened(-10)
	host_mob.AdjustParalysis(-10)
	host_mob.adjustHalLoss(-25)
	host_mob.reagents.add_reagent("stimulants", 5)
	host_mob.update_canmove()

/datum/nanite_program/hardening
	name = "Dermal Hardening"
	desc = "The nanites form a mesh under the host's skin, protecting them from melee and bullet impacts."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/skin_decay)

//TODO on_hit effect that turns skin grey for a moment
//UPD. NOW TEST THIS!

/datum/nanite_program/hardening/enable_passive_effect()
	. = ..()
	ADD_TRAIT(host_mob, TRAIT_REINFORCING_NANITES, NANITE_TRAIT)
	ADD_TRAIT(host_mob, TRAIT_LOW_PAIN_THRESHOLD, NANITE_TRAIT)


/datum/nanite_program/hardening/disable_passive_effect()
	. = ..()
	REMOVE_TRAIT(host_mob, TRAIT_REINFORCING_NANITES, NANITE_TRAIT)
	REMOVE_TRAIT(host_mob, TRAIT_LOW_PAIN_THRESHOLD, NANITE_TRAIT)

/datum/nanite_program/refractive
	name = "Dermal Refractive Surface"
	desc = "The nanites form a membrane above the host's skin, reducing the effect of laser and energy impacts."
	use_rate = 0.50
	rogue_types = list(/datum/nanite_program/skin_decay)

/datum/nanite_program/refractive/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		ADD_TRAIT(H, TRAIT_REFLECT_SKIN, NANITE_TRAIT)

/datum/nanite_program/refractive/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		REMOVE_TRAIT(H, TRAIT_REFLECT_SKIN, NANITE_TRAIT)

//TODO: DELETE??? LOSS BLOOD = LOSS NANITES
/datum/nanite_program/coagulating
	name = "Rapid Coagulation"
	desc = "The nanites induce rapid coagulation when the host is wounded, dramatically reducing bleeding rate."
	use_rate = 0.10
	rogue_types = list(/datum/nanite_program/suffocating)

/datum/nanite_program/coagulating/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		ADD_TRAIT(H, TRAIT_HEMOCOAGULATION, NANITE_TRAIT)
		for(var/obj/item/organ/external/BP in H.bodyparts)
			BP.status &= ~ORGAN_ARTERY_CUT

/datum/nanite_program/coagulating/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		REMOVE_TRAIT(H, TRAIT_HEMOCOAGULATION, NANITE_TRAIT)

/datum/nanite_program/conductive
	name = "Electric Conduction"
	desc = "The nanites act as a grounding rod for electric shocks, protecting the host. Shocks can still damage the nanites themselves."
	use_rate = 0.20
	program_flags = NANITE_SHOCK_IMMUNE
	rogue_types = list(/datum/nanite_program/nerve_decay)

/datum/nanite_program/conductive/enable_passive_effect()
	. = ..()
	ADD_TRAIT(host_mob, TRAIT_SHOCKIMMUNE, NANITE_TRAIT)

/datum/nanite_program/conductive/disable_passive_effect()
	. = ..()
	REMOVE_TRAIT(host_mob, TRAIT_SHOCKIMMUNE, NANITE_TRAIT)

/datum/nanite_program/mindshield
	name = "Imitation Mental Barrier"
	desc = "The nanites form a imitation of protective membrane around the host's brain."
	use_rate = 0.40
	rogue_types = list(/datum/nanite_program/brain_decay, /datum/nanite_program/brain_misfire)

/datum/nanite_program/mindshield/enable_passive_effect()
	. = ..()
	ADD_TRAIT(host_mob, TRAIT_MINDSHIELD, NANITE_TRAIT)
	host_mob.sec_hud_set_implants()

/datum/nanite_program/mindshield/disable_passive_effect()
	. = ..()
	REMOVE_TRAIT(host_mob, TRAIT_MINDSHIELD, NANITE_TRAIT)
	host_mob.sec_hud_set_implants()
