//Programs specifically engineered to cause harm to either the user or its surroundings (as opposed to ones that only do it due to broken programming)
//Very dangerous!

/datum/nanite_program/flesh_eating
	name = "Cellular Breakdown"
	desc = "The nanites destroy cellular structures in the host's body, causing brute damage."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/flesh_eating/active_effect()
	host_mob.take_bodypart_damage(1)
	if(prob(3))
		to_chat(host_mob, "<span class='warning'>You feel a stab of pain from somewhere inside you.</span>")

/datum/nanite_program/poison
	name = "Poisoning"
	desc = "The nanites deliver poisonous chemicals to the host's internal organs, causing toxin damage and vomiting."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/poison/active_effect()
	host_mob.adjustToxLoss(1)
	if(prob(2))
		if(iscarbon(host_mob))
			var/mob/living/carbon/C = host_mob
			C.vomit()

/datum/nanite_program/memory_leak
	name = "Memory Leak"
	desc = "This program invades the memory space used by other programs, causing frequent corruptions and errors."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/memory_leak/active_effect()
	if(prob(6))
		var/datum/nanite_program/target = pick(nanites.programs)
		if(target == src)
			return
		target.software_error()

/datum/nanite_program/aggressive_replication
	name = "Aggressive Replication"
	desc = "Nanites will consume organic matter to improve their replication rate, damaging the host. The efficiency increases with the volume of nanites, requiring 200 to break even."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/aggressive_replication/active_effect()
	var/extra_regen = round(nanites.nanite_volume / 200, 0.1)
	nanites.adjust_nanites(null, extra_regen)
	host_mob.adjustBruteLoss(extra_regen / 2, TRUE)

/datum/nanite_program/meltdown
	name = "Meltdown"
	desc = "Causes an internal meltdown inside the nanites, causing internal burns inside the host as well as rapidly destroying the nanite population.\
			Sets the nanites' safety threshold to 0 when activated."
	use_rate = 10
	rogue_types = list(/datum/nanite_program/glitch)

/datum/nanite_program/meltdown/active_effect()
	host_mob.adjustFireLoss(4)

/datum/nanite_program/meltdown/enable_passive_effect()
	. = ..()
	to_chat(host_mob, "<span class='userdanger'>Your blood is burning!</span>")
	nanites.safety_threshold = 0

/datum/nanite_program/meltdown/disable_passive_effect()
	. = ..()
	to_chat(host_mob, "<span class='warning'>Your blood cools down, and the pain gradually fades.</span>")

/datum/nanite_program/explosive
	name = "Chain Detonation"
	desc = "Detonates all the nanites inside the host in a chain reaction when triggered."
	can_trigger = TRUE
	trigger_cost = 25 //plus every idle nanite left afterwards
	trigger_cooldown = 100 //Just to avoid double-triggering
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/explosive/on_trigger(comm_message)
	host_mob.visible_message("<span class='warning'>[host_mob] starts emitting a high-pitched buzzing, and skin begins to glow...</span>",\
							"<span class='userdanger'>You start emitting a high-pitched buzzing, and your skin begins to glow...</span>")
	addtimer(CALLBACK(src, .proc/boom), clamp((nanites.nanite_volume * 0.35), 25, 150))

/datum/nanite_program/explosive/proc/boom()
	var/nanite_amount = nanites.nanite_volume
	var/dev_range = FLOOR(nanite_amount/200, 1) - 1
	var/heavy_range = FLOOR(nanite_amount/100, 1) - 1
	var/light_range = FLOOR(nanite_amount/50, 1) - 1
	explosion(get_turf(host_mob), dev_range, heavy_range, light_range)
	qdel(nanites)

//TG comment - TODO make it defuse if triggered again

/datum/nanite_program/heart_stop
	name = "Heart-Stopper"
	desc = "Stops the host's heart when triggered; restarts it if triggered again."
	can_trigger = TRUE
	trigger_cost = 12
	trigger_cooldown = 10
	rogue_types = list(/datum/nanite_program/nerve_decay)

/datum/nanite_program/heart_stop/on_trigger(comm_message)
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		var/obj/item/organ/internal/heart/heart = H.organs_by_name[O_HEART]
		if(heart)
			if(heart.heart_status == HEART_NORMAL)
				heart.heart_stop()
			else
				heart.heart_normalize()

/datum/nanite_program/emp
	name = "Electromagnetic Resonance"
	desc = "The nanites cause an elctromagnetic pulse around the host when triggered. Will corrupt other nanite programs!"
	trigger_cost = 10
	program_flags = NANITE_EMP_IMMUNE
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/emp/on_trigger(comm_message)
	empulse(get_turf(host_mob), 1, 2)

/datum/nanite_program/pyro
	name = "Sub-Dermal Combustion"
	desc = "The nanites cause buildup of flammable fluids under the host's skin, then ignites them."
	use_rate = 4
	rogue_types = list(/datum/nanite_program/skin_decay, /datum/nanite_program/cryo)

/datum/nanite_program/pyro/check_conditions()
	if(host_mob.fire_stacks >= 10 && host_mob.on_fire)
		return FALSE
	return ..()

/datum/nanite_program/pyro/active_effect()
	host_mob.fire_stacks += 1
	host_mob.IgniteMob()

/datum/nanite_program/cryo
	name = "Cryogenic Treatment"
	desc = "The nanites rapidly skin heat through the host's skin, lowering their temperature."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/skin_decay, /datum/nanite_program/pyro)

/datum/nanite_program/cryo/check_conditions()
	if(host_mob.bodytemperature <= 70)
		return FALSE
	return ..()

/datum/nanite_program/cryo/active_effect()
	host_mob.adjust_bodytemperature(-rand(15,25), 50)
