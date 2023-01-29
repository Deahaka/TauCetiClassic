//Programs that heal the host in some way.

/datum/nanite_program/regenerative
	name = "Accelerated Regeneration"
	desc = "The nanites boost the host's natural regeneration, increasing their healing speed. Does not consume nanites if the host is unharmed."
	use_rate = 2.5
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/regenerative/check_conditions()
	if(!host_mob.getBruteLoss() && !host_mob.getFireLoss())
		return FALSE
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		var/list/parts = H.bad_bodyparts
		if(!parts.len)
			return FALSE
	return ..()

/datum/nanite_program/regenerative/active_effect()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		var/list/parts = list()
		for(var/obj/item/organ/external/BP in H.bodyparts)
			if(BP.get_damage())
				parts += BP
		if(!parts.len)
			return
		for(var/obj/item/organ/external/BP in parts)
			BP.heal_damage(1/parts.len, 1/parts.len)
	else
		host_mob.adjustBruteLoss(-1)
		host_mob.adjustFireLoss(-1)

/datum/nanite_program/temperature
	name = "Temperature Adjustment"
	desc = "The nanites adjust the host's internal temperature to an ideal level."
	use_rate = 3.5
	rogue_types = list(/datum/nanite_program/skin_decay)

//TODO: rework in RESIST_HEAT trait with visuals ?
/datum/nanite_program/temperature/check_conditions()
	var/normal_temperature = BODYTEMP_NORMAL
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		if(H.species)
			normal_temperature = H.species.body_temperature
			if(H.bodytemperature < H.species.heat_level_1 && H.bodytemperature > H.species.cold_level_1)
				return FALSE
	else
		if(host_mob.bodytemperature > (normal_temperature - 30) && host_mob.bodytemperature < (normal_temperature + 30))
			return FALSE
	return ..()

/datum/nanite_program/temperature/active_effect()
	var/normal_temperature = BODYTEMP_NORMAL
	var/upper_limit_temp = normal_temperature - 10
	var/lower_limit_temp = normal_temperature + 10
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		if(H.species)
			normal_temperature = H.species.body_temperature
			lower_limit_temp = H.species.cold_level_1 + 10
			upper_limit_temp = H.species.heat_level_1 - 10
	if(host_mob.bodytemperature > upper_limit_temp)
		host_mob.adjust_bodytemperature(-15 * TEMPERATURE_DAMAGE_COEFFICIENT, upper_limit_temp)
		host_mob.adjust_fire_stacks(-0.5)
	else if(host_mob.bodytemperature < lower_limit_temp)
		host_mob.adjust_bodytemperature(15 * TEMPERATURE_DAMAGE_COEFFICIENT, 0, lower_limit_temp)

/datum/nanite_program/purging
	name = "Blood Purification"
	desc = "The nanites purge toxins and chemicals from the host's bloodstream."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/suffocating, /datum/nanite_program/necrotic)

/datum/nanite_program/purging/check_conditions()
	var/foreign_reagent = host_mob.reagents.reagent_list.len
	if(!host_mob.getToxLoss() && !foreign_reagent)
		return FALSE
	return ..()

/datum/nanite_program/purging/active_effect()
	host_mob.adjustToxLoss(-1)
	for(var/datum/reagent/R in host_mob.reagents.reagent_list)
		host_mob.reagents.remove_reagent(R.id,1)

/datum/nanite_program/brain_heal
	name = "Neural Regeneration"
	desc = "The nanites fix neural connections in the host's brain, reversing brain damage and minor traumas."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/brain_decay)

/datum/nanite_program/brain_heal/check_conditions()
	if(!host_mob.getBrainLoss())
		return FALSE
	return ..()

/datum/nanite_program/brain_heal/active_effect()
	host_mob.adjustBrainLoss(-1)

/datum/nanite_program/repairing
	name = "Mechanical Repair"
	desc = "The nanites fix damage in the host's mechanical limbs."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/repairing/check_conditions()
	var/count_of_damaged_parts = 0
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		for(var/obj/item/organ/external/BP in H.bodyparts)
			if(BP.is_robotic())
				if(BP.get_damage())
					count_of_damaged_parts++
	if(count_of_damaged_parts < 1)
		return FALSE
	return ..()

/datum/nanite_program/repairing/active_effect(mob/living/M)
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		var/list/parts = list()
		for(var/obj/item/organ/external/BP in H.bodyparts)
			if(BP.is_robotic())
				if(BP.get_damage())
					parts += BP
		if(!parts.len)
			return
		for(var/obj/item/organ/external/BP in parts)
			BP.heal_damage(1/parts.len, 1/parts.len, robo_repair = TRUE)
	else
		host_mob.adjustBruteLoss(-1)
		host_mob.adjustFireLoss(-1)

