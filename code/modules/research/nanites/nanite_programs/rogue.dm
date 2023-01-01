//Programs generated through degradation of other complex programs.
//They generally cause minor damage or annoyance.

//Last stop of the error train
/datum/nanite_program/glitch
	name = "Glitch"
	desc = "A heavy software corruption that causes nanites to gradually break down."
	use_rate = 1.5
	unique = FALSE
	rogue_types = list()

//Generic body-affecting programs will decay into this
/datum/nanite_program/necrotic
	name = "Necrosis"
	desc = "The nanites attack internal tissues indiscriminately, causing widespread damage."
	use_rate = 0.75
	unique = FALSE
	rogue_types = list(/datum/nanite_program/glitch)

/datum/nanite_program/necrotic/active_effect()
	host_mob.adjustBruteLoss(0.75, TRUE)
	if(prob(1))
		to_chat(host_mob, "<span class='warning'>You feel a mild ache from somewhere inside you.</span>")

//Programs that don't directly interact with the body will decay into this
/datum/nanite_program/toxic
	name = "Toxin Buildup"
	desc = "The nanites cause a slow but constant toxin buildup inside the host."
	use_rate = 0.25
	unique = FALSE
	rogue_types = list(/datum/nanite_program/glitch)

/datum/nanite_program/toxic/active_effect()
	host_mob.adjustToxLoss(0.5)
	if(prob(1))
		to_chat(host_mob, "<span class='warning'>You feel a bit sick.</span>")

//Generic blood-affecting programs will decay into this
/datum/nanite_program/suffocating
	name = "Hypoxemia"
	desc = "The nanites prevent the host's blood from absorbing oxygen efficiently."
	use_rate = 0.75
	unique = FALSE
	rogue_types = list(/datum/nanite_program/glitch)

/datum/nanite_program/suffocating/active_effect()
	host_mob.adjustOxyLoss(3, 0)
	if(prob(1))
		to_chat(host_mob, "<span class='warning'>You feel short of breath.</span>")

//Generic brain-affecting programs will decay into this
/datum/nanite_program/brain_decay
	name = "Neuro-Necrosis"
	desc = "The nanites seek and attack brain cells, causing extensive neural damage to the host."
	use_rate = 0.75
	unique = FALSE
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/brain_decay/active_effect()
	if(prob(4))
		host_mob.hallucination = min(15, host_mob.hallucination)
	host_mob.adjustBrainLoss(1)

//Generic brain-affecting programs can also decay into this
/datum/nanite_program/brain_misfire
	name = "Brain Misfire"
	desc = "The nanites interfere with neural pathways, causing minor psychological disturbances."
	use_rate = 0.50
	unique = FALSE
	rogue_types = list(/datum/nanite_program/brain_decay)

/datum/nanite_program/brain_misfire/active_effect()
	if(prob(10))
		switch(rand(1,4))
			if(1)
				host_mob.hallucination += 15
			if(2)
				host_mob.confused  += 10
			if(3)
				host_mob.drowsyness += 10
			if(4)
				host_mob.slurring += 10

//Generic skin-affecting programs will decay into this
/datum/nanite_program/skin_decay
	name = "Dermalysis"
	desc = "The nanites attack skin cells, causing irritation, rashes, and minor damage."
	use_rate = 0.25
	unique = FALSE
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/skin_decay/active_effect()
	host_mob.adjustBruteLoss(0.25)
	if(prob(5)) //itching
		var/mob/living/carbon/human/H = host_mob
		var/picked_bodypart = pick(BP_HEAD, BP_CHEST, BP_R_ARM, BP_L_ARM, BP_R_LEG, BP_L_LEG)
		var/obj/item/organ/external/bodypart = H.get_bodypart(picked_bodypart)
		var/can_scratch = !H.incapacitated()

		H.visible_message("[can_scratch ? "<span class='warning'>[H] scratches [bodypart.name].</span>" : ""]",\
								"<span class='warning'>Your [bodypart.name] itches. [can_scratch ? " You scratch it." : ""]</span>")

//Generic nerve-affecting programs will decay into this
/datum/nanite_program/nerve_decay
	name = "Nerve Decay"
	desc = "The nanites attack the host's nerves, causing lack of coordination and short bursts of paralysis."
	use_rate = 1
	unique = FALSE
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/nerve_decay/active_effect()
	if(prob(5))
		to_chat(host_mob, "<span class='warning'>You feel unbalanced!</span>")
		host_mob.AdjustConfused(10)
	else if(prob(4))
		to_chat(host_mob, "<span class='warning'>You can't feel your hands!</span>")
		host_mob.drop_item()
	else if(prob(4))
		to_chat(host_mob, "<span class='warning'>You can't feel your legs!</span>")
		host_mob.AdjustWeakened(15)