/datum/nanite_program/purging_advanced
	name = "Selective Blood Purification"
	desc = "The nanites purge toxins and dangerous chemicals from the host's bloodstream, while ignoring beneficial chemicals. \
			The added processing power required to analyze the chemicals severely increases the nanite consumption rate."
	use_rate = 2
	rogue_types = list(/datum/nanite_program/suffocating, /datum/nanite_program/necrotic)

/datum/nanite_program/purging_advanced/check_conditions()
	var/foreign_reagent = FALSE
	for(var/datum/reagent/toxin/R in host_mob.reagents.reagent_list)
		foreign_reagent = TRUE
		break
	if(!host_mob.getToxLoss() && !foreign_reagent)
		return FALSE
	return ..()

/datum/nanite_program/purging_advanced/active_effect()
	host_mob.adjustToxLoss(-1)
	for(var/datum/reagent/toxin/R in host_mob.reagents.reagent_list)
		host_mob.reagents.remove_reagent(R.id,1)

/datum/nanite_program/regenerative_advanced
	name = "Bio-Reconstruction"
	desc = "The nanites manually repair and replace organic cells, acting much faster than normal regeneration. \
			However, this program cannot detect the difference between harmed and unharmed, causing it to consume nanites even if it has no effect."
	use_rate = 5.5
	rogue_types = list(/datum/nanite_program/suffocating, /datum/nanite_program/necrotic)

/datum/nanite_program/regenerative_advanced/active_effect()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		var/list/parts = list()
		for(var/obj/item/organ/external/BP in H.bodyparts)
			if(BP.get_damage())
				parts += BP
		if(!parts.len)
			return
		for(var/obj/item/organ/external/BP in parts)
			BP.heal_damage(3/parts.len, 3/parts.len)
	else
		host_mob.adjustBruteLoss(-3)
		host_mob.adjustFireLoss(-3)

/datum/nanite_program/brain_heal_advanced
	name = "Neural Reimaging"
	desc = "The nanites are able to backup and restore the host's neural connections, potentially replacing entire chunks of missing or damaged brain matter."
	use_rate = 3
	rogue_types = list(/datum/nanite_program/brain_decay, /datum/nanite_program/brain_misfire)

/datum/nanite_program/brain_heal_advanced/check_conditions()
	if(!host_mob.getBrainLoss())
		return FALSE
	return ..()

/datum/nanite_program/brain_heal_advanced/active_effect()
	host_mob.adjustBrainLoss(-3)

/datum/nanite_program/defib
	name = "Defibrillation"
	desc = "The nanites shock the host's heart when triggered, bringing them back to life if the body can sustain it."
	trigger_cost = 25
	trigger_cooldown = 120
	rogue_types = list(/datum/nanite_program/shocking)

/datum/nanite_program/defib/on_trigger(comm_message)
	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		if(check_revivable())
			H.return_to_body_dialog()
	playsound(host_mob, 'sound/machines/defib_zap.ogg', 75, 1, -1)
	addtimer(CALLBACK(src, .proc/zap), 30)

/datum/nanite_program/defib/proc/check_revivable()
	if(!iscarbon(host_mob)) //nonstandard biology
		return FALSE
	var/mob/living/carbon/human/H = host_mob
	if(H.suiciding) //can't revive
		return FALSE
	if((world.time - H.timeofdeath) >= DEFIB_TIME_LIMIT) //too late
		return FALSE
	if((H.getBruteLoss() > 180) || (H.getFireLoss() > 180)) //too damaged
		return FALSE
	//what are we even shocking
	if(!istype(H.organs_by_name[O_HEART], /obj/item/organ/internal/heart))
		return FALSE
	if(!(H.has_brain() && H.should_have_organ(O_BRAIN)))
		return FALSE
	if(!H.get_ghost())
		return FALSE
	return TRUE

/datum/nanite_program/defib/proc/zap()
	if(check_revivable())
		var/mob/living/carbon/human/H = host_mob
		//playsound(C, 'sound/machines/defib_success.ogg', 50, 0)
		var/obj/item/organ/internal/heart/IO = H.organs_by_name[O_HEART]
		if(!IO)
			return
		if(IO.heart_status == HEART_NORMAL)
			IO.heart_stop()
		if(IO.heart_status == HEART_FIBR)
			if(H.stat == DEAD)
				IO.heart_normalize()
				H.reanimate_body(H)
				H.stat = UNCONSCIOUS
				H.beauty.AddModifier("stat", additive=H.beauty_living)
			else
				IO.heart_normalize()
		H.emote("gasp")
		H.make_jittery(150)
		SEND_SIGNAL(H, COMSIG_LIVING_MINOR_SHOCK)
		var/tplus = world.time - H.timeofdeath
		if(tplus > 600)
			H.adjustBrainLoss( max(0, ((1800 - tplus) / 1800 * 150)), 150)
		log_game("[H] has been successfully defibrillated by nanites.")
	//else
		//playsound(src, 'sound/machines/defib_failed.ogg', 50, 0)
